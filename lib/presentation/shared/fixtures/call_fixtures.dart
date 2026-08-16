import '../models/call_view_data.dart';

/// Appel de démonstration.
///
/// ⚠️ Contenu de maquette. La feature temps réel remplacera cette source par un
/// provider branché sur le transport, sans toucher à la présentation.
abstract final class CallFixtures {
  /// Historique de démonstration.
  static const List<CallLogEntry> history = [
    CallLogEntry(
      id: 'l1',
      name: 'Kofi Adjei',
      direction: CallDirection.missed,
      timeLabel: '12:04',
      repeatCount: 2,
    ),
    CallLogEntry(
      id: 'l2',
      name: 'Awa Traoré',
      direction: CallDirection.outgoing,
      timeLabel: '11:38',
      duration: Duration(minutes: 6, seconds: 12),
    ),
    CallLogEntry(
      id: 'l3',
      name: 'Tournée du matin',
      direction: CallDirection.outgoing,
      timeLabel: '09:15',
      isVideo: true,
      duration: Duration(minutes: 24),
    ),
    CallLogEntry(
      id: 'l4',
      name: 'Fatou Diallo',
      direction: CallDirection.incoming,
      timeLabel: 'Hier',
      duration: Duration(minutes: 2, seconds: 40),
    ),
    CallLogEntry(
      id: 'l5',
      name: 'Ibrahim Sow',
      direction: CallDirection.missed,
      timeLabel: 'Hier',
    ),
    CallLogEntry(
      id: 'l6',
      name: 'Kwame Mensah',
      direction: CallDirection.incoming,
      timeLabel: 'Hier',
      isVideo: true,
      duration: Duration(minutes: 11, seconds: 5),
    ),
    CallLogEntry(
      id: 'l7',
      name: 'Yao Kouassi',
      direction: CallDirection.outgoing,
      timeLabel: '12 août',
      duration: Duration(seconds: 45),
    ),
    CallLogEntry(
      id: 'l8',
      name: 'Adjoa Bamba',
      direction: CallDirection.missed,
      timeLabel: '12 août',
      repeatCount: 3,
    ),
    CallLogEntry(
      id: 'l9',
      name: 'Mariam Cissé',
      direction: CallDirection.incoming,
      timeLabel: '11 août',
      duration: Duration(minutes: 4, seconds: 18),
    ),
    CallLogEntry(
      id: 'l10',
      name: 'Seydou Koné',
      direction: CallDirection.outgoing,
      timeLabel: '11 août',
      duration: Duration(minutes: 1, seconds: 30),
    ),
  ];

  /// Agents qu'on peut faire entrer en cours d'appel.
  static const List<String> invitables = [
    'Mariam Cissé',
    'Seydou Koné',
    'Adjoa Bamba',
    'Aminata Barry',
  ];

  static CallSessionData session([String? title]) => CallSessionData(
    title: title ?? 'Tournée du matin — secteur Cocody',
    subtitle: 'Point logistique quotidien',
    isRecording: true,
    // Deux places libres : la grille montre qu'on peut encore inviter, ce
    // qu'un bouton seul n'aurait pas dit.
    freeSlots: 2,
    participants: const [
      CallParticipantData(
        id: 'self',
        name: 'Vous',
        isSelf: true,
        isSpeaking: true,
      ),
      CallParticipantData(id: 'p1', name: 'Awa Traoré', handle: 'awa'),
      CallParticipantData(
        id: 'p2',
        name: 'Kwame Mensah',
        handle: 'kwame',
        isMuted: true,
      ),
      // Une seule voix à la fois : deux halos simultanés donnent une grille
      // qui clignote et on ne sait plus qui parle.
      CallParticipantData(id: 'p3', name: 'Fatou Diallo', handle: 'fatou'),
      CallParticipantData(id: 'p4', name: 'Yao Kouassi', handle: 'yao'),
      CallParticipantData(
        id: 'p5',
        name: 'Ibrahim Sow',
        handle: 'ibrahim',
        isMuted: true,
      ),
    ],
  );
}
