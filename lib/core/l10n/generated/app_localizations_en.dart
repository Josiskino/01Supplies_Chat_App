// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => '01 Chat';

  @override
  String get appTagline => 'Internal logistics messaging';

  @override
  String get navConversations => 'Messages';

  @override
  String get navCalls => 'Calls';

  @override
  String get navContacts => 'Contacts';

  @override
  String get navSettings => 'Settings';

  @override
  String get conversationsTitle => 'Conversations';

  @override
  String get conversationsEmptyTitle => 'No conversations';

  @override
  String get conversationsEmptyMessage =>
      'Customer requests will show up here.';

  @override
  String get callsTitle => 'Calls';

  @override
  String get callsEmptyTitle => 'No calls';

  @override
  String get callsEmptyMessage => 'Your call history will show up here.';

  @override
  String get contactsTitle => 'Contacts';

  @override
  String get contactsEmptyTitle => 'No contacts';

  @override
  String get contactsEmptyMessage =>
      'The customer directory will show up here.';

  @override
  String get accountTitle => 'Settings';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get themeLabel => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get languageLabel => 'Language';

  @override
  String get languageFrench => 'French';

  @override
  String get languageEnglish => 'English';

  @override
  String get signIn => 'Sign in';

  @override
  String get signOut => 'Sign out';

  @override
  String get emailLabel => 'Email address';

  @override
  String get passwordLabel => 'Password';

  @override
  String get loginTitle => 'Sign in';

  @override
  String get loginSubtitle => 'Restricted to the 01Supplies logistics team';

  @override
  String get rememberMe => 'Stay signed in';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get retry => 'Retry';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get search => 'Search';

  @override
  String get loading => 'Loading…';

  @override
  String get errorGeneric => 'Something went wrong.';

  @override
  String get errorNetwork =>
      'Can\'t connect. Check your network and try again.';

  @override
  String unreadCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count unread messages',
      one: '1 unread message',
      zero: 'No unread messages',
    );
    return '$_temp0';
  }
}
