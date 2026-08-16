/// Un participant à un appel de groupe.
class CallParticipantData {
  const CallParticipantData({
    required this.id,
    required this.name,
    this.handle,
    this.avatarUrl,
    this.isMuted = false,
    this.isSpeaking = false,
    this.isSelf = false,
  });

  final String id;
  final String name;

  /// Identifiant court affiché sous l'avatar (`@awa`). À défaut, le prénom.
  final String? handle;

  final String? avatarUrl;

  /// Micro coupé : la pastille passe au rouge barré.
  final bool isMuted;

  /// Parle en ce moment — l'anneau de l'avatar s'anime.
  ///
  /// Distinct de `!isMuted` : un micro ouvert sur quelqu'un qui se tait ne doit
  /// pas attirer l'œil, sinon toute la grille clignote en permanence.
  final bool isSpeaking;

  /// L'utilisateur courant, placé au centre et affiché plus grand.
  final bool isSelf;

  String get displayHandle => handle ?? name.split(' ').first.toLowerCase();
}

/// État d'un appel en cours.
class CallSessionData {
  const CallSessionData({
    required this.title,
    required this.participants,
    this.subtitle,
    this.freeSlots = 0,
    this.isRecording = false,
  });

  /// Sujet de l'appel — le nom de la conversation dont il est parti.
  final String title;

  final String? subtitle;

  final List<CallParticipantData> participants;

  /// Emplacements vides offrant d'inviter quelqu'un.
  ///
  /// Rendus comme des pastilles « + » à la place d'un participant : montrer la
  /// place libre invite plus sûrement qu'un bouton d'ajout relégué dans un menu.
  final int freeSlots;

  final bool isRecording;

  CallParticipantData? get self =>
      participants.where((p) => p.isSelf).firstOrNull;

  List<CallParticipantData> get others =>
      participants.where((p) => !p.isSelf).toList();
}
