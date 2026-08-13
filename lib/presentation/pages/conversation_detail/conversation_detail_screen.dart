import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

import '../../../config/theme/design_tokens.dart';
import '../../../core/platform/platform_ui.dart';
import '../../../core/platform/platform_ui_provider.dart';
import '../../desktop/widgets/presence_avatar.dart';
import '../../shared/fixtures/conversation_fixtures.dart';
import '../../shared/models/conversation_view_data.dart';
import 'widgets/chat_bubble.dart';
import 'widgets/message_composer.dart';

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

class _ConversationDetailScreenState
    extends ConsumerState<ConversationDetailScreen> {
  late List<ChatThreadEntry> _entries;

  @override
  void initState() {
    super.initState();
    _entries = List.of(ConversationFixtures.thread);
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
    return ChatMessageData(
      id: message.id,
      text: message.text,
      timeLabel: message.timeLabel,
      isMine: message.isMine,
      senderName: _conversation.name,
      avatarUrl: message.avatarUrl,
      reaction: message.reaction,
      isDelivered: message.isDelivered,
      isTyping: message.isTyping,
    );
  }

  void _send(String text) {
    setState(() {
      _entries = [
        ..._entries,
        ChatMessageEntry(
          ChatMessageData(
            // Les fixtures n'ont pas d'horloge : l'identifiant dérive de la
            // longueur de la liste, suffisant pour une maquette.
            id: 'local-${_entries.length}',
            text: text,
            timeLabel: '',
            isMine: true,
          ),
        ),
      ];
    });
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
    final conversation = _conversation;

    return platformUi.shell.buildPage(
      title: conversation.name,
      titleWidget: _ConversationHeaderTitle(conversation: conversation),
      actions: [
        PlatformAction(
          icon: isApple ? CupertinoIcons.video_camera : Iconsax.video,
          sfSymbol: 'video',
          label: 'Appel vidéo',
          onPressed: () {},
        ),
      ],
      body: Column(
        children: [
          Expanded(
            child: _ThreadList(
              entries: _entries,
              decorate: _withSender,
              buildMenu: (context, message, child) =>
                  platformUi.overlays.contextMenu(
                    actions: _messageActions(context, message),
                    child: child,
                  ),
            ),
          ),
          MessageComposer(
            onSend: _send,
            placeholder: isApple ? 'iMessage' : 'Message',
          ),
        ],
      ),
    );
  }
}

/// Titre d'en-tête : avatar au-dessus du nom, comme dans Messages.
class _ConversationHeaderTitle extends StatelessWidget {
  const _ConversationHeaderTitle({required this.conversation});

  final ConversationListItemData conversation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      // Toute la zone est cliquable : sur iOS, toucher le nom ouvre la fiche du
      // contact.
      onTap: () {},
      behavior: HitTestBehavior.opaque,
      // Hauteur maîtrisée : une barre de navigation iOS fait 44 pt, et un avatar
      // de 30 px surmonté d'une ligne de texte la débordait de quelques pixels.
      // L'avatar est réduit et l'interligne resserré pour tenir dans le gabarit.
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PresenceAvatar(
            name: conversation.name,
            avatarUrl: conversation.avatarUrl,
            presence: conversation.presence,
            size: 24,
          ),
          const SizedBox(height: 1),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  conversation.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 11,
                    height: 1.1,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                CupertinoIcons.chevron_right,
                size: 10,
                color: DesignTokens.getTextColorWithOpacity(context, 0.4),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Liste des messages, avec groupement des séries consécutives.
class _ThreadList extends StatelessWidget {
  const _ThreadList({
    required this.entries,
    required this.decorate,
    required this.buildMenu,
  });

  final List<ChatThreadEntry> entries;
  final ChatMessageData Function(ChatMessageData) decorate;

  /// Enveloppe une bulle de son menu contextuel.
  ///
  /// Injecté plutôt que construit ici : la liste n'a pas à connaître le contrat
  /// de plateforme, et la construction reste testable en isolation.
  final Widget Function(BuildContext, ChatMessageData, Widget) buildMenu;

  /// Détermine si l'entrée [index] ouvre ou ferme une série du même auteur.
  ///
  /// Une série est rompue par un changement d'auteur **ou** par un séparateur de
  /// date : deux messages du même auteur séparés par une nuit ne forment pas un
  /// bloc.
  ({bool isFirst, bool isLast}) _groupPosition(int index) {
    final entry = entries[index];
    if (entry is! ChatMessageEntry) {
      return (isFirst: true, isLast: true);
    }

    bool sameAuthorAt(int i) {
      if (i < 0 || i >= entries.length) return false;
      final other = entries[i];
      if (other is! ChatMessageEntry) return false;
      return other.message.isMine == entry.message.isMine;
    }

    return (
      isFirst: !sameAuthorAt(index - 1),
      isLast: !sameAuthorAt(index + 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      // Le fil se lit du bas : `reverse` ancre le défilement sur le dernier
      // message sans piloter de ScrollController.
      reverse: true,
      padding: const EdgeInsets.only(bottom: DesignTokens.spaceM),
      itemCount: entries.length,
      itemBuilder: (context, reversedIndex) {
        final index = entries.length - 1 - reversedIndex;
        final entry = entries[index];

        return switch (entry) {
          ChatSeparatorEntry(separator: final separator) => ChatDayDivider(
            label: separator.label,
          ),
          ChatMessageEntry(message: final message) => Builder(
            builder: (context) {
              final position = _groupPosition(index);
              final decorated = decorate(message);
              final bubble = ChatBubble(
                message: decorated,
                isFirstOfGroup: position.isFirst,
                isLastOfGroup: position.isLast,
              );
              // L'indicateur de saisie n'est pas un message : rien à copier ni à
              // supprimer dessus.
              if (decorated.isTyping) return bubble;
              return buildMenu(context, decorated, bubble);
            },
          ),
        };
      },
    );
  }
}
