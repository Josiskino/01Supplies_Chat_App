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
}
