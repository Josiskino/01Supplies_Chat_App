import '../../../domain/entity/messaging/support_ticket_entity.dart';
import '../auth/user_model.dart';
import 'conversation_model.dart';

/// Représentation JSON d'un ticket de support.
class SupportTicketModel {
  const SupportTicketModel({
    required this.id,
    required this.conversationId,
    required this.subject,
    required this.description,
    required this.status,
    required this.priority,
    required this.category,
    required this.updatedAt,
    this.user,
    this.unreadCount = 0,
    this.assignedTo,
    this.assigneeName,
    this.participantIds = const [],
    this.conversation,
  });

  final String id;
  final String conversationId;
  final String subject;
  final String description;
  final String status;
  final String priority;
  final String category;
  final String updatedAt;
  final UserModel? user;
  final int unreadCount;
  final String? assignedTo;
  final String? assigneeName;
  final List<String> participantIds;
  final ConversationModel? conversation;

  factory SupportTicketModel.fromJson(Map<String, dynamic> json) {
    final conv = (json['conversation'] as Map?)?.cast<String, dynamic>();
    final rawUser = (json['user'] as Map?)?.cast<String, dynamic>();

    return SupportTicketModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      // L'identifiant de conversation est le pivot : c'est lui qui ouvre le fil
      // et sert de canal temps réel. Il peut arriver à plat ou dans l'objet
      // `conversation` selon l'endpoint.
      conversationId: (json['conversationId'] ?? conv?['id'] ?? '').toString(),
      subject: (json['subject'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      status: (json['status'] ?? 'open').toString(),
      priority: (json['priority'] ?? 'medium').toString(),
      category: (json['category'] ?? 'general').toString(),
      updatedAt: (json['updatedAt'] ?? json['createdAt'] ?? '').toString(),
      user: rawUser == null ? null : UserModel.fromJson(rawUser),
      unreadCount: (conv?['unreadCount'] as num?)?.toInt() ?? 0,
      // Le champ direct plutôt que l'historique : `assignmentHistory` retrace
      // les prises successives, mais c'est `assignedTo` qui dit qui détient le
      // dossier maintenant.
      assignedTo: json['assignedTo']?.toString(),
      assigneeName: _parseAssigneeName(json, conv),
      conversation: conv == null ? null : ConversationModel.fromJson(conv),
      participantIds: _parseParticipantIds(conv),
    );
  }

  static List<String> _parseParticipantIds(Map<String, dynamic>? conversation) {
    final parts = conversation?['participants'];
    if (parts is! List) return const [];
    return parts
        .whereType<Map>()
        .where((p) => p['isActive'] != false)
        .map((p) {
          final u = p['user'];
          return (p['userId'] ?? (u is Map ? u['id'] : null) ?? '').toString();
        })
        .where((id) => id.isNotEmpty)
        .toList();
  }

  /// Nom de l'agent en charge, lu sur les participants de la conversation.
  static String? _parseAssigneeName(
    Map<String, dynamic> ticket,
    Map<String, dynamic>? conversation,
  ) {
    final assigned = ticket['assignedAgent'];
    if (assigned is Map) {
      return UserModel.fromJson(
        assigned.cast<String, dynamic>(),
      ).toEntity().displayName;
    }
    final parts = conversation?['participants'];
    if (parts is! List) return null;
    for (final p in parts) {
      if (p is! Map) continue;
      if (p['role'] != 'support_agent' || p['isActive'] == false) continue;
      if (p['userId']?.toString() != ticket['assignedTo']?.toString()) continue;
      final u = p['user'];
      if (u is Map) {
        final name = UserModel.fromJson(
          u.cast<String, dynamic>(),
        ).toEntity().displayName;
        if (name.isNotEmpty) return name;
      }
    }
    return null;
  }

  SupportTicketEntity toEntity() => SupportTicketEntity(
    id: id,
    conversationId: conversationId,
    subject: subject,
    description: description,
    status: TicketStatus.fromWire(status),
    priority: TicketPriority.fromWire(priority),
    category: category,
    updatedAt: DateTime.tryParse(updatedAt) ?? DateTime.now(),
    author: user?.toEntity(),
    unreadCount: unreadCount,
    assigneeId: assignedTo,
    assigneeName: assigneeName,
    participantIds: participantIds,
    lastMessage: conversation?.lastMessage,
    lastMessageType: conversation?.lastMessageType,
    lastMessageAt: DateTime.tryParse(
      conversation?.lastMessageAt ?? conversation?.updatedAt ?? '',
    )?.toLocal(),
    liveUnreadCount: conversation?.unreadCount,
  );
}
