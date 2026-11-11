import '../auth/user_role.dart';
import '../auth/user_entity.dart';
import 'conversation_entity.dart';
import 'support_ticket_entity.dart';

/// Une ligne de l'onglet Conversations.
///
/// ## Pourquoi un type à part
///
/// La liste réunit deux choses de nature différente : les **demandes de
/// support**, qui existent avant tout échange et que l'équipe se répartit, et
/// les **conversations directes**, ouvertes depuis le répertoire et qui n'ont
/// pas de dossier derrière elles. Partir du ticket, comme on le faisait,
/// laissait les secondes entièrement hors de la liste.
class ConversationListEntry {
  const ConversationListEntry({
    required this.conversationId,
    required this.title,
    required this.preview,
    required this.date,
    this.avatarUrl,
    this.peerRole,
    this.peerId,
    this.unreadCount = 0,
    this.ticketId,
    this.assigneeId,
    this.assigneeName,
    this.isUnclaimed = false,
    this.isSupport = false,
  });

  final String conversationId;
  final String title;
  final String preview;
  final DateTime date;
  final String? avatarUrl;
  final UserRole? peerRole;
  final String? peerId;

  String? get peerRoleLabel => switch (peerRole) {
    UserRole.client => 'Client',
    UserRole.delivery => 'Livreur',
    UserRole.vendor => 'Vendeur',
    _ => null,
  };
  final int unreadCount;

  /// Dossier de support correspondant. Nul pour une conversation directe.
  final String? ticketId;

  /// Conversation kind is independent of whether ticket linkage is available.
  /// Missing linkage must never turn a support conversation into a direct one.
  final bool isSupport;

  final String? assigneeId;
  final String? assigneeName;

  /// Demande que personne n'a encore prise. Toujours faux pour une directe :
  /// on est déjà participant d'une conversation qu'on a soi-même ouverte.
  final bool isUnclaimed;

  /// Construit une ligne à partir d'une demande de support.
  factory ConversationListEntry.fromTicket(
    SupportTicketEntity ticket, {
    String? me,
    UserEntity? lastSender,
  }) => ConversationListEntry(
    conversationId: ticket.conversationId,
    title: ticket.authorName,
    preview: formatPreview(ticket.preview, me: me, sender: lastSender),
    date: ticket.displayDate,
    avatarUrl: ticket.author?.avatarUrl,
    peerRole: ticket.author?.role,
    peerId: ticket.author?.id,
    unreadCount: ticket.displayUnreadCount,
    ticketId: ticket.id,
    isSupport: true,
    assigneeId: ticket.assigneeId,
    assigneeName: ticket.assigneeName,
    isUnclaimed: ticket.isUnclaimed && ticket.status.isActive,
  );

  /// Construit une ligne à partir d'une conversation sans dossier.
  ///
  /// [me] sert à nommer la ligne d'après **l'autre** participant : une
  /// conversation directe n'a pas de titre, seulement deux personnes.
  factory ConversationListEntry.fromConversation(
    ConversationEntity conversation, {
    required String? me,
  }) {
    final other = conversation.participants
        .where((p) => p.id != me)
        .firstOrNull;

    return ConversationListEntry(
      conversationId: conversation.id,
      title: other?.displayName.isNotEmpty == true
          ? other!.displayName
          : (conversation.isSupport ? 'Demande de support' : 'Conversation'),
      ticketId: conversation.supportTicketId,
      isSupport: conversation.isSupport,
      preview: formatPreview(
        _previewOf(conversation),
        me: me,
        sender: conversation.lastSender,
      ),
      date: conversation.sortDate,
      avatarUrl: other?.avatarUrl,
      peerRole: other?.role,
      peerId: other?.id,
      unreadCount: conversation.unreadCount,
    );
  }

  /// Collapse message paragraphs before the row truncates its single line.
  static String formatPreview(
    String content, {
    String? me,
    UserEntity? sender,
    String? senderId,
  }) {
    final text = content.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (me != null && (senderId ?? sender?.id) == me) return 'Vous : $text';
    if (sender != null &&
        const {
          UserRole.admin,
          UserRole.support,
          UserRole.superAdmin,
        }.contains(sender.role)) {
      final name = sender.displayName.trim();
      if (name.isNotEmpty) return '$name : $text';
    }
    return text;
  }

  static String _previewOf(ConversationEntity conversation) {
    final text = conversation.lastMessage?.trim();
    if (text != null && text.isNotEmpty) return text;
    return switch (conversation.lastMessageType) {
      'image' => '📷 Photo',
      'audio' => '🎤 Note vocale',
      'file' => '📎 Fichier',
      // Une conversation ouverte sans qu'un mot ait été échangé.
      _ => 'Aucun message',
    };
  }
}
