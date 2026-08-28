import '../auth/user_entity.dart';

/// Une conversation dont l'utilisateur est participant.
///
/// Distincte du ticket : le ticket décrit une **demande** — sujet, catégorie,
/// priorité — tandis que la conversation porte l'échange, son dernier message
/// et son compteur de non-lus. C'est elle qui alimente la liste, le ticket ne
/// sachant rien de ce qui s'y est dit depuis son ouverture.
class ConversationEntity {
  const ConversationEntity({
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
  final DateTime updatedAt;

  /// Ticket dont cette conversation est le fil, s'il y en a un.
  final String? supportTicketId;

  /// Contenu du dernier message échangé.
  ///
  /// Vide pour une photo ou une note vocale : le contenu textuel n'existe pas.
  /// C'est [lastMessageType] qui permet alors d'annoncer « Photo » plutôt que
  /// de laisser l'aperçu retomber sur une description périmée.
  final String? lastMessage;

  /// Nature du dernier message : `text`, `image`, `audio`, `file`…
  final String? lastMessageType;

  final UserEntity? lastSender;
  final DateTime? lastMessageAt;

  final int unreadCount;
  final List<UserEntity> participants;

  /// Date à afficher dans la liste : celle du dernier message, à défaut la
  /// dernière activité connue.
  DateTime get sortDate => lastMessageAt ?? updatedAt;
}
