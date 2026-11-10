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
  factory ConversationListEntry.fromTicket(SupportTicketEntity ticket) =>
      ConversationListEntry(
        conversationId: ticket.conversationId,
        title: ticket.authorName,
        preview: ticket.preview,
        date: ticket.displayDate,
        avatarUrl: ticket.author?.avatarUrl,
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
      preview: _previewOf(conversation),
      date: conversation.sortDate,
      avatarUrl: other?.avatarUrl,
      unreadCount: conversation.unreadCount,
    );
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
