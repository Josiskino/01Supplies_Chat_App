import 'package:flutter/widgets.dart';

import '../../../domain/entity/auth/user_entity.dart';
import '../../../core/utils/chat_date_formatter.dart';
import '../../../domain/entity/messaging/message_entity.dart';
import '../../../domain/entity/messaging/support_ticket_entity.dart';

/// Modèles de **présentation** de l'espace de travail desktop.
///
/// Volontairement séparés des entités du domaine, qui n'existent pas encore : les
/// widgets desktop prennent ces types en paramètre, si bien que brancher la
/// feature messagerie consistera à mapper `ConversationEntity` vers
/// [ConversationListItemData] sans toucher à l'interface.
///
/// C'est aussi ce qui permet à la maquette statique de vivre dans un fichier de
/// fixtures au lieu d'être codée dans les widgets.

/// Statut de présence d'un interlocuteur.
enum PresenceStatus {
  online,
  away,
  offline;

  bool get isVisible => this != offline;
}

/// Une entrée de la liste des conversations (colonne 3).
class ConversationListItemData {
  const ConversationListItemData({
    required this.id,
    required this.name,
    required this.preview,
    required this.timeLabel,
    this.avatarUrl,
    this.presence = PresenceStatus.offline,
    this.hasUnread = false,
    this.unreadCount = 0,
    this.isStarred = false,
    this.isMissedCall = false,
  });

  final String id;
  final String name;

  /// Aperçu du dernier message, préfixé de son auteur (« Vous : … »).
  final String preview;

  /// Heure ou date déjà formatée. Le formatage relève de la couche appelante.
  final String timeLabel;

  final String? avatarUrl;
  final PresenceStatus presence;
  final bool hasUnread;
  final int unreadCount;
  final bool isStarred;

  /// Un appel manqué s'affiche avec une icône dédiée à la place de l'aperçu.
  final bool isMissedCall;

  /// Projette un ticket de la file dans une ligne de conversation.
  ///
  /// L'aperçu vient du **dernier message** dès que la conversation est
  /// accessible ; il retombe sur la description de la demande pour les dossiers
  /// qu'on n'a pas rejoints, dont l'API ne livre pas le fil.
  factory ConversationListItemData.fromTicket(
    SupportTicketEntity ticket, {
    required String timeLabel,
  }) {
    return ConversationListItemData(
      // L'identifiant de **conversation**, pas celui du ticket : c'est lui qui
      // ouvre le fil et sert de canal temps réel.
      id: ticket.conversationId,
      name: ticket.authorName,
      // Le dernier échange quand on y a accès, la demande d'origine sinon.
      preview: ticket.preview,
      timeLabel: timeLabel,
      avatarUrl: ticket.author?.avatarUrl,
      unreadCount: ticket.displayUnreadCount,
      hasUnread: ticket.displayUnreadCount > 0,
      // L'étoile marque les dossiers que personne n'a encore pris : c'est
      // l'information qui décide de l'action dans une file partagée.
      isStarred: ticket.isUnclaimed && ticket.status.isActive,
    );
  }
}

/// Tracé neutre d'une note vocale dont l'API ne donne pas la forme d'onde.
const List<double> _flatWave = [
  0.35,
  0.5,
  0.65,
  0.45,
  0.7,
  0.55,
  0.4,
  0.6,
  0.75,
  0.5,
  0.45,
  0.65,
  0.55,
  0.7,
  0.4,
  0.6,
  0.5,
  0.35,
  0.55,
  0.45,
];

/// Un message du fil de discussion (colonne 4).
class ChatMessageData {
  const ChatMessageData({
    required this.id,
    required this.text,
    required this.timeLabel,
    required this.isMine,
    this.sentAt,
    this.senderName,
    this.avatarUrl,
    this.reaction,
    this.replyTo,
    this.voice,
    this.attachments = const [],
    this.status = MessageStatus.read,
    this.isTyping = false,
  });

  final String id;
  final String text;
  final String timeLabel;

  /// `true` pour un message émis par l'utilisateur courant : la bulle passe à
  /// droite et prend la couleur d'accent.
  final bool isMine;

  /// Nom de l'auteur, affiché au-dessus de la première bulle d'une série.
  ///
  /// iOS l'affiche systématiquement en conversation de groupe et le masque sur les
  /// messages consécutifs du même auteur.
  final String? senderName;

  final String? avatarUrl;

  /// Emoji de réaction affiché sous la bulle.
  final String? reaction;

  /// Acheminement du message. N'a de sens que sur les messages émis.
  final MessageStatus status;

  /// Bulle d'indicateur de saisie, sans texte.
  final bool isTyping;

  /// Horodatage réel, qui sert au regroupement par jour.
  ///
  /// Distinct de [timeLabel], déjà formaté : un libellé ne permet ni de trier ni
  /// de décider où insérer un séparateur, et « Hier » cesse d'être vrai à
  /// minuit. Nullable le temps que les fixtures migrent.
  final DateTime? sentAt;

  /// Message cité, quand celui-ci est une réponse.
  final ChatReplyPreview? replyTo;

  /// Contenu audio, si le message est une note vocale.
  final VoiceNoteData? voice;

  /// Images joints au message — URL distantes ou chemins locaux.
  ///
  /// La liste porte **toutes** les images, même quand l'aperçu n'en montre que
  /// deux : c'est elle qui alimente la visionneuse plein écran, et le compteur
  /// affiché doit refléter ce qui sera réellement feuilletable.
  final List<String> attachments;

  bool get isVoice => voice != null;
  bool get hasAttachments => attachments.isNotEmpty;

  /// Projette un message de l'API dans le modèle de vue du fil.
  ///
  /// [currentUserId] décide du côté de la bulle. Comparé à l'identifiant et non
  /// au nom : plusieurs admins répondent dans le même fil, et deux homonymes
  /// enverraient leurs messages du mauvais côté.
  factory ChatMessageData.fromMessage(
    MessageEntity message, {
    required String? currentUserId,
  }) {
    // Les clients envoient leurs images avec le nom du fichier pour contenu :
    // l'afficher en légende donne « scaled_1002322126.jpg » sous la photo, ce
    // qui n'apprend rien et ressemble à un défaut.
    final looksLikeFileName =
        message.type != MessageType.text &&
        RegExp(
          r'\.(jpe?g|png|gif|webp|heic|mp4|mov|m4a|aac|wav|pdf)$',
          caseSensitive: false,
        ).hasMatch(message.content.trim());

    return ChatMessageData(
      id: message.id,
      text: looksLikeFileName ? '' : message.content,
      timeLabel: ChatDateFormatter.timeLabel(message.sentAt),
      isMine: message.isMine(currentUserId),
      sentAt: message.sentAt,
      senderName: message.authorName.isEmpty ? null : message.authorName,
      avatarUrl: message.sender?.avatarUrl,
      reaction: message.reaction,
      replyTo: message.replyToId == null
          ? null
          : ChatReplyPreview(
              messageId: message.replyToId!,
              author: message.replyToAuthor ?? '',
              text: message.replyToContent ?? '',
            ),
      attachments: message.type == MessageType.audio
          ? const []
          : message.attachments,
      // Une note vocale se reconnaît à son type, pas à sa pièce jointe : un
      // message audio rendu comme du texte n'afficherait qu'une bulle vide.
      //
      // ⚠️ Durée et forme d'onde ne sont pas transmises par l'API : la bulle
      // s'affiche avec un tracé neutre, et la durée réelle apparaîtra à la
      // lecture. Mieux vaut cela qu'un message invisible.
      voice: message.type == MessageType.audio
          ? const VoiceNoteData(duration: Duration.zero, waveform: _flatWave)
          : null,
      status: message.isPending
          ? MessageStatus.sending
          : switch (message.delivery) {
              MessageDelivery.sent => MessageStatus.sent,
              MessageDelivery.delivered => MessageStatus.delivered,
              MessageDelivery.read => MessageStatus.read,
            },
    );
  }
}

/// Étapes d'acheminement d'un message émis.
///
/// iOS n'affiche l'état que sous le **dernier** message envoyé, et sous forme de
/// libellé : « Distribué », « Lu », et rien du tout tant que c'est simplement
/// parti. Les coches de WhatsApp répondent à la même question, mais les répéter
/// sur chaque bulle encombre le fil sans rien apprendre — l'état d'un message
/// plus ancien se déduit de celui du dernier.
enum MessageStatus {
  /// Remis à la file d'envoi, pas encore acquitté par le serveur.
  sending,

  /// Accepté par le serveur.
  sent,

  /// Arrivé sur l'appareil du destinataire.
  delivered,

  /// Ouvert par le destinataire.
  read,

  /// L'envoi a échoué — le seul état qui mérite d'être signalé en rouge, et sur
  /// la bulle concernée plutôt que sur la dernière.
  failed,
}

/// Extrait du message auquel on répond, affiché en tête de bulle.
///
/// Une copie figée plutôt qu'une référence vers le message d'origine : celui-ci
/// peut être supprimé ou modifié, et la citation doit rester ce qu'elle était au
/// moment de la réponse — c'est aussi le comportement de WhatsApp.
class ChatReplyPreview {
  const ChatReplyPreview({
    required this.author,
    required this.text,
    this.messageId,
    this.isVoice = false,
  });

  /// Identifiant du message cité, pour pouvoir y remonter d'un tap.
  ///
  /// Nullable : le message d'origine peut avoir été supprimé, et la citation
  /// reste alors affichée mais devient inerte.
  final String? messageId;

  final String author;
  final String text;
  final bool isVoice;
}

/// Note vocale.
class VoiceNoteData {
  const VoiceNoteData({required this.duration, required this.waveform});

  final Duration duration;

  /// Amplitudes normalisées entre 0 et 1, une par barre de la forme d'onde.
  ///
  /// Pré-calculées côté données : les recalculer au rendu obligerait à décoder
  /// l'audio pour dessiner une liste, ce qui bloquerait le défilement.
  final List<double> waveform;

  String get durationLabel {
    final m = duration.inMinutes;
    final s = duration.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}

/// Séparateur de jour inséré dans le fil.
class ChatDaySeparator {
  const ChatDaySeparator(this.label);

  final String label;
}

/// Entrée du fil : soit un message, soit un séparateur de date.
///
/// Une liste hétérogène typée évite de recalculer les ruptures de jour à chaque
/// rendu, et laisse la couche de données décider où les insérer.
sealed class ChatThreadEntry {
  const ChatThreadEntry();
}

class ChatMessageEntry extends ChatThreadEntry {
  const ChatMessageEntry(this.message);
  final ChatMessageData message;
}

class ChatSeparatorEntry extends ChatThreadEntry {
  const ChatSeparatorEntry(this.separator);
  final ChatDaySeparator separator;
}

/// En-tête du fil et contenu du panneau de profil (colonnes 4 et 5).
class ContactProfileData {
  const ContactProfileData({
    required this.name,
    this.userId,
    required this.role,
    this.avatarUrl,
    this.presence = PresenceStatus.offline,
    this.phone,
    this.email,
    this.location,
    this.memberSince,
    this.website,
  });

  final String name;

  /// Identifiant du compte, nécessaire pour ouvrir une conversation avec lui.
  final String? userId;

  final String role;
  final String? avatarUrl;
  final PresenceStatus presence;
  final String? phone;
  final String? email;
  final String? location;
  final String? memberSince;
  final String? website;

  /// Projette un compte de l'API dans le modèle de vue du répertoire.
  ///
  /// Les champs que l'API ne fournit pas restent nuls plutôt que d'être
  /// approximés : une ville inventée dans une fiche contact se lit comme une
  /// donnée vérifiée.
  factory ContactProfileData.fromUser(UserEntity user) => ContactProfileData(
    name: user.displayName,
    userId: user.id,
    role: user.role?.label ?? '',
    avatarUrl: user.avatarUrl,
    phone: user.phones.isEmpty ? null : user.phones.first,
    email: user.email,
    // La présence n'est pas exposée par l'API : afficher tout le monde comme
    // « hors ligne » serait faux, mais moins trompeur qu'un point vert inventé.
    presence: PresenceStatus.offline,
  );
}

/// Section de la colonne de navigation (colonne 2).
class WorkspaceSectionData {
  const WorkspaceSectionData({
    required this.id,
    required this.icon,
    required this.label,
    this.badgeCount = 0,
    this.badgeLabel,
  });

  final String id;
  final IconData icon;
  final String label;

  /// Compteur numérique (« 32 »). Ignoré si [badgeLabel] est fourni.
  final int badgeCount;

  /// Badge textuel (« New »), prioritaire sur le compteur.
  final String? badgeLabel;
}

/// Contact épinglé dans la section Favoris.
class WorkspaceFavoriteData {
  const WorkspaceFavoriteData({
    required this.name,
    this.avatarUrl,
    this.badgeCount = 0,
    this.presence = PresenceStatus.offline,
  });

  final String name;
  final String? avatarUrl;
  final int badgeCount;
  final PresenceStatus presence;
}

/// Raccourci vers un dossier ou une collection.
class WorkspaceShortcutData {
  const WorkspaceShortcutData({required this.label, required this.icon});

  final String label;
  final IconData icon;
}
