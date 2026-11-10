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
    this.participantIds = const [],
    this.lastMessage,
    this.lastMessageType,
    this.lastMessageAt,
    this.liveUnreadCount,
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

  /// Son nom, fourni par `assignedAgent`, avec repli sur le participant
  /// actif dont l'identifiant correspond exactement à `assignedTo`.
  final String? assigneeName;

  /// Tous les comptes présents dans la conversation, agents compris.
  ///
  /// Sert à savoir quels fils écouter en temps réel : on ne reçoit d'événements
  /// que sur les conversations dont on est participant, et c'est aussi la seule
  /// façon de faire vivre les compteurs de non-lus sans ouvrir chaque fil.
  final List<String> participantIds;

  /// Dernier message échangé, quand la conversation est accessible.
  ///
  /// Fourni par la conversation embarquée dans le ticket, même sans accès au
  /// fil complet. L'aperçu retombe sur la demande si aucun message n'existe.
  final String? lastMessage;

  /// Nature du dernier message, pour l'annoncer quand il n'a pas de texte.
  final String? lastMessageType;

  final DateTime? lastMessageAt;

  /// Compteur de non-lus tenu par la conversation, plus juste que celui du
  /// ticket, qui ne bouge pas au fil des échanges.
  final int? liveUnreadCount;

  /// Ce que la liste doit montrer : le dernier échange, ou à défaut la demande.
  String get preview {
    final last = lastMessage?.trim();
    if (last != null && last.isNotEmpty) return last;

    // Une photo ou une note vocale n'a pas de texte. Sans ce libellé, l'aperçu
    // retombait sur la description d'ouverture du dossier : la ligne remontait
    // bien en tête, mais annonçait un message vieux de plusieurs jours.
    switch (lastMessageType) {
      case 'image':
        return '📷 Photo';
      case 'audio':
        return '🎤 Note vocale';
      case 'file':
        return '📎 Fichier';
    }

    final desc = description.trim();
    return desc.isEmpty ? subject : desc;
  }

  /// Date de tri et d'affichage : celle du dernier message si on le connaît.
  DateTime get displayDate => lastMessageAt ?? updatedAt;

  int get displayUnreadCount => liveUnreadCount ?? unreadCount;

  /// Copie enrichie des informations de la conversation.
  SupportTicketEntity withConversation({
    String? lastMessage,
    String? lastMessageType,
    DateTime? lastMessageAt,
    int? unreadCount,
  }) => SupportTicketEntity(
    id: id,
    conversationId: conversationId,
    subject: subject,
    description: description,
    status: status,
    priority: priority,
    category: category,
    updatedAt: updatedAt,
    author: author,
    unreadCount: this.unreadCount,
    assigneeId: assigneeId,
    assigneeName: assigneeName,
    participantIds: participantIds,
    lastMessage: lastMessage ?? this.lastMessage,
    lastMessageType: lastMessageType ?? this.lastMessageType,
    lastMessageAt: lastMessageAt ?? this.lastMessageAt,
    liveUnreadCount: unreadCount ?? liveUnreadCount,
  );

  /// Suis-je dans cette conversation ?
  bool includes(String? userId) =>
      userId != null && participantIds.contains(userId);

  /// Personne ne s'en occupe encore : le ticket attend dans la file commune.
  bool get isUnclaimed => assigneeId == null || assigneeId!.isEmpty;

  /// Ce dossier appartient déjà à quelqu'un d'autre.
  bool isTakenBySomeoneElse(String? currentUserId) =>
      !isUnclaimed && assigneeId != currentUserId;

  String get authorName => author?.displayName ?? 'Client';
}
