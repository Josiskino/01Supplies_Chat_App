import '../../../domain/entity/messaging/conversation_entity.dart';
import '../auth/user_model.dart';

/// Représentation JSON d'une conversation.
class ConversationModel {
  const ConversationModel({
    required this.id,
    required this.updatedAt,
    this.supportTicketId,
    this.lastMessage,
    this.lastMessageType,
    this.lastSender,
    this.lastMessageAt,
    this.unreadCount = 0,
    this.participants = const [],
  });

  final String id;
  final String updatedAt;
  final String? supportTicketId;
  final String? lastMessage;
  final String? lastMessageType;
  final UserModel? lastSender;
  final String? lastMessageAt;
  final int unreadCount;
  final List<UserModel> participants;

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    final last = (json['lastMessage'] as Map?)?.cast<String, dynamic>();
    final lastSender = (last?['sender'] as Map?)?.cast<String, dynamic>();
    final meta = (json['metadata'] as Map?)?.cast<String, dynamic>();

    return ConversationModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      updatedAt: (json['updatedAt'] ?? '').toString(),
      // Le lien vers le ticket : c'est lui qui permet de rapprocher cette
      // conversation de la demande correspondante dans la file.
      supportTicketId: meta?['supportTicketId']?.toString(),
      lastMessage: last?['content']?.toString(),
      lastMessageType: last?['type']?.toString(),
      lastSender: lastSender == null ? null : UserModel.fromJson(lastSender),
      lastMessageAt: last?['createdAt']?.toString(),
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
      participants: _parseParticipants(json['participants']),
    );
  }

  static List<UserModel> _parseParticipants(Object? raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((p) => p['user'])
        .whereType<Map>()
        .map((u) => UserModel.fromJson(u.cast<String, dynamic>()))
        .toList();
  }

  ConversationEntity toEntity() => ConversationEntity(
    id: id,
    updatedAt: DateTime.tryParse(updatedAt)?.toLocal() ?? DateTime.now(),
    supportTicketId: supportTicketId,
    lastMessage: lastMessage,
    lastMessageType: lastMessageType,
    lastSender: lastSender?.toEntity(),
    lastMessageAt: lastMessageAt == null
        ? null
        : DateTime.tryParse(lastMessageAt!)?.toLocal(),
    unreadCount: unreadCount,
    participants: participants.map((p) => p.toEntity()).toList(),
  );
}
