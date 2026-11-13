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

  @override
  String get callsEmptyMessageAgent =>
      'Customer calls and your callbacks will appear here.';

  @override
  String get callsMissedEmptyTitle => 'No missed calls';

  @override
  String get callsUnavailableTitle => 'Calls unavailable';

  @override
  String get callsUnavailableMessage => 'Support calls are not enabled.';

  @override
  String get callsFilterAll => 'All';

  @override
  String get callsFilterMissed => 'Missed';

  @override
  String get callsMicrophoneRequired =>
      'Allow the microphone to make and receive calls.';

  @override
  String get callsAllowMicrophone => 'Allow microphone';

  @override
  String get callsMicrophoneDialogTitle => 'Microphone access';

  @override
  String get callsMicrophoneDialogMessage =>
      '01 Chat only uses the microphone during your calls with customers. Allow it to answer and call back.';

  @override
  String get callsMicrophoneDialogContinue => 'Continue';

  @override
  String get availabilityLabel => 'Call status';

  @override
  String get availabilityAvailable => 'Available';

  @override
  String get availabilityPaused => 'Paused';

  @override
  String get availabilityBusy => 'In a call';

  @override
  String get availabilityOffline => 'Offline';

  @override
  String get availabilityAvailableHint => 'You receive customer calls.';

  @override
  String get availabilityPausedHint => 'You no longer receive calls.';

  @override
  String get availabilityBusyHint => 'New calls go to your colleagues.';

  @override
  String get availabilityOfflineHint => 'Call service unreachable.';

  @override
  String incomingCallsTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count incoming calls',
      one: 'Incoming call',
    );
    return '$_temp0';
  }

  @override
  String get incomingCallAccept => 'Answer';

  @override
  String get incomingCallDecline => 'Decline';

  @override
  String incomingCallWaiting(String duration) {
    return 'Waiting for $duration';
  }

  @override
  String callsWaitingQueue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count calls waiting',
      one: '1 call waiting',
    );
    return '$_temp0';
  }

  @override
  String callDurationSeconds(int seconds) {
    return '${seconds}s';
  }

  @override
  String callDurationMinutes(int minutes, int seconds) {
    return '${minutes}m ${seconds}s';
  }

  @override
  String get callRoleClient => 'Customer';

  @override
  String get callRoleDriver => 'Driver';

  @override
  String get callRoleVendor => 'Vendor';

  @override
  String get callStatusRinging => 'Ringing…';

  @override
  String get callStatusIncomingRinging => 'Incoming · ringing';

  @override
  String get callStatusInProgress => 'In progress';

  @override
  String get callStatusIncomingInProgress => 'Incoming · in progress';

  @override
  String get callStatusDeclined => 'Declined';

  @override
  String get callStatusCancelled => 'Cancelled';

  @override
  String get callStatusNoAnswer => 'No answer';

  @override
  String get callStatusMissed => 'Missed';

  @override
  String get callStatusAnswered => 'Answered';

  @override
  String get callStatusUnavailable => 'Support unavailable';

  @override
  String get callStatusEnded => 'Ended';

  @override
  String get callStatusIncomingEnded => 'Incoming · ended';

  @override
  String callOutgoing(String status) {
    return 'Outgoing · $status';
  }

  @override
  String callAnsweredBy(String name) {
    return 'Answered by $name';
  }

  @override
  String callStartedBy(String name) {
    return 'Started by $name';
  }

  @override
  String get callEndReasonEndedByYou => 'You hung up';

  @override
  String get callEndReasonEndedByPeer => 'The other party hung up';

  @override
  String get callEndReasonPeerLeft => 'Other party left';

  @override
  String get callEndReasonAudioFailed => 'Audio connection failed';

  @override
  String get callEndReasonNetwork => 'Network lost';

  @override
  String get callEndReasonTimeout => 'Nobody answered in time';

  @override
  String get callEndReasonNoAgent => 'No agent available';

  @override
  String get callEndReasonDeclined => 'Declined';

  @override
  String get callEndReasonCancelled => 'Caller hung up';

  @override
  String get callEndReasonServerRestart => 'Service restarted';

  @override
  String get callEndReasonOtherDevice => 'Taken on another device';

  @override
  String get callEndReasonRevoked => 'Access revoked';

  @override
  String get callEndReasonMicrophone => 'Microphone unavailable';

  @override
  String get callCallback => 'Call back';

  @override
  String get callCallbackTooltip => 'Call the customer';

  @override
  String get callOpenConversation => 'Open conversation';

  @override
  String get callMinimize => 'Minimize';

  @override
  String get callNoActive => 'No call in progress';

  @override
  String get callIncomingAudio => 'Incoming audio call';

  @override
  String get callConnecting => 'Connecting audio…';

  @override
  String get callMute => 'Mute';

  @override
  String get callUnmute => 'Unmute';

  @override
  String get callSpeaker => 'Speaker';

  @override
  String get callEarpiece => 'Earpiece';

  @override
  String get callHangUp => 'Hang up';

  @override
  String get callHealthLocalPoor => 'Your connection is unstable';

  @override
  String get callHealthRemotePoor =>
      'The other party\'s connection is unstable';

  @override
  String get callHealthReconnecting => 'Reconnecting audio…';

  @override
  String get callSupportBrand => '01Supplies Support';

  @override
  String get callOpen => 'Open call';

  @override
  String get callErrorUnauthorized => 'Call session expired. Sign in again.';

  @override
  String get callErrorForbidden => 'This action is not allowed on this call.';

  @override
  String get callErrorUnavailable =>
      'The call service is unavailable right now.';

  @override
  String get callErrorBusy => 'You are already in a call.';

  @override
  String get callErrorAlreadyTaken => 'A colleague already took this call.';

  @override
  String get callErrorNotFound => 'This call no longer exists.';

  @override
  String get callErrorNotAccepted => 'The call has not been accepted yet.';

  @override
  String get callErrorNetwork =>
      'Can\'t reach the call service. Check your network.';

  @override
  String get callErrorAudio => 'The audio connection failed.';

  @override
  String get callErrorDisabled => 'Calls are temporarily disabled.';

  @override
  String get callErrorRateLimited => 'Too many attempts. Wait a few seconds.';

  @override
  String get callErrorOtherDevice => 'Call taken on another device';

  @override
  String get callErrorGeneric => 'The call failed.';

  @override
  String callNotificationTitle(String name) {
    return 'Incoming call · $name';
  }

  @override
  String get callRingtoneMute => 'Mute ringtone';

  @override
  String get callRingtoneUnmute => 'Unmute ringtone';
}
