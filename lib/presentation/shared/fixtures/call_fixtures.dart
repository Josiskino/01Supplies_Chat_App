import '../models/call_view_data.dart';

/// Appel de démonstration.
///
/// ⚠️ Contenu de maquette. La feature temps réel remplacera cette source par un
/// provider branché sur le transport, sans toucher à la présentation.
abstract final class CallFixtures {
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
      CallParticipantData(
        id: 'p3',
        name: 'Fatou Diallo',
        handle: 'fatou',
        isSpeaking: true,
      ),
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
