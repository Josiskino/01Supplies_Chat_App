import '../auth/user_entity.dart';

/// Nature du contenu d'un message.
enum MessageType {
  text('text'),
  image('image'),
  file('file'),
  audio('audio'),
  system('system');

  const MessageType(this.wireName);
  final String wireName;

  static MessageType fromWire(String? v) =>
      values.firstWhere((t) => t.wireName == v, orElse: () => MessageType.text);
}

/// Avancement d'un message vers son destinataire.
enum MessageDelivery {
  sent('sent'),
  delivered('delivered'),
  read('read');

  const MessageDelivery(this.wireName);
  final String wireName;

  static MessageDelivery fromWire(String? v) => values.firstWhere(
    (s) => s.wireName == v,
    // Un état inconnu est traité comme « envoyé » : c'est le plus prudent, il
    // ne promet ni distribution ni lecture.
    orElse: () => MessageDelivery.sent,
  );
}

/// Un message du fil.
class MessageEntity {
  const MessageEntity({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.type,
    required this.delivery,
    required this.sentAt,
    this.sender,
    this.replyToId,
    this.replyToContent,
    this.replyToAuthor,
    this.attachments = const [],
    this.reaction,
    this.isPending = false,
  });

  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final MessageType type;
  final MessageDelivery delivery;
  final DateTime sentAt;

  /// L'auteur, quand l'API le peuple.
  final UserEntity? sender;

  final String? replyToId;
  final String? replyToContent;
  final String? replyToAuthor;

  /// URL des pièces jointes, dans l'ordre d'envoi.
  final List<String> attachments;

  /// Première réaction posée, celle que la bulle affiche.
  final String? reaction;

  /// Message affiché avant d'exister côté serveur, le temps du téléversement.
  ///
  /// Un booléen plutôt qu'un identifiant à préfixe : reconnaître un état à la
  /// forme d'une chaîne casse dès que le serveur change ses identifiants.
  final bool isPending;

  bool get hasAttachments => attachments.isNotEmpty;

  /// Un message émis par le compte connecté.
  ///
  /// Comparé à l'identifiant plutôt qu'au nom : plusieurs admins peuvent
  /// répondre dans le même fil, et deux homonymes ne sont pas impossibles.
  bool isMine(String? currentUserId) =>
      currentUserId != null && senderId == currentUserId;

  String get authorName => sender?.displayName ?? '';
}
