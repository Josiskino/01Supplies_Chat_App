import '../../../domain/entity/messaging/message_entity.dart';
import '../auth/user_model.dart';

/// Représentation JSON d'un message.
class MessageModel {
  const MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.type,
    required this.status,
    required this.createdAt,
    this.sender,
    this.replyTo,
    this.replyToMessage,
    this.attachments = const [],
    this.attachmentMediaIds = const [],
    this.reactions = const [],
  });

  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final String type;
  final String status;
  final String createdAt;
  final UserModel? sender;
  final String? replyTo;
  final Map<String, dynamic>? replyToMessage;
  final List<String> attachments;
  final List<String> attachmentMediaIds;
  final List<Map<String, dynamic>> reactions;

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    final rawSender = (json['sender'] as Map?)?.cast<String, dynamic>();
    return MessageModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      conversationId: (json['conversationId'] ?? '').toString(),
      // `senderId` peut arriver à plat ou n'exister que dans l'objet `sender`.
      senderId: (json['senderId'] ?? rawSender?['id'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      type: (json['type'] ?? 'text').toString(),
      status: (json['status'] ?? 'sent').toString(),
      createdAt: (json['createdAt'] ?? '').toString(),
      sender: rawSender == null ? null : UserModel.fromJson(rawSender),
      replyTo: json['replyTo']?.toString(),
      replyToMessage: (json['replyToMessage'] as Map?)?.cast<String, dynamic>(),
      attachments: _parseAttachments(json),
      attachmentMediaIds: _parseAttachmentMediaIds(json),
      reactions:
          (json['reactions'] as List?)
              ?.whereType<Map>()
              .map((e) => e.cast<String, dynamic>())
              .toList() ??
          const [],
    );
  }

  /// Les pièces jointes arrivent soit en URL brutes, soit en objets média.
  ///
  /// Le serveur renseigne **les deux** champs avec les mêmes fichiers :
  /// `attachments` et `attachmentMedia` portent des URL identiques. Sans
  /// déduplication, une photo envoyée seule s'affichait en pile de deux, avec
  /// un compteur annonçant « 2 photos » pour une seule image.
  static List<String> _parseAttachments(Map<String, dynamic> json) {
    final urls = <String>{};
    for (final key in ['attachments', 'attachmentMedia']) {
      final raw = json[key];
      if (raw is! List) continue;
      for (final e in raw) {
        if (e is String && e.isNotEmpty) {
          urls.add(e);
        } else if (e is Map) {
          final u = e['url'] ?? e['secureUrl'] ?? e['path'];
          if (u is String && u.isNotEmpty) urls.add(u);
        }
      }
    }
    return urls.toList();
  }

  static List<String> _parseAttachmentMediaIds(Map<String, dynamic> json) {
    final ids = <String>{};
    final explicit = json['attachmentMediaIds'];
    if (explicit is List) {
      for (final value in explicit.whereType<String>()) {
        if (value.isNotEmpty) ids.add(value);
      }
    }
    for (final key in ['attachmentMedia', 'attachments']) {
      final media = json[key];
      if (media is! List) continue;
      for (final item in media.whereType<Map>()) {
        final value = item['id'] ?? item['_id'];
        if (value is String && value.isNotEmpty) ids.add(value);
      }
    }
    return ids.toList();
  }

  MessageEntity toEntity() {
    final reply = replyToMessage;
    final replyAuthor = (reply?['sender'] as Map?)?.cast<String, dynamic>();

    return MessageEntity(
      id: id,
      conversationId: conversationId,
      senderId: senderId,
      content: content,
      type: MessageType.fromWire(type),
      delivery: MessageDelivery.fromWire(status),
      sentAt: DateTime.tryParse(createdAt)?.toLocal() ?? DateTime.now(),
      sender: sender?.toEntity(),
      replyToId: replyTo ?? reply?['id']?.toString(),
      replyToContent: reply?['content']?.toString(),
      replyToAuthor: replyAuthor == null
          ? null
          : UserModel.fromJson(replyAuthor).toEntity().displayName,
      attachments: attachments,
      attachmentMediaIds: attachmentMediaIds,
      // Une seule réaction est affichée par la bulle : la première posée.
      reaction: reactions.isEmpty ? null : reactions.first['emoji']?.toString(),
    );
  }
}
