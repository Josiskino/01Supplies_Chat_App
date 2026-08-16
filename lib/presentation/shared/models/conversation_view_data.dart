import 'package:flutter/widgets.dart';

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
}

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
    this.isDelivered = true,
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

  final bool isDelivered;

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

  bool get isVoice => voice != null;
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
    this.isVoice = false,
  });

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
  final String role;
  final String? avatarUrl;
  final PresenceStatus presence;
  final String? phone;
  final String? email;
  final String? location;
  final String? memberSince;
  final String? website;
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
