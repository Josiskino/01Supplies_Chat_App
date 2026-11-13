// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => '01 Chat';

  @override
  String get appTagline => 'Messagerie interne logistique';

  @override
  String get navConversations => 'Messages';

  @override
  String get navCalls => 'Appels';

  @override
  String get navContacts => 'Contacts';

  @override
  String get navSettings => 'Réglages';

  @override
  String get conversationsTitle => 'Conversations';

  @override
  String get conversationsEmptyTitle => 'Aucune conversation';

  @override
  String get conversationsEmptyMessage =>
      'Les demandes des clients apparaîtront ici.';

  @override
  String get callsTitle => 'Appels';

  @override
  String get callsEmptyTitle => 'Aucun appel';

  @override
  String get callsEmptyMessage =>
      'L\'historique de vos appels s\'affichera ici.';

  @override
  String get contactsTitle => 'Contacts';

  @override
  String get contactsEmptyTitle => 'Aucun contact';

  @override
  String get contactsEmptyMessage =>
      'L\'annuaire des clients s\'affichera ici.';

  @override
  String get accountTitle => 'Réglages';

  @override
  String get settingsTitle => 'Réglages';

  @override
  String get themeLabel => 'Thème';

  @override
  String get themeSystem => 'Système';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeDark => 'Sombre';

  @override
  String get languageLabel => 'Langue';

  @override
  String get languageFrench => 'Français';

  @override
  String get languageEnglish => 'Anglais';

  @override
  String get signIn => 'Se connecter';

  @override
  String get signOut => 'Se déconnecter';

  @override
  String get emailLabel => 'Adresse e-mail';

  @override
  String get passwordLabel => 'Mot de passe';

  @override
  String get loginTitle => 'Connexion';

  @override
  String get loginSubtitle =>
      'Espace réservé à l\'équipe logistique 01Supplies';

  @override
  String get rememberMe => 'Rester connecté';

  @override
  String get forgotPassword => 'Mot de passe oublié ?';

  @override
  String get retry => 'Réessayer';

  @override
  String get cancel => 'Annuler';

  @override
  String get confirm => 'Confirmer';

  @override
  String get search => 'Rechercher';

  @override
  String get loading => 'Chargement…';

  @override
  String get errorGeneric => 'Une erreur est survenue.';

  @override
  String get errorNetwork =>
      'Connexion impossible. Vérifiez votre réseau et réessayez.';

  @override
  String unreadCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count messages non lus',
      one: '1 message non lu',
      zero: 'Aucun message non lu',
    );
    return '$_temp0';
  }

  @override
  String get callsEmptyMessageAgent =>
      'Les appels des clients et vos rappels apparaîtront ici.';

  @override
  String get callsMissedEmptyTitle => 'Aucun appel manqué';

  @override
  String get callsUnavailableTitle => 'Appels indisponibles';

  @override
  String get callsUnavailableMessage =>
      'Les appels au support ne sont pas activés.';

  @override
  String get callsFilterAll => 'Tous';

  @override
  String get callsFilterMissed => 'Manqués';

  @override
  String get callsMicrophoneRequired =>
      'Autorisez le microphone pour passer et recevoir des appels.';

  @override
  String get callsAllowMicrophone => 'Autoriser le microphone';

  @override
  String get callsMicrophoneDialogTitle => 'Accès au microphone';

  @override
  String get callsMicrophoneDialogMessage =>
      '01 Chat utilise le microphone uniquement pendant vos appels avec les clients. Autorisez-le pour répondre et rappeler.';

  @override
  String get callsMicrophoneDialogContinue => 'Continuer';

  @override
  String get availabilityLabel => 'Statut d\'appel';

  @override
  String get availabilityAvailable => 'Disponible';

  @override
  String get availabilityPaused => 'En pause';

  @override
  String get availabilityBusy => 'En appel';

  @override
  String get availabilityOffline => 'Hors ligne';

  @override
  String get availabilityAvailableHint =>
      'Vous recevez les appels des clients.';

  @override
  String get availabilityPausedHint => 'Vous ne recevez plus d\'appels.';

  @override
  String get availabilityBusyHint =>
      'Les nouveaux appels vont à vos collègues.';

  @override
  String get availabilityOfflineHint => 'Service d\'appels non joignable.';

  @override
  String incomingCallsTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count appels entrants',
      one: 'Appel entrant',
    );
    return '$_temp0';
  }

  @override
  String get incomingCallAccept => 'Répondre';

  @override
  String get incomingCallDecline => 'Refuser';

  @override
  String incomingCallWaiting(String duration) {
    return 'Attend depuis $duration';
  }

  @override
  String callsWaitingQueue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count appels en attente',
      one: '1 appel en attente',
    );
    return '$_temp0';
  }

  @override
  String callDurationSeconds(int seconds) {
    return '$seconds s';
  }

  @override
  String callDurationMinutes(int minutes, int seconds) {
    return '$minutes min $seconds s';
  }

  @override
  String get callRoleClient => 'Client';

  @override
  String get callRoleDriver => 'Livreur';

  @override
  String get callRoleVendor => 'Vendeur';

  @override
  String get callStatusRinging => 'Sonnerie…';

  @override
  String get callStatusIncomingRinging => 'Entrant · sonnerie';

  @override
  String get callStatusInProgress => 'En cours';

  @override
  String get callStatusIncomingInProgress => 'Entrant · en cours';

  @override
  String get callStatusDeclined => 'Refusé';

  @override
  String get callStatusCancelled => 'Annulé';

  @override
  String get callStatusNoAnswer => 'Sans réponse';

  @override
  String get callStatusMissed => 'Manqué';

  @override
  String get callStatusAnswered => 'Répondu';

  @override
  String get callStatusUnavailable => 'Support indisponible';

  @override
  String get callStatusEnded => 'Terminé';

  @override
  String get callStatusIncomingEnded => 'Entrant · terminé';

  @override
  String callOutgoing(String status) {
    return 'Sortant · $status';
  }

  @override
  String callAnsweredBy(String name) {
    return 'Répondu par $name';
  }

  @override
  String callStartedBy(String name) {
    return 'Lancé par $name';
  }

  @override
  String get callEndReasonEndedByYou => 'Vous avez raccroché';

  @override
  String get callEndReasonEndedByPeer => 'Raccroché par l\'interlocuteur';

  @override
  String get callEndReasonPeerLeft => 'Interlocuteur déconnecté';

  @override
  String get callEndReasonAudioFailed => 'Échec de la connexion audio';

  @override
  String get callEndReasonNetwork => 'Coupure réseau';

  @override
  String get callEndReasonTimeout => 'Personne n\'a répondu à temps';

  @override
  String get callEndReasonNoAgent => 'Aucun agent disponible';

  @override
  String get callEndReasonDeclined => 'Refusé';

  @override
  String get callEndReasonCancelled => 'Raccroché par l\'appelant';

  @override
  String get callEndReasonServerRestart => 'Redémarrage du service';

  @override
  String get callEndReasonOtherDevice => 'Pris sur un autre appareil';

  @override
  String get callEndReasonRevoked => 'Accès révoqué';

  @override
  String get callEndReasonMicrophone => 'Microphone indisponible';

  @override
  String get callCallback => 'Rappeler';

  @override
  String get callCallbackTooltip => 'Appeler le client';

  @override
  String get callOpenConversation => 'Ouvrir la conversation';

  @override
  String get callMinimize => 'Réduire';

  @override
  String get callNoActive => 'Aucun appel en cours';

  @override
  String get callIncomingAudio => 'Appel audio entrant';

  @override
  String get callConnecting => 'Connexion audio…';

  @override
  String get callMute => 'Couper le micro';

  @override
  String get callUnmute => 'Activer le micro';

  @override
  String get callSpeaker => 'Haut-parleur';

  @override
  String get callEarpiece => 'Écouteur';

  @override
  String get callHangUp => 'Raccrocher';

  @override
  String get callHealthLocalPoor => 'Votre connexion est instable';

  @override
  String get callHealthRemotePoor =>
      'La connexion de votre interlocuteur est instable';

  @override
  String get callHealthReconnecting => 'Reconnexion audio…';

  @override
  String get callSupportBrand => 'Support 01Supplies';

  @override
  String get callOpen => 'Ouvrir l\'appel';

  @override
  String get callErrorUnauthorized =>
      'Session d\'appel expirée. Reconnectez-vous.';

  @override
  String get callErrorForbidden => 'Action non autorisée sur cet appel.';

  @override
  String get callErrorUnavailable =>
      'Service d\'appels indisponible pour le moment.';

  @override
  String get callErrorBusy => 'Vous êtes déjà en appel.';

  @override
  String get callErrorAlreadyTaken => 'Un collègue a déjà pris cet appel.';

  @override
  String get callErrorNotFound => 'Cet appel n\'existe plus.';

  @override
  String get callErrorNotAccepted => 'L\'appel n\'a pas encore été accepté.';

  @override
  String get callErrorNetwork =>
      'Connexion au service d\'appels impossible. Vérifiez votre réseau.';

  @override
  String get callErrorAudio => 'La connexion audio a échoué.';

  @override
  String get callErrorDisabled => 'Les appels sont temporairement désactivés.';

  @override
  String get callErrorRateLimited =>
      'Trop de tentatives. Patientez quelques secondes.';

  @override
  String get callErrorOtherDevice => 'Appel pris sur un autre appareil';

  @override
  String get callErrorGeneric => 'L\'appel a échoué.';

  @override
  String callNotificationTitle(String name) {
    return 'Appel entrant · $name';
  }

  @override
  String get callRingtoneMute => 'Couper la sonnerie';

  @override
  String get callRingtoneUnmute => 'Activer la sonnerie';
}
