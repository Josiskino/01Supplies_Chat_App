import '../auth/user_entity.dart';

/// Avancement d'un ticket dans la file.
enum TicketStatus {
  open('open'),
  inProgress('in_progress'),
  resolved('resolved'),
  closed('closed');

  const TicketStatus(this.wireName);
  final String wireName;

  static TicketStatus fromWire(String? v) => values.firstWhere(
    (s) => s.wireName == v,
    // Un statut inconnu est traité comme ouvert : mieux vaut un ticket de trop
    // dans la file qu'une demande client qui disparaît sans que personne ne la
    // voie.
    orElse: () => TicketStatus.open,
  );

  String get label => switch (this) {
    TicketStatus.open => 'Ouvert',
    TicketStatus.inProgress => 'En cours',
    TicketStatus.resolved => 'Résolu',
    TicketStatus.closed => 'Clos',
  };

  /// Un ticket encore à traiter par l'équipe.
  bool get isActive =>
      this == TicketStatus.open || this == TicketStatus.inProgress;
}

/// Urgence déclarée d'un ticket.
enum TicketPriority {
  low('low'),
  medium('medium'),
  high('high'),
  urgent('urgent');

  const TicketPriority(this.wireName);
  final String wireName;

  static TicketPriority fromWire(String? v) => values.firstWhere(
    (p) => p.wireName == v,
    orElse: () => TicketPriority.medium,
  );

  String get label => switch (this) {
    TicketPriority.low => 'Faible',
    TicketPriority.medium => 'Normale',
    TicketPriority.high => 'Haute',
    TicketPriority.urgent => 'Urgente',
  };
}

/// Une demande client dans la file d'attente commune.
///
/// C'est l'unité de travail de la messagerie interne : un client écrit, un
/// ticket naît, et **tous** les admins le voient jusqu'à ce que l'un s'en
/// saisisse. Il porte sa propre conversation, où se déroulent les échanges.
class SupportTicketEntity {
  const SupportTicketEntity({
    required this.id,
    required this.conversationId,
    required this.subject,
    required this.description,
    required this.status,
    required this.priority,
    required this.category,
    required this.updatedAt,
    this.author,
    this.unreadCount = 0,
    this.assigneeId,
    this.assigneeName,
  });

  final String id;
  final String conversationId;
  final String subject;

  /// Premier message du client, servant d'aperçu dans la liste.
  final String description;

  final TicketStatus status;
  final TicketPriority priority;
  final String category;
  final DateTime updatedAt;

  /// Le client à l'origine du ticket. Nul si l'API ne l'a pas peuplé.
  final UserEntity? author;

  final int unreadCount;

  /// Membre de l'équipe qui s'est saisi du dossier. Nul s'il attend encore.
  final String? assigneeId;

  /// Son nom, tiré des participants de la conversation.
  ///
  /// L'API ne renvoie que l'identifiant de l'assigné, et le répertoire ne
  /// contient que les clients et partenaires : le nom d'un collègue ne s'y
  /// trouve pas. Il est donc lu sur la conversation, seul endroit qui le porte.
  final String? assigneeName;

  /// Personne ne s'en occupe encore : le ticket attend dans la file commune.
  bool get isUnclaimed => assigneeId == null || assigneeId!.isEmpty;

  /// Ce dossier appartient déjà à quelqu'un d'autre.
  bool isTakenBySomeoneElse(String? currentUserId) =>
      !isUnclaimed && assigneeId != currentUserId;

  String get authorName => author?.displayName ?? 'Client';
}
