import '../../../domain/entity/messaging/support_ticket_entity.dart';
import '../auth/user_model.dart';

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
    this.assigneeIds = const [],
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
  final List<String> assigneeIds;

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
      assigneeIds: _parseAssignees(json),
    );
  }

  /// Les prises en charge vivent dans `metadata.assignmentHistory`, dont seule
  /// la dernière entrée compte.
  static List<String> _parseAssignees(Map<String, dynamic> json) {
    final meta = (json['metadata'] as Map?)?.cast<String, dynamic>();
    final history = meta?['assignmentHistory'];
    if (history is! List || history.isEmpty) return const [];
    final ids = <String>[];
    for (final e in history) {
      if (e is Map) {
        final id = e['assignedTo'] ?? e['userId'] ?? e['adminId'];
        if (id != null && id.toString().isNotEmpty) ids.add(id.toString());
      }
    }
    return ids;
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
    assigneeIds: assigneeIds,
  );
}
