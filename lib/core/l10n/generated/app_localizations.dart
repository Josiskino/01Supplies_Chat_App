import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
  ];

  /// Nom de l'application affiché dans les titres
  ///
  /// In fr, this message translates to:
  /// **'01 Chat'**
  String get appTitle;

  /// No description provided for @appTagline.
  ///
  /// In fr, this message translates to:
  /// **'Messagerie interne logistique'**
  String get appTagline;

  /// Onglet listant les fils de discussion
  ///
  /// In fr, this message translates to:
  /// **'Messages'**
  String get navConversations;

  /// Onglet listant l’historique des appels
  ///
  /// In fr, this message translates to:
  /// **'Appels'**
  String get navCalls;

  /// Onglet de l'annuaire des clients
  ///
  /// In fr, this message translates to:
  /// **'Contacts'**
  String get navContacts;

  /// Onglet du compte et des réglages
  ///
  /// In fr, this message translates to:
  /// **'Réglages'**
  String get navSettings;

  /// No description provided for @conversationsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Conversations'**
  String get conversationsTitle;

  /// No description provided for @conversationsEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucune conversation'**
  String get conversationsEmptyTitle;

  /// No description provided for @conversationsEmptyMessage.
  ///
  /// In fr, this message translates to:
  /// **'Les demandes des clients apparaîtront ici.'**
  String get conversationsEmptyMessage;

  /// No description provided for @callsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Appels'**
  String get callsTitle;

  /// No description provided for @callsEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucun appel'**
  String get callsEmptyTitle;

  /// No description provided for @callsEmptyMessage.
  ///
  /// In fr, this message translates to:
  /// **'L\'historique de vos appels s\'affichera ici.'**
  String get callsEmptyMessage;

  /// No description provided for @contactsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Contacts'**
  String get contactsTitle;

  /// No description provided for @contactsEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucun contact'**
  String get contactsEmptyTitle;

  /// No description provided for @contactsEmptyMessage.
  ///
  /// In fr, this message translates to:
  /// **'L\'annuaire des clients s\'affichera ici.'**
  String get contactsEmptyMessage;

  /// No description provided for @accountTitle.
  ///
  /// In fr, this message translates to:
  /// **'Réglages'**
  String get accountTitle;

  /// No description provided for @settingsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Réglages'**
  String get settingsTitle;

  /// No description provided for @themeLabel.
  ///
  /// In fr, this message translates to:
  /// **'Thème'**
  String get themeLabel;

  /// No description provided for @themeSystem.
  ///
  /// In fr, this message translates to:
  /// **'Système'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In fr, this message translates to:
  /// **'Clair'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In fr, this message translates to:
  /// **'Sombre'**
  String get themeDark;

  /// No description provided for @languageLabel.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get languageLabel;

  /// No description provided for @languageFrench.
  ///
  /// In fr, this message translates to:
  /// **'Français'**
  String get languageFrench;

  /// No description provided for @languageEnglish.
  ///
  /// In fr, this message translates to:
  /// **'Anglais'**
  String get languageEnglish;

  /// No description provided for @signIn.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get signIn;

  /// No description provided for @signOut.
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter'**
  String get signOut;

  /// No description provided for @emailLabel.
  ///
  /// In fr, this message translates to:
  /// **'Adresse e-mail'**
  String get emailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get passwordLabel;

  /// No description provided for @loginTitle.
  ///
  /// In fr, this message translates to:
  /// **'Connexion'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Espace réservé à l\'équipe logistique 01Supplies'**
  String get loginSubtitle;

  /// No description provided for @rememberMe.
  ///
  /// In fr, this message translates to:
  /// **'Rester connecté'**
  String get rememberMe;

  /// No description provided for @forgotPassword.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe oublié ?'**
  String get forgotPassword;

  /// No description provided for @retry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get retry;

  /// No description provided for @cancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer'**
  String get confirm;

  /// No description provided for @search.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher'**
  String get search;

  /// No description provided for @loading.
  ///
  /// In fr, this message translates to:
  /// **'Chargement…'**
  String get loading;

  /// No description provided for @errorGeneric.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur est survenue.'**
  String get errorGeneric;

  /// No description provided for @errorNetwork.
  ///
  /// In fr, this message translates to:
  /// **'Connexion impossible. Vérifiez votre réseau et réessayez.'**
  String get errorNetwork;

  /// Nombre de messages non lus
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucun message non lu} =1{1 message non lu} other{{count} messages non lus}}'**
  String unreadCount(int count);

  /// No description provided for @callsEmptyMessageAgent.
  ///
  /// In fr, this message translates to:
  /// **'Les appels des clients et vos rappels apparaîtront ici.'**
  String get callsEmptyMessageAgent;

  /// No description provided for @callsMissedEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucun appel manqué'**
  String get callsMissedEmptyTitle;

  /// No description provided for @callsUnavailableTitle.
  ///
  /// In fr, this message translates to:
  /// **'Appels indisponibles'**
  String get callsUnavailableTitle;

  /// No description provided for @callsUnavailableMessage.
  ///
  /// In fr, this message translates to:
  /// **'Les appels au support ne sont pas activés.'**
  String get callsUnavailableMessage;

  /// No description provided for @callsFilterAll.
  ///
  /// In fr, this message translates to:
  /// **'Tous'**
  String get callsFilterAll;

  /// No description provided for @callsFilterMissed.
  ///
  /// In fr, this message translates to:
  /// **'Manqués'**
  String get callsFilterMissed;

  /// No description provided for @callsMicrophoneRequired.
  ///
  /// In fr, this message translates to:
  /// **'Autorisez le microphone pour passer et recevoir des appels.'**
  String get callsMicrophoneRequired;

  /// No description provided for @callsAllowMicrophone.
  ///
  /// In fr, this message translates to:
  /// **'Autoriser le microphone'**
  String get callsAllowMicrophone;

  /// No description provided for @callsMicrophoneDialogTitle.
  ///
  /// In fr, this message translates to:
  /// **'Accès au microphone'**
  String get callsMicrophoneDialogTitle;

  /// No description provided for @callsMicrophoneDialogMessage.
  ///
  /// In fr, this message translates to:
  /// **'01 Chat utilise le microphone uniquement pendant vos appels avec les clients. Autorisez-le pour répondre et rappeler.'**
  String get callsMicrophoneDialogMessage;

  /// No description provided for @callsMicrophoneDialogContinue.
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get callsMicrophoneDialogContinue;

  /// No description provided for @availabilityLabel.
  ///
  /// In fr, this message translates to:
  /// **'Statut d\'appel'**
  String get availabilityLabel;

  /// No description provided for @availabilityAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Disponible'**
  String get availabilityAvailable;

  /// No description provided for @availabilityPaused.
  ///
  /// In fr, this message translates to:
  /// **'En pause'**
  String get availabilityPaused;

  /// No description provided for @availabilityBusy.
  ///
  /// In fr, this message translates to:
  /// **'En appel'**
  String get availabilityBusy;

  /// No description provided for @availabilityOffline.
  ///
  /// In fr, this message translates to:
  /// **'Hors ligne'**
  String get availabilityOffline;

  /// No description provided for @availabilityAvailableHint.
  ///
  /// In fr, this message translates to:
  /// **'Vous recevez les appels des clients.'**
  String get availabilityAvailableHint;

  /// No description provided for @availabilityPausedHint.
  ///
  /// In fr, this message translates to:
  /// **'Vous ne recevez plus d\'appels.'**
  String get availabilityPausedHint;

  /// No description provided for @availabilityBusyHint.
  ///
  /// In fr, this message translates to:
  /// **'Les nouveaux appels vont à vos collègues.'**
  String get availabilityBusyHint;

  /// No description provided for @availabilityOfflineHint.
  ///
  /// In fr, this message translates to:
  /// **'Service d\'appels non joignable.'**
  String get availabilityOfflineHint;

  /// No description provided for @incomingCallsTitle.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Appel entrant} other{{count} appels entrants}}'**
  String incomingCallsTitle(int count);

  /// No description provided for @incomingCallAccept.
  ///
  /// In fr, this message translates to:
  /// **'Répondre'**
  String get incomingCallAccept;

  /// No description provided for @incomingCallDecline.
  ///
  /// In fr, this message translates to:
  /// **'Refuser'**
  String get incomingCallDecline;

  /// No description provided for @incomingCallWaiting.
  ///
  /// In fr, this message translates to:
  /// **'Attend depuis {duration}'**
  String incomingCallWaiting(String duration);

  /// No description provided for @callsWaitingQueue.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 appel en attente} other{{count} appels en attente}}'**
  String callsWaitingQueue(int count);

  /// No description provided for @callDurationSeconds.
  ///
  /// In fr, this message translates to:
  /// **'{seconds} s'**
  String callDurationSeconds(int seconds);

  /// No description provided for @callDurationMinutes.
  ///
  /// In fr, this message translates to:
  /// **'{minutes} min {seconds} s'**
  String callDurationMinutes(int minutes, int seconds);

  /// No description provided for @callRoleClient.
  ///
  /// In fr, this message translates to:
  /// **'Client'**
  String get callRoleClient;

  /// No description provided for @callRoleDriver.
  ///
  /// In fr, this message translates to:
  /// **'Livreur'**
  String get callRoleDriver;

  /// No description provided for @callRoleVendor.
  ///
  /// In fr, this message translates to:
  /// **'Vendeur'**
  String get callRoleVendor;

  /// No description provided for @callStatusRinging.
  ///
  /// In fr, this message translates to:
  /// **'Sonnerie…'**
  String get callStatusRinging;

  /// No description provided for @callStatusIncomingRinging.
  ///
  /// In fr, this message translates to:
  /// **'Entrant · sonnerie'**
  String get callStatusIncomingRinging;

  /// No description provided for @callStatusInProgress.
  ///
  /// In fr, this message translates to:
  /// **'En cours'**
  String get callStatusInProgress;

  /// No description provided for @callStatusIncomingInProgress.
  ///
  /// In fr, this message translates to:
  /// **'Entrant · en cours'**
  String get callStatusIncomingInProgress;

  /// No description provided for @callStatusDeclined.
  ///
  /// In fr, this message translates to:
  /// **'Refusé'**
  String get callStatusDeclined;

  /// No description provided for @callStatusCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Annulé'**
  String get callStatusCancelled;

  /// No description provided for @callStatusNoAnswer.
  ///
  /// In fr, this message translates to:
  /// **'Sans réponse'**
  String get callStatusNoAnswer;

  /// No description provided for @callStatusMissed.
  ///
  /// In fr, this message translates to:
  /// **'Manqué'**
  String get callStatusMissed;

  /// No description provided for @callStatusAnswered.
  ///
  /// In fr, this message translates to:
  /// **'Répondu'**
  String get callStatusAnswered;

  /// No description provided for @callStatusUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Support indisponible'**
  String get callStatusUnavailable;

  /// No description provided for @callStatusEnded.
  ///
  /// In fr, this message translates to:
  /// **'Terminé'**
  String get callStatusEnded;

  /// No description provided for @callStatusIncomingEnded.
  ///
  /// In fr, this message translates to:
  /// **'Entrant · terminé'**
  String get callStatusIncomingEnded;

  /// No description provided for @callOutgoing.
  ///
  /// In fr, this message translates to:
  /// **'Sortant · {status}'**
  String callOutgoing(String status);

  /// No description provided for @callAnsweredBy.
  ///
  /// In fr, this message translates to:
  /// **'Répondu par {name}'**
  String callAnsweredBy(String name);

  /// No description provided for @callStartedBy.
  ///
  /// In fr, this message translates to:
  /// **'Lancé par {name}'**
  String callStartedBy(String name);

  /// No description provided for @callEndReasonEndedByYou.
  ///
  /// In fr, this message translates to:
  /// **'Vous avez raccroché'**
  String get callEndReasonEndedByYou;

  /// No description provided for @callEndReasonEndedByPeer.
  ///
  /// In fr, this message translates to:
  /// **'Raccroché par l\'interlocuteur'**
  String get callEndReasonEndedByPeer;

  /// No description provided for @callEndReasonPeerLeft.
  ///
  /// In fr, this message translates to:
  /// **'Interlocuteur déconnecté'**
  String get callEndReasonPeerLeft;

  /// No description provided for @callEndReasonAudioFailed.
  ///
  /// In fr, this message translates to:
  /// **'Échec de la connexion audio'**
  String get callEndReasonAudioFailed;

  /// No description provided for @callEndReasonNetwork.
  ///
  /// In fr, this message translates to:
  /// **'Coupure réseau'**
  String get callEndReasonNetwork;

  /// No description provided for @callEndReasonTimeout.
  ///
  /// In fr, this message translates to:
  /// **'Personne n\'a répondu à temps'**
  String get callEndReasonTimeout;

  /// No description provided for @callEndReasonNoAgent.
  ///
  /// In fr, this message translates to:
  /// **'Aucun agent disponible'**
  String get callEndReasonNoAgent;

  /// No description provided for @callEndReasonDeclined.
  ///
  /// In fr, this message translates to:
  /// **'Refusé'**
  String get callEndReasonDeclined;

  /// No description provided for @callEndReasonCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Raccroché par l\'appelant'**
  String get callEndReasonCancelled;

  /// No description provided for @callEndReasonServerRestart.
  ///
  /// In fr, this message translates to:
  /// **'Redémarrage du service'**
  String get callEndReasonServerRestart;

  /// No description provided for @callEndReasonOtherDevice.
  ///
  /// In fr, this message translates to:
  /// **'Pris sur un autre appareil'**
  String get callEndReasonOtherDevice;

  /// No description provided for @callEndReasonRevoked.
  ///
  /// In fr, this message translates to:
  /// **'Accès révoqué'**
  String get callEndReasonRevoked;

  /// No description provided for @callEndReasonMicrophone.
  ///
  /// In fr, this message translates to:
  /// **'Microphone indisponible'**
  String get callEndReasonMicrophone;

  /// No description provided for @callCallback.
  ///
  /// In fr, this message translates to:
  /// **'Rappeler'**
  String get callCallback;

  /// No description provided for @callCallbackTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Appeler le client'**
  String get callCallbackTooltip;

  /// No description provided for @callOpenConversation.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir la conversation'**
  String get callOpenConversation;

  /// No description provided for @callMinimize.
  ///
  /// In fr, this message translates to:
  /// **'Réduire'**
  String get callMinimize;

  /// No description provided for @callNoActive.
  ///
  /// In fr, this message translates to:
  /// **'Aucun appel en cours'**
  String get callNoActive;

  /// No description provided for @callIncomingAudio.
  ///
  /// In fr, this message translates to:
  /// **'Appel audio entrant'**
  String get callIncomingAudio;

  /// No description provided for @callConnecting.
  ///
  /// In fr, this message translates to:
  /// **'Connexion audio…'**
  String get callConnecting;

  /// No description provided for @callMute.
  ///
  /// In fr, this message translates to:
  /// **'Couper le micro'**
  String get callMute;

  /// No description provided for @callUnmute.
  ///
  /// In fr, this message translates to:
  /// **'Activer le micro'**
  String get callUnmute;

  /// No description provided for @callSpeaker.
  ///
  /// In fr, this message translates to:
  /// **'Haut-parleur'**
  String get callSpeaker;

  /// No description provided for @callEarpiece.
  ///
  /// In fr, this message translates to:
  /// **'Écouteur'**
  String get callEarpiece;

  /// No description provided for @callHangUp.
  ///
  /// In fr, this message translates to:
  /// **'Raccrocher'**
  String get callHangUp;

  /// No description provided for @callHealthLocalPoor.
  ///
  /// In fr, this message translates to:
  /// **'Votre connexion est instable'**
  String get callHealthLocalPoor;

  /// No description provided for @callHealthRemotePoor.
  ///
  /// In fr, this message translates to:
  /// **'La connexion de votre interlocuteur est instable'**
  String get callHealthRemotePoor;

  /// No description provided for @callHealthReconnecting.
  ///
  /// In fr, this message translates to:
  /// **'Reconnexion audio…'**
  String get callHealthReconnecting;

  /// No description provided for @callSupportBrand.
  ///
  /// In fr, this message translates to:
  /// **'Support 01Supplies'**
  String get callSupportBrand;

  /// No description provided for @callOpen.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir l\'appel'**
  String get callOpen;

  /// No description provided for @callErrorUnauthorized.
  ///
  /// In fr, this message translates to:
  /// **'Session d\'appel expirée. Reconnectez-vous.'**
  String get callErrorUnauthorized;

  /// No description provided for @callErrorForbidden.
  ///
  /// In fr, this message translates to:
  /// **'Action non autorisée sur cet appel.'**
  String get callErrorForbidden;

  /// No description provided for @callErrorUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Service d\'appels indisponible pour le moment.'**
  String get callErrorUnavailable;

  /// No description provided for @callErrorBusy.
  ///
  /// In fr, this message translates to:
  /// **'Vous êtes déjà en appel.'**
  String get callErrorBusy;

  /// No description provided for @callErrorAlreadyTaken.
  ///
  /// In fr, this message translates to:
  /// **'Un collègue a déjà pris cet appel.'**
  String get callErrorAlreadyTaken;

  /// No description provided for @callErrorNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Cet appel n\'existe plus.'**
  String get callErrorNotFound;

  /// No description provided for @callErrorNotAccepted.
  ///
  /// In fr, this message translates to:
  /// **'L\'appel n\'a pas encore été accepté.'**
  String get callErrorNotAccepted;

  /// No description provided for @callErrorNetwork.
  ///
  /// In fr, this message translates to:
  /// **'Connexion au service d\'appels impossible. Vérifiez votre réseau.'**
  String get callErrorNetwork;

  /// No description provided for @callErrorAudio.
  ///
  /// In fr, this message translates to:
  /// **'La connexion audio a échoué.'**
  String get callErrorAudio;

  /// No description provided for @callErrorDisabled.
  ///
  /// In fr, this message translates to:
  /// **'Les appels sont temporairement désactivés.'**
  String get callErrorDisabled;

  /// No description provided for @callErrorRateLimited.
  ///
  /// In fr, this message translates to:
  /// **'Trop de tentatives. Patientez quelques secondes.'**
  String get callErrorRateLimited;

  /// No description provided for @callErrorOtherDevice.
  ///
  /// In fr, this message translates to:
  /// **'Appel pris sur un autre appareil'**
  String get callErrorOtherDevice;

  /// No description provided for @callErrorGeneric.
  ///
  /// In fr, this message translates to:
  /// **'L\'appel a échoué.'**
  String get callErrorGeneric;

  /// No description provided for @callNotificationTitle.
  ///
  /// In fr, this message translates to:
  /// **'Appel entrant · {name}'**
  String callNotificationTitle(String name);

  /// No description provided for @callRingtoneMute.
  ///
  /// In fr, this message translates to:
  /// **'Couper la sonnerie'**
  String get callRingtoneMute;

  /// No description provided for @callRingtoneUnmute.
  ///
  /// In fr, this message translates to:
  /// **'Activer la sonnerie'**
  String get callRingtoneUnmute;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
