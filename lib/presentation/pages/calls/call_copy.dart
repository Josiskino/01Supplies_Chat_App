import 'package:supplies_calls/support.dart';

import '../../../core/l10n/generated/app_localizations.dart';

/// Agent-facing copy for support calls. Raw error codes and end reasons never
/// reach the screen: every value maps to a translated sentence.
abstract final class CallCopy {
  static String error(AppLocalizations l10n, String code) => switch (code) {
    'unauthorized' => l10n.callErrorUnauthorized,
    'forbidden' => l10n.callErrorForbidden,
    'unavailable' => l10n.callErrorUnavailable,
    'busy' => l10n.callErrorBusy,
    'already_taken' => l10n.callErrorAlreadyTaken,
    'not_found' => l10n.callErrorNotFound,
    'not_accepted' => l10n.callErrorNotAccepted,
    'network' => l10n.callErrorNetwork,
    'audio' => l10n.callErrorAudio,
    'microphone_permission' => l10n.callsMicrophoneRequired,
    'disabled' => l10n.callErrorDisabled,
    'rate_limited' => l10n.callErrorRateLimited,
    'other_device' => l10n.callErrorOtherDevice,
    _ => l10n.callErrorGeneric,
  };

  /// How a terminal call ended, relative to the viewer. Null while active or
  /// when the server gave no reason.
  static String? endReason(
    AppLocalizations l10n,
    SupportCall call, {
    String? viewerId,
  }) => switch (supportCallOutcome(call, viewerId)) {
    SupportCallOutcome.ongoing || SupportCallOutcome.unknown => null,
    SupportCallOutcome.endedByYou => l10n.callEndReasonEndedByYou,
    SupportCallOutcome.endedByPeer => l10n.callEndReasonEndedByPeer,
    SupportCallOutcome.peerLeft => l10n.callEndReasonPeerLeft,
    SupportCallOutcome.network => l10n.callEndReasonNetwork,
    SupportCallOutcome.audioFailed => l10n.callEndReasonAudioFailed,
    SupportCallOutcome.timeout => l10n.callEndReasonTimeout,
    SupportCallOutcome.noAgent => l10n.callEndReasonNoAgent,
    SupportCallOutcome.declined => l10n.callEndReasonDeclined,
    SupportCallOutcome.cancelled => l10n.callEndReasonCancelled,
    SupportCallOutcome.serverRestart => l10n.callEndReasonServerRestart,
    SupportCallOutcome.otherDevice => l10n.callEndReasonOtherDevice,
    SupportCallOutcome.revoked => l10n.callEndReasonRevoked,
    SupportCallOutcome.microphone => l10n.callEndReasonMicrophone,
  };

  static String role(AppLocalizations l10n, String role) =>
      switch (role.split('.').last) {
        'client' || 'customer' => l10n.callRoleClient,
        'driver' => l10n.callRoleDriver,
        'vendor' => l10n.callRoleVendor,
        final other => other,
      };

  static String duration(AppLocalizations l10n, Duration duration) {
    final seconds = duration.inSeconds < 0 ? 0 : duration.inSeconds;
    final minutes = seconds ~/ 60;
    return minutes == 0
        ? l10n.callDurationSeconds(seconds)
        : l10n.callDurationMinutes(minutes, seconds % 60);
  }

  /// Status as seen by an agent. [viewerId] decides whether an unanswered
  /// call counts as missed for this agent.
  static String status(
    AppLocalizations l10n,
    SupportCall call, {
    String? viewerId,
  }) => switch (call.status) {
    SupportCallStatus.ringing =>
      call.isCallback ? l10n.callStatusRinging : l10n.callStatusIncomingRinging,
    SupportCallStatus.accepted =>
      call.isCallback
          ? l10n.callStatusInProgress
          : l10n.callStatusIncomingInProgress,
    SupportCallStatus.rejected => l10n.callStatusDeclined,
    SupportCallStatus.cancelled => l10n.callStatusCancelled,
    SupportCallStatus.expired =>
      call.isCallback
          ? l10n.callStatusNoAnswer
          : call.acceptedAt == null && call.agentId == null
          ? l10n.callStatusMissed
          : l10n.callStatusAnswered,
    SupportCallStatus.unavailable => l10n.callStatusUnavailable,
    SupportCallStatus.ended =>
      call.connectedAt == null || call.isCallback
          ? l10n.callStatusEnded
          : l10n.callStatusIncomingEnded,
  };
}
