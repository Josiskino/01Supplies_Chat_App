import '../../../domain/entity/messaging/message_attachment_entity.dart';
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
    this.attachmentDetails = const [],
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
  final List<MessageAttachmentEntity> attachmentDetails;
  final List<Map<String, dynamic>> reactions;

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    final rawSender = (json['sender'] as Map?)?.cast<String, dynamic>();
    return MessageModel(
      id: (json['id'] ?? json['_id'] ?? json['messageId'] ?? '').toString(),
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
      attachmentDetails: parseAttachmentDetails(json),
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

  /// Merges `attachmentMedia` (resolved media assets) and the legacy
  /// `attachments` objects into one description per file.
  ///
  /// Without this metadata every attachment was treated as a photo: a PDF was
  /// handed to the image decoder, rendered as a broken thumbnail, and its tap
  /// opened the photo viewer instead of the document.
  static List<MessageAttachmentEntity> parseAttachmentDetails(
    Map<String, dynamic> json,
  ) {
    final byUrl = <String, MessageAttachmentEntity>{};
    final unavailable = <MessageAttachmentEntity>[];

    int? asInt(Object? value) => switch (value) {
      num() => value.toInt(),
      String() => int.tryParse(value),
      _ => null,
    };
    String? asText(Object? value) {
      final text = value?.toString().trim() ?? '';
      return text.isEmpty ? null : text;
    }

    // The server fills a missing legacy `name` with the media id: an id is
    // not a file name, the URL file name reads better.
    String? legacyName(Map item, String? mediaId) {
      final name = asText(item['name'] ?? item['originalName']);
      final id = mediaId ?? asText(item['id'] ?? item['_id']);
      return name != null && name == id ? null : name;
    }

    final media = json['attachmentMedia'];
    if (media is List) {
      for (final item in media.whereType<Map>()) {
        final id = asText(item['id'] ?? item['_id'] ?? item['mediaId']);
        if (item['unavailable'] == true) {
          unavailable.add(
            MessageAttachmentEntity(
              url: '',
              mediaId: id,
              mimeType: asText(item['mimeType']),
              fileType: asText(item['fileType']),
              unavailable: true,
            ),
          );
          continue;
        }
        final url = asText(item['url'] ?? item['secureUrl'] ?? item['path']);
        if (url == null) continue;
        byUrl[url] = MessageAttachmentEntity(
          url: url,
          mediaId: id,
          name: asText(item['originalName'] ?? item['name']),
          size: asInt(item['size']),
          mimeType: asText(item['mimeType']),
          fileType: asText(item['fileType']),
        );
      }
    }

    final legacy = json['attachments'];
    if (legacy is List) {
      for (final item in legacy) {
        if (item is String && item.isNotEmpty) {
          byUrl.putIfAbsent(item, () => MessageAttachmentEntity(url: item));
        } else if (item is Map) {
          final url = asText(item['url'] ?? item['secureUrl'] ?? item['path']);
          if (url == null) continue;
          final known = byUrl[url];
          // Legacy `type` holds a MIME type (`application/pdf`).
          final legacyType = asText(item['type'] ?? item['mimeType']);
          byUrl[url] = MessageAttachmentEntity(
            url: url,
            mediaId: known?.mediaId ?? asText(item['id'] ?? item['_id']),
            name: known?.name ?? legacyName(item, known?.mediaId),
            size: known?.size ?? asInt(item['size']),
            mimeType:
                known?.mimeType ??
                (legacyType != null && legacyType.contains('/')
                    ? legacyType
                    : null),
            fileType: known?.fileType,
          );
        }
      }
    }
    return [...byUrl.values, ...unavailable];
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
      attachmentDetails: attachmentDetails,
      // Une seule réaction est affichée par la bulle : la première posée.
      reaction: reactions.isEmpty ? null : reactions.first['emoji']?.toString(),
    );
  }
}
