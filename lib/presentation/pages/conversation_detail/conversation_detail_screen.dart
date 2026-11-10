import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import '../../../config/theme/apple_type.dart';
import '../../../config/theme/design_tokens.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/constants/app_ui_route.dart';
import '../../../core/providers/messaging/message_provider.dart';
import '../../../core/providers/messaging/draft_provider.dart';
import '../../../core/providers/auth/auth_provider.dart';
import '../../../core/services/message_events_service.dart';
import '../../../core/providers/realtime/realtime_provider.dart';
import '../../../core/providers/messaging/support_provider.dart';
import '../../../domain/entity/messaging/message_entity.dart';
import '../../../core/platform/platform_ui.dart';
import '../../../core/platform/platform_ui_provider.dart';
import '../../../core/utils/chat_date_formatter.dart';
import '../../desktop/widgets/presence_avatar.dart';
import '../../shared/fixtures/conversation_fixtures.dart';
import '../../shared/models/conversation_view_data.dart';
import 'widgets/chat_bubble.dart';
import '../../widgets/common/context_actions_panel.dart';
import 'widgets/message_composer.dart';
import 'widgets/sticky_date_list.dart';
import 'widgets/swipe_to_reply.dart';
import 'widgets/voice_recorder_bar.dart';

/// Fil de discussion, présentation mobile.
///
/// ⚠️ Les messages viennent de [ConversationFixtures] : la présentation est
/// réelle, le contenu est une maquette. La feature messagerie remplacera la
/// source par un provider sans toucher aux widgets.
class ConversationDetailScreen extends ConsumerStatefulWidget {
  const ConversationDetailScreen({
    super.key,
    required this.conversationId,
    this.contactName,
    this.embedded = false,
    this.onBack,
  });

  final String conversationId;
  final bool embedded;
  final VoidCallback? onBack;

  /// Passé par la liste pour afficher le bon nom dès le premier frame, sans
  /// attendre une résolution asynchrone.
  final String? contactName;

  @override
  ConsumerState<ConversationDetailScreen> createState() =>
      _ConversationDetailScreenState();
}

/// Sentinelle de paramètre non fourni.
///
/// `null` est une valeur *légitime* pour une réaction — c'est même ainsi qu'on
/// la retire. Un défaut à `null` ne permettrait donc pas de distinguer « ne
/// change pas » de « efface ».
const Object _unset = Object();

class _ConversationDetailScreenState
    extends ConsumerState<ConversationDetailScreen>
    with WidgetsBindingObserver {
  late final MessageEventsService _events;
  late final VisibleConversation _visibleConversation;

  @override
  void initState() {
    super.initState();
    _events = ref.read(messageEventsProvider);
    _visibleConversation = ref.read(visibleConversationProvider.notifier);
    WidgetsBinding.instance.addObserver(this);
    // Déclare le fil affiché : un message arrivé sous les yeux de
    // l'utilisateur ne doit pas déclencher de notification.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(visibleConversationProvider.notifier).set(widget.conversationId);
    });
  }

  @override
  void dispose() {
    // `ref` reste lisible pendant `dispose` pour un ConsumerState, mais le
    // provider peut déjà être détruit à la fermeture de l'application.
    try {
      _visibleConversation.set(null);
    } catch (_) {}
    WidgetsBinding.instance.removeObserver(this);
    _scroll.dispose();
    _editController.dispose();
    super.dispose();
  }

  final ScrollController _scroll = ScrollController();
  bool _readScheduled = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _scheduleRead();
  }

  void _scheduleRead() {
    if (_readScheduled) return;
    _readScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _readScheduled = false;
      if (!mounted) return;
      if (WidgetsBinding.instance.lifecycleState != null &&
          WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
        return;
      }
      if (_scroll.hasClients &&
          _scroll.position.pixels - _scroll.position.minScrollExtent > 80) {
        return;
      }
      unawaited(
        ref.read(threadProvider(widget.conversationId).notifier).markRead(),
      );
    });
  }

  /// Message auquel la saisie en cours répond, le cas échéant.
  ChatReplyPreview? _replyTo;

  /// Bascule le composer vers la barre d'enregistrement.
  bool _recording = false;
  ChatMessageData? _editing;
  final TextEditingController _editController = TextEditingController();

  /// Une clé par message, pour pouvoir défiler jusqu'à lui.
  ///
  /// `Scrollable.ensureVisible` a besoin du `BuildContext` de la cible : il faut
  /// donc une clé montée sur la bulle elle-même, qu'aucun index de liste ne peut
  /// remplacer.
  final Map<String, GlobalKey> _messageKeys = {};

  /// Message mis en évidence après un retour depuis une citation.
  String? _highlighted;

  /// En-tête du fil.
  ///
  /// Le nom vient de la liste qui a poussé cet écran : le fil lui-même ne
  /// transporte pas l'identité de l'interlocuteur, et la retrouver demanderait
  /// un appel de plus pour une information déjà connue.
  ConversationListItemData get _conversation => ConversationListItemData(
    id: widget.conversationId,
    name: widget.contactName ?? 'Conversation',
    preview: '',
    timeLabel: '',
  );

  /// Les messages reçus portent le nom de l'interlocuteur.
  ///
  /// Les fixtures sont génériques ; en production, cette information viendra de
  /// l'entité message.
  ChatMessageData _withSender(ChatMessageData message) {
    if (message.senderName != null) return message;
    final me = ref.read(currentUserProvider);
    return _copy(
      message,
      senderName: message.isMine ? (me?.displayName ?? 'Vous') : 'Utilisateur',
    );
  }

  /// Copie d'un message, un champ à la fois.
  ///
  /// Le modèle est immuable et n'a pas de `copyWith` : l'écrire à la main ici
  /// évite d'ajouter du code généré au socle, mais tout nouveau champ devra y
  /// être reporté.
  ChatMessageData _copy(
    ChatMessageData m, {
    String? senderName,
    Object? reaction = _unset,
    MessageStatus? status,
  }) {
    return ChatMessageData(
      id: m.id,
      text: m.text,
      timeLabel: m.timeLabel,
      isMine: m.isMine,
      sentAt: m.sentAt,
      senderName: senderName ?? m.senderName,
      avatarUrl: m.avatarUrl,
      reaction: reaction == _unset ? m.reaction : reaction as String?,
      replyTo: m.replyTo,
      voice: m.voice,
      attachments: m.attachments,
      status: status ?? m.status,
      isTyping: m.isTyping,
    );
  }

  /// Repose la réaction d'un message, ou la retire quand [emoji] est nul.
  ///
  /// Purement locale pour l'instant : `POST /messages/{id}/reactions` existe
  /// mais n'est pas branché, et une réaction qui ne part pas doit au moins ne
  /// pas survivre au rechargement.
  Future<void> _react(ChatMessageData message, String? emoji) async {
    final value = emoji ?? message.reaction;
    if (value == null) return;
    final ok = await ref
        .read(threadProvider(widget.conversationId).notifier)
        .react(message.id, value);
    if (!mounted || ok) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Réaction non envoyée. Réessayez.')),
    );
  }

  /// Prépare une réponse au message glissé.
  void _startReply(ChatMessageData message) {
    setState(() {
      _replyTo = ChatReplyPreview(
        messageId: message.id,
        author: message.isMine
            ? 'Vous'
            : (message.senderName ?? _conversation.name),
        // Une note vocale n'a pas de texte à citer : on cite sa nature.
        text: message.isVoice ? 'Note vocale' : message.text,
        isVoice: message.isVoice,
      );
    });
  }

  /// Remonte au message cité et le signale brièvement.
  ///
  /// Le simple défilement ne suffit pas : arrivé en haut d'un fil dense, rien ne
  /// dit *lequel* des messages visibles était celui qu'on cherchait. Le
  /// surlignage répond à cette question, puis s'efface pour ne pas rester comme
  /// un état.
  Future<void> _scrollToMessage(String id) async {
    final key = _messageKeys[id];
    final context = key?.currentContext;
    if (context == null) return;

    await Scrollable.ensureVisible(
      context,
      duration: DesignTokens.durationSlow,
      curve: Curves.easeOutCubic,
      // Un peu au-dessus du bord : collé en haut, le message se retrouverait
      // sous la barre de navigation.
      alignment: 0.3,
    );
    if (!mounted) return;

    setState(() => _highlighted = id);
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() => _highlighted = null);
  }

  /// Envoie la note vocale capturée.
  Future<void> _sendVoice(VoiceNoteData voice, String filePath) async {
    setState(() => _recording = false);
    await _sendFiles([filePath], MessageType.audio);
  }

  /// Envoie des images choisies dans la photothèque ou prises à l'instant.
  Future<void> _sendImages(List<String> paths) =>
      _sendFiles(paths, MessageType.image);

  /// Dépose les fichiers puis les envoie en un seul message.
  ///
  /// L'attente est signalée : un envoi de photos passe par un téléversement,
  /// et sans repère l'utilisateur croit que rien ne part.
  Future<void> _sendFiles(List<String> paths, MessageType type) async {
    if (paths.isEmpty) return;
    final reply = _replyTo;
    setState(() => _replyTo = null);

    final ok = await ref
        .read(threadProvider(widget.conversationId).notifier)
        .sendAttachments(
          filePaths: paths,
          type: type,
          replyTo: reply?.messageId,
        );

    if (!mounted || ok) return;

    if (_replyTo == null) setState(() => _replyTo = reply);
    ref
        .read(platformUiProvider)
        .overlays
        .notify(
          context: context,
          message: type == MessageType.audio
              ? 'Note vocale non envoyée. Réessayez.'
              : 'Envoi des photos impossible. Réessayez.',
          isError: true,
        );
  }

  /// Nom de l'agent déjà sur le dossier, ou `null` si personne.
  ///
  /// Sert à informer, non à interdire : rejoindre reste possible à plusieurs.
  String? get _assigneeName {
    final queue = ref.read(supportQueueProvider).value ?? const [];
    final entry = queue
        .where((e) => e.conversationId == widget.conversationId)
        .firstOrNull;
    if (entry == null || entry.assigneeId == null) return null;
    if (entry.assigneeId == ref.read(currentUserIdProvider)) return null;
    return entry.assigneeName ?? 'un membre de l’équipe';
  }

  void _typingChanged(bool active) {
    if (!mounted) return;
    unawaited(_events.setTyping(widget.conversationId, isTyping: active));
  }

  Future<bool> _send(String text) async {
    final reply = _replyTo;
    setState(() => _replyTo = null);

    final sent = await ref
        .read(threadProvider(widget.conversationId).notifier)
        .send(text, replyTo: reply?.messageId);

    if (!mounted || sent) return sent;
    // L'envoi a échoué : la citation est rendue à l'utilisateur plutôt que
    // perdue, et le message reste dans le champ de saisie.
    if (_replyTo == null) setState(() => _replyTo = reply);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Message non envoyé. Réessayez.')),
    );
    return false;
  }

  /// Actions du menu d'en-tête.
  ///
  /// L'appel n'y figure plus : l'écran existe et son design est prêt, mais rien
  /// ne compose derrière — proposer « Appel vocal » ouvrirait une conversation
  /// simulée avec des participants inventés. Il reviendra avec le transport.
  Future<void> _openCallOptions(BuildContext context, String name) async {
    final choice = await ref
        .read(platformUiProvider)
        .overlays
        .pickOption(
          context: context,
          title: name,
          labels: const ['Actualiser la discussion'],
        );
    if (choice == null || !context.mounted) return;
    if (choice == 0) {
      await ref.read(threadProvider(widget.conversationId).notifier).refresh();
    }
  }

  /// Actions proposées à l'appui long sur un message.
  ///
  /// « Modifier » et « Supprimer » ne concernent que ses propres messages : les
  /// proposer sur ceux d'un interlocuteur donnerait une promesse que le backend
  /// refuserait.
  List<PlatformMenuAction> _messageActions(
    BuildContext context,
    ChatMessageData message,
  ) {
    return [
      PlatformMenuAction(
        label: 'Répondre',
        icon: Iconsax.undo,
        sfSymbol: 'arrowshape.turn.up.left',
        onPressed: () => _startReply(message),
      ),
      PlatformMenuAction(
        label: 'Copier',
        icon: Iconsax.copy,
        sfSymbol: 'doc.on.doc',
        onPressed: () {
          Clipboard.setData(ClipboardData(text: message.text));
        },
      ),
      if (message.isMine && !message.isVoice && !message.hasAttachments)
        PlatformMenuAction(
          label: 'Modifier',
          icon: Iconsax.edit_2,
          sfSymbol: 'pencil',
          onPressed: () {
            _editController.text = message.text;
            setState(() => _editing = message);
          },
        ),
      if (message.isMine)
        PlatformMenuAction(
          label: 'Supprimer',
          icon: Iconsax.trash,
          sfSymbol: 'trash',
          isDestructive: true,
          onPressed: () => _deleteMessage(message),
        ),
    ];
  }

  Future<void> _deleteMessage(ChatMessageData message) async {
    final accepted = await ref
        .read(platformUiProvider)
        .overlays
        .confirm(
          context: context,
          title: 'Supprimer le message ?',
          message: 'Cette action supprime le contenu du message.',
          confirmLabel: 'Supprimer',
          cancelLabel: 'Annuler',
          isDestructive: true,
        );
    if (accepted != true || !mounted) return;
    final ok = await ref
        .read(threadProvider(widget.conversationId).notifier)
        .delete(message.id);
    if (!mounted || ok) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Suppression impossible.')));
  }

  Future<void> _submitEdit() async {
    final editing = _editing;
    final text = _editController.text.trim();
    if (editing == null || text.isEmpty) return;
    final ok = await ref
        .read(threadProvider(widget.conversationId).notifier)
        .edit(editing.id, text);
    if (!mounted) return;
    if (ok) {
      setState(() => _editing = null);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Modification impossible. Le texte est conservé.'),
        ),
      );
    }
  }

  /// Le fil projeté pour l'affichage, réactions locales appliquées.
  List<ChatMessageData> _visibleMessages(List<MessageEntity> source) {
    final me = ref.read(currentUserIdProvider);
    return [
      for (final message in source)
        ChatMessageData.fromMessage(message, currentUserId: me),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(messageDraftProvider(widget.conversationId));
    final platformUi = ref.watch(platformUiProvider);
    final isApple = platformUi.platform.isApple;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final conversation = _conversation;
    final async = ref.watch(threadProvider(widget.conversationId));
    final thread = async.value;
    final locked = thread is ThreadLocked;
    final messages = _visibleMessages(
      thread is ThreadMessages ? thread.messages : const [],
    );

    if (thread is ThreadMessages) _scheduleRead();
    final typing =
        ref.watch(typingUsersProvider(widget.conversationId)).value ??
        const <String, String>{};
    final present =
        ref.watch(conversationPresenceProvider(widget.conversationId)).value ??
        const <String, Map<String, dynamic>>{};
    final me = ref.watch(currentUserIdProvider);
    final peerPresent = present.keys.any((id) => id != me);

    // En-tête construit dans le corps, sans barre de navigation.
    //
    // C'est la seule façon d'aligner avatar et nom juste après la flèche : les
    // deux plateformes bornent la zone de début de barre — 56 px pour Material,
    // la largeur d'un bouton retour pour iOS — et un en-tête plus large y
    // déborde. Passer par le titre l'aurait centré, iOS centrant sa zone du
    // milieu quelle que soit sa largeur.
    //
    // Le geste de retour par balayage reste assuré par la route, pas par la
    // barre : il n'est pas perdu.
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          _ConversationHeader(
            conversation: conversation,
            onBack: widget.embedded ? widget.onBack : () => context.pop(),
            onMore: () => _openCallOptions(context, conversation.name),
            isApple: isApple,
          ),
          // Le motif ne couvre que la zone des messages.
          //
          // Posé sur tout l'écran, il traversait le composer et le bandeau de
          // réponse : en thème clair, les traits du dessin passaient à travers
          // le champ de saisie, qui devenait à peine lisible. Le thème sombre le
          // masquait, ce qui rendait le défaut invisible d'un côté seulement.
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    child: Opacity(
                      // Discret : le motif doit se deviner derrière les bulles,
                      // pas concurrencer le texte qu'elles portent.
                      opacity: isDark ? 0.5 : 0.55,
                      child: Image.asset(
                        isDark
                            ? AppImages.chatPatternDark
                            : AppImages.chatPatternLight,
                        // Répété plutôt qu'étiré : une image unique déformée sur
                        // un iPad n'aurait plus rien du dessin d'origine.
                        repeat: ImageRepeat.repeat,
                        alignment: Alignment.topLeft,
                      ),
                    ),
                  ),
                ),
                if (async.isLoading && !async.hasValue)
                  const Center(child: CircularProgressIndicator())
                else if (locked || (async.hasError && !async.hasValue))
                  _ThreadError(
                    // Nul quand l'accès est simplement à prendre : ce n'est pas
                    // une erreur, et le widget doit le dire autrement.
                    error: locked ? null : async.error,
                    // Qui détient le dossier, s'il est déjà pris. C'est la
                    // différence entre « à prendre » et « pas pour vous ».
                    heldBy: locked ? _assigneeName : null,
                    onRetry: () => ref
                        .read(threadProvider(widget.conversationId).notifier)
                        .refresh(),
                  )
                else
                  NotificationListener<ScrollNotification>(
                    onNotification: (_) {
                      _scheduleRead();
                      return false;
                    },
                    child: StickyDateList(
                      controller: _scroll,
                      now: DateTime.now(),
                      padding: const EdgeInsets.symmetric(
                        vertical: DesignTokens.spaceM,
                      ),
                      messages: [
                        for (var i = 0; i < messages.length; i++)
                          DatedMessage(
                            sentAt: messages[i].sentAt ?? DateTime.now(),
                            child: _buildBubble(
                              context,
                              platformUi,
                              messages,
                              i,
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if ((thread is ThreadMessages && thread.syncError != null) ||
              (async.hasError && async.hasValue))
            const Text(
              'Actualisation impossible. Les messages affichés sont conservés.',
            ),
          if (peerPresent) const Text('Présent dans cette discussion'),
          if (typing.isNotEmpty) Text('${typing.values.join(', ')} écrit…'),
          if (ref.read(threadProvider(widget.conversationId).notifier).hasMore)
            TextButton(
              onPressed: () => ref
                  .read(threadProvider(widget.conversationId).notifier)
                  .loadOlder(),
              child: const Text('Charger les messages précédents'),
            ),
          if (_editing != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _editController,
                      maxLines: 3,
                      minLines: 1,
                      decoration: const InputDecoration(
                        labelText: 'Modifier le message',
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Annuler',
                    onPressed: () => setState(() => _editing = null),
                    icon: const Icon(Icons.close),
                  ),
                  IconButton(
                    tooltip: 'Enregistrer',
                    onPressed: _submitEdit,
                    icon: const Icon(Icons.check),
                  ),
                ],
              ),
            )
          else if (_recording)
            VoiceRecorderBar(
              onSend: _sendVoice,
              onCancel: () => setState(() => _recording = false),
            )
          else
            MessageComposer(
              onSend: _send,
              initialText: draft,
              onDraftChanged: (text) => ref
                  .read(messageDraftProvider(widget.conversationId).notifier)
                  .set(text),
              onTyping: _typingChanged,
              onPickImages: _sendImages,
              placeholder: 'Écrire un message…',
              replyTo: _replyTo,
              onCancelReply: () => setState(() => _replyTo = null),
              onRecordVoice: () => setState(() => _recording = true),
            ),
        ],
      ),
    );
  }

  /// Assemble une bulle et les trois gestes qui l'entourent.
  ///
  /// L'ordre d'emballage compte : le menu contextuel est **à l'intérieur** du
  /// glissement. L'inverse ferait porter le drag horizontal par le widget que
  /// `CupertinoContextMenu` extrait de l'arbre à l'ouverture, et le geste se
  /// retrouverait orphelin.
  Widget _buildBubble(
    BuildContext context,
    PlatformUi platformUi,
    List<ChatMessageData> messages,
    int index,
  ) {
    final message = _withSender(messages[index]);

    final entity = switch (ref
        .read(threadProvider(widget.conversationId))
        .value) {
      ThreadMessages(:final messages) =>
        messages.where((m) => m.id == message.id).firstOrNull,
      _ => null,
    };
    if (entity?.type == MessageType.system) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Center(
          child: Text(
            message.text,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ),
      );
    }

    final position = _groupPosition(messages, index);
    final key = _messageKeys.putIfAbsent(message.id, GlobalKey.new);

    // Deux exemplaires distincts, et c'est nécessaire : celui de la liste porte
    // une `GlobalKey` — indispensable pour `ensureVisible` — et une clé ne peut
    // être montée qu'à un seul endroit. Passer ce même widget au panneau
    // d'actions la dupliquait, et la mise en page partait en contraintes
    // infinies.
    final bubble = ChatBubble(
      message: message,
      isFirstOfGroup: position.isFirst,
      isLastOfGroup: position.isLast,
      showStatus: index == _lastSentOf(messages),
      showAuthorAlways: true,
      refreshVoiceSource: () => ref
          .read(threadProvider(widget.conversationId).notifier)
          .refreshVoiceSource(message.id),
      onTapQuote: _scrollToMessage,
      onOpenGallery: _openGallery,
    );

    final keyed = KeyedSubtree(
      key: key,
      child: _Highlightable(active: _highlighted == message.id, child: bubble),
    );

    // L'indicateur de saisie n'est pas un message : rien à citer, à copier ni
    // sur quoi réagir.
    if (message.isTyping || message.status == MessageStatus.sending) {
      return keyed;
    }
    if (message.status == MessageStatus.failed) {
      return Column(
        children: [
          keyed,
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => ref
                    .read(threadProvider(widget.conversationId).notifier)
                    .retryAttachment(message.id),
                child: const Text('Réessayer'),
              ),
              TextButton(
                onPressed: () => ref
                    .read(threadProvider(widget.conversationId).notifier)
                    .discardAttachment(message.id),
                child: const Text('Supprimer'),
              ),
            ],
          ),
        ],
      );
    }

    return SwipeToReply(
      onReply: () => _startReply(message),
      child: GestureDetector(
        onLongPress: () => showContextActions(
          context: context,
          // L'exemplaire sans clé : le panneau en affiche une copie.
          preview: ChatBubble(
            message: message,
            isFirstOfGroup: position.isFirst,
            isLastOfGroup: position.isLast,
            showAuthorAlways: true,
          ),
          alignEnd: message.isMine,
          selectedReaction: message.reaction,
          actions: _messageActions(context, message),
          onReact: (emoji) => _react(message, emoji),
        ),
        child: keyed,
      ),
    );
  }

  /// Ouvre le lot de photos en plein écran, sur la première image.
  ///
  /// Passe par la route déclarée plutôt que par un `Navigator.push` : la
  /// visionneuse est un overlay non opaque, et c'est `CustomTransitionPage` qui
  /// laisse voir le fil pendant le fondu.
  void _openGallery(List<String> images) {
    context.push(
      AppUiRoute.imageViewer,
      extra: {'images': images, 'initialIndex': 0},
    );
  }

  /// Index du dernier message émis, seul à porter son état d'acheminement.
  ///
  /// Recalculé à chaque construction plutôt que mémorisé : l'envoi d'un message
  /// le déplace, et un index gardé en champ finirait par désigner une bulle
  /// reçue.
  int _lastSentOf(List<ChatMessageData> messages) =>
      messages.lastIndexWhere((m) => m.isMine && !m.isTyping);

  /// Détermine si l'entrée [index] ouvre ou ferme une série du même auteur.
  ///
  /// Une série est rompue par un changement d'auteur **ou** par un changement de
  /// jour : deux messages du même auteur séparés par une nuit ne forment pas un
  /// bloc.
  ({bool isFirst, bool isLast}) _groupPosition(
    List<ChatMessageData> messages,
    int index,
  ) {
    final current = messages[index];

    bool sameGroup(int other) {
      if (other < 0 || other >= messages.length) return false;
      final m = messages[other];
      if (m.isMine != current.isMine) return false;
      if (m.sentAt == null || current.sentAt == null) return true;
      return ChatDateFormatter.dayKey(m.sentAt!) ==
          ChatDateFormatter.dayKey(current.sentAt!);
    }

    return (isFirst: !sameGroup(index - 1), isLast: !sameGroup(index + 1));
  }
}

/// En-tête du fil : retour, avatar, nom, puis les actions.
///
/// Remplace la barre de navigation, dont la zone de début est trop étroite pour
/// ce contenu sur les deux plateformes.
class _ConversationHeader extends StatelessWidget {
  const _ConversationHeader({
    required this.conversation,
    required this.onBack,
    required this.onMore,
    required this.isApple,
  });

  final ConversationListItemData conversation;
  final VoidCallback? onBack;
  final VoidCallback onMore;
  final bool isApple;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.paddingOf(context).top + DesignTokens.spaceS,
        bottom: DesignTokens.spaceS,
        left: DesignTokens.spaceS,
        right: DesignTokens.spaceS,
      ),
      decoration: BoxDecoration(
        // Aplat opaque : le fil défile juste en dessous, et un en-tête
        // translucide laisserait les bulles le traverser.
        color: theme.scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: DesignTokens.getBorderColor(isDark, opacity: 0.12),
            width: DesignTokens.borderWidthThin,
          ),
        ),
      ),
      // Pas de `mainAxisSize.min` : la rangée doit accepter la largeur qu'on lui
      // donne pour que le nom s'y ellipse.
      child: Row(
        children: [
          if (onBack != null)
            GestureDetector(
              onTap: onBack,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                // Marge à droite du chevron : seul, il fait 26 px, très en deçà de
                // la cible de 44 pt attendue sur iOS.
                padding: const EdgeInsets.only(right: DesignTokens.spaceXs),
                child: Icon(
                  CupertinoIcons.chevron_back,
                  size: 24,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          PresenceAvatar(
            name: conversation.name,
            avatarUrl: conversation.avatarUrl,
            presence: conversation.presence,
            // 38 et non 30 : en dessous, la pastille ne tient plus son rang face
            // au nom en `headline` (17 pt gras) et l'en-tête paraît déséquilibré.
            // C'est aussi l'ordre de grandeur retenu par Messages et WhatsApp.
            size: 38,
          ),
          const SizedBox(width: DesignTokens.spaceS),
          // `Expanded` et non `Flexible` : le second laisse le nom à sa largeur
          // naturelle, et l'action de droite venait alors se coller au texte au
          // lieu de rester au bord de l'en-tête.
          Expanded(
            child: GestureDetector(
              // Le nom mène à la fiche du contact, comme sur iOS.
              onTap: () {},
              behavior: HitTestBehavior.opaque,
              child: Text(
                conversation.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium
                    ?.merge(AppleType.headline)
                    .copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          // Les trois points ouvrent le choix du type d'appel.
          GestureDetector(
            onTap: onMore,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(DesignTokens.spaceS),
              child: Icon(
                isApple ? CupertinoIcons.ellipsis : Iconsax.more,
                size: DesignTokens.iconM,
                color: DesignTokens.getTextColorWithOpacity(context, 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Voile passager posé sur une bulle qu'on vient de rejoindre.
///
/// Un fond translucide plutôt qu'une bordure : la bulle a déjà la sienne, et
/// deux traits concurrents se lisent comme un défaut d'alignement.
class _Highlightable extends StatelessWidget {
  const _Highlightable({required this.child, required this.active});

  final Widget child;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: DesignTokens.durationSlow,
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: active
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.14)
            : Colors.transparent,
        borderRadius: DesignTokens.borderRadiusM,
      ),
      child: child,
    );
  }
}

/// Ce que le fil affiche quand il ne peut pas se charger.
///
/// Le cas courant n'est pas une panne : un admin qui n'a pas encore pris le
/// dossier n'est pas participant de la conversation, et l'API le lui refuse.
/// Lui montrer « erreur réseau » l'enverrait chercher un problème inexistant.
class _ThreadError extends StatelessWidget {
  const _ThreadError({required this.error, required this.onRetry, this.heldBy});

  /// Agent qui détient déjà le dossier. Nul s'il est libre.
  final String? heldBy;

  /// Nul lorsque le fil est seulement verrouillé, faute de prise en charge.
  final Object? error;
  final VoidCallback onRetry;

  /// Se saisir du dossier — la seule action qui débloque un fil inaccessible.

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isNotParticipant = error == null;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spaceXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isNotParticipant ? Iconsax.lock_1 : Iconsax.cloud_cross,
              size: 44,
              color: DesignTokens.getTextColorWithOpacity(context, 0.3),
            ),
            const SizedBox(height: DesignTokens.spaceM),
            Text(
              !isNotParticipant
                  ? 'Conversation indisponible'
                  : heldBy != null
                  ? 'Dossier suivi par $heldBy'
                  : 'Dossier non pris en charge',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.merge(AppleType.headline),
            ),
            const SizedBox(height: DesignTokens.spaceS),
            Text(
              !isNotParticipant
                  ? error.toString().replaceFirst('Exception: ', '')
                  : heldBy != null
                  ? 'Votre premier envoi reprendra cette discussion.'
                  : 'Votre premier envoi prendra en charge cette discussion.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.merge(AppleType.subheadline)
                  .copyWith(
                    color: DesignTokens.getTextColorWithOpacity(context, 0.55),
                  ),
            ),
            const SizedBox(height: DesignTokens.spaceL),
            FilledButton(onPressed: onRetry, child: const Text('Réessayer')),
          ],
        ),
      ),
    );
  }
}
