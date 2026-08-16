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
  });

  final String conversationId;

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
    extends ConsumerState<ConversationDetailScreen> {
  late List<ChatMessageData> _messages;

  /// Message auquel la saisie en cours répond, le cas échéant.
  ChatReplyPreview? _replyTo;

  /// Bascule le composer vers la barre d'enregistrement.
  bool _recording = false;

  /// Une clé par message, pour pouvoir défiler jusqu'à lui.
  ///
  /// `Scrollable.ensureVisible` a besoin du `BuildContext` de la cible : il faut
  /// donc une clé montée sur la bulle elle-même, qu'aucun index de liste ne peut
  /// remplacer.
  final Map<String, GlobalKey> _messageKeys = {};

  /// Message mis en évidence après un retour depuis une citation.
  String? _highlighted;

  @override
  void initState() {
    super.initState();
    _messages = List.of(ConversationFixtures.datedThread);
  }

  ConversationListItemData get _conversation {
    return ConversationFixtures.conversations.firstWhere(
      (c) => c.id == widget.conversationId,
      orElse: () => ConversationFixtures.conversations.first,
    );
  }

  /// Les messages reçus portent le nom de l'interlocuteur.
  ///
  /// Les fixtures sont génériques ; en production, cette information viendra de
  /// l'entité message.
  ChatMessageData _withSender(ChatMessageData message) {
    if (message.isMine || message.senderName != null) return message;
    return _copy(message, senderName: _conversation.name);
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
      status: status ?? m.status,
      isTyping: m.isTyping,
    );
  }

  /// Fait progresser l'état d'un message fraîchement émis.
  ///
  /// Le socle n'a pas de transport : cette progression est **simulée**, pour que
  /// l'état affiché sous la dernière bulle soit autre chose qu'une constante. Le
  /// jour où le socket arrive, ce sont ses accusés qui appelleront `_setStatus`.
  Future<void> _simulateDelivery(String id) async {
    for (final step in const [
      (Duration(milliseconds: 700), MessageStatus.sent),
      (Duration(milliseconds: 900), MessageStatus.delivered),
      (Duration(seconds: 3), MessageStatus.read),
    ]) {
      await Future<void>.delayed(step.$1);
      if (!mounted) return;
      setState(() {
        _messages = [
          for (final m in _messages)
            if (m.id == id) _copy(m, status: step.$2) else m,
        ];
      });
    }
  }

  /// Repose la réaction d'un message, ou la retire quand [emoji] est nul.
  void _react(ChatMessageData message, String? emoji) {
    setState(() {
      _messages = [
        for (final m in _messages)
          if (m.id == message.id) _copy(m, reaction: emoji) else m,
      ];
    });
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

  void _sendVoice(VoiceNoteData voice) {
    final now = DateTime.now();
    final id = _messages.length;
    setState(() {
      _recording = false;
      _messages = [
        ..._messages,
        ChatMessageData(
          id: 'local-$id',
          text: 'Note vocale',
          timeLabel: ChatDateFormatter.timeLabel(now),
          isMine: true,
          sentAt: now,
          voice: voice,
          replyTo: _replyTo,
          status: MessageStatus.sending,
        ),
      ];
      _replyTo = null;
    });
    _simulateDelivery('local-$id');
  }

  void _send(String text) {
    final now = DateTime.now();
    // Les fixtures n'ont pas de séquence : l'identifiant dérive de la longueur
    // de la liste, suffisant pour une maquette.
    final id = _messages.length;
    setState(() {
      _messages = [
        ..._messages,
        ChatMessageData(
          id: 'local-$id',
          text: text,
          timeLabel: ChatDateFormatter.timeLabel(now),
          isMine: true,
          sentAt: now,
          replyTo: _replyTo,
          status: MessageStatus.sending,
        ),
      ];
      _replyTo = null;
    });
    _simulateDelivery('local-$id');
  }

  /// Choix du type d'appel.
  ///
  /// Les deux appels partagent le même écran : c'est la présence de la vidéo qui
  /// change, pas la conversation. Demander avant d'ouvrir évite d'allumer une
  /// caméra que personne n'attendait.
  Future<void> _openCallOptions(BuildContext context, String name) async {
    final choice = await ref
        .read(platformUiProvider)
        .overlays
        .pickOption(
          context: context,
          title: name,
          labels: const ['Appel vocal', 'Appel vidéo'],
        );
    if (choice == null || !context.mounted) return;
    context.push(AppUiRoute.call, extra: name);
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
        onPressed: () {},
      ),
      PlatformMenuAction(
        label: 'Copier',
        icon: Iconsax.copy,
        sfSymbol: 'doc.on.doc',
        onPressed: () {
          Clipboard.setData(ClipboardData(text: message.text));
        },
      ),
      PlatformMenuAction(
        label: 'Transférer',
        icon: Iconsax.send_2,
        sfSymbol: 'arrowshape.turn.up.right',
        onPressed: () {},
      ),
      if (message.isMine)
        PlatformMenuAction(
          label: 'Modifier',
          icon: Iconsax.edit_2,
          sfSymbol: 'pencil',
          onPressed: () {},
        ),
      if (message.isMine)
        PlatformMenuAction(
          label: 'Supprimer',
          icon: Iconsax.trash,
          sfSymbol: 'trash',
          isDestructive: true,
          onPressed: () {},
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final platformUi = ref.watch(platformUiProvider);
    final isApple = platformUi.platform.isApple;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final conversation = _conversation;

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
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Motif de fond, comme dans WhatsApp. Répété plutôt qu'étiré : une
          // image unique déformée sur un iPad n'aurait plus rien du dessin
          // d'origine.
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                // Discret : le motif doit se deviner derrière les bulles, pas
                // concurrencer le texte qu'elles portent.
                opacity: isDark ? 0.5 : 0.7,
                child: Image.asset(
                  isDark
                      ? AppImages.chatPatternDark
                      : AppImages.chatPatternLight,
                  repeat: ImageRepeat.repeat,
                  alignment: Alignment.topLeft,
                ),
              ),
            ),
          ),
          Column(
            children: [
              _ConversationHeader(
                conversation: conversation,
                onBack: () => context.pop(),
                onMore: () => _openCallOptions(context, conversation.name),
                isApple: isApple,
              ),
              Expanded(
                child: StickyDateList(
                  now: DateTime.now(),
                  padding: const EdgeInsets.symmetric(
                    vertical: DesignTokens.spaceM,
                  ),
                  messages: [
                    for (var i = 0; i < _messages.length; i++)
                      DatedMessage(
                        sentAt: _messages[i].sentAt ?? DateTime.now(),
                        child: _buildBubble(context, platformUi, i),
                      ),
                  ],
                ),
              ),
              if (_recording)
                VoiceRecorderBar(
                  onSend: _sendVoice,
                  onCancel: () => setState(() => _recording = false),
                )
              else
                MessageComposer(
                  onSend: _send,
                  placeholder: 'Écrire un message…',
                  replyTo: _replyTo,
                  onCancelReply: () => setState(() => _replyTo = null),
                  onRecordVoice: () => setState(() => _recording = true),
                ),
            ],
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
  Widget _buildBubble(BuildContext context, PlatformUi platformUi, int index) {
    final message = _withSender(_messages[index]);

    final position = _groupPosition(index);
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
      showStatus: index == _lastSentIndex,
      onTapQuote: _scrollToMessage,
    );

    final keyed = KeyedSubtree(
      key: key,
      child: _Highlightable(active: _highlighted == message.id, child: bubble),
    );

    // L'indicateur de saisie n'est pas un message : rien à citer, à copier ni
    // sur quoi réagir.
    if (message.isTyping) return keyed;

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

  /// Index du dernier message émis, seul à porter son état d'acheminement.
  ///
  /// Recalculé à chaque construction plutôt que mémorisé : l'envoi d'un message
  /// le déplace, et un index gardé en champ finirait par désigner une bulle
  /// reçue.
  int get _lastSentIndex =>
      _messages.lastIndexWhere((m) => m.isMine && !m.isTyping);

  /// Détermine si l'entrée [index] ouvre ou ferme une série du même auteur.
  ///
  /// Une série est rompue par un changement d'auteur **ou** par un changement de
  /// jour : deux messages du même auteur séparés par une nuit ne forment pas un
  /// bloc.
  ({bool isFirst, bool isLast}) _groupPosition(int index) {
    final current = _messages[index];

    bool sameGroup(int other) {
      if (other < 0 || other >= _messages.length) return false;
      final m = _messages[other];
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
  final VoidCallback onBack;
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
            size: 30,
          ),
          const SizedBox(width: DesignTokens.spaceS),
          Flexible(
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
