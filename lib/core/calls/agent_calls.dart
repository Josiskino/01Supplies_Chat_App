import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supplies_calls/support.dart';

part 'agent_calls.g.dart';

/// Agent-side view of the support calls state.
///
/// Every screen of 01 Chat reads calls through this snapshot instead of the
/// package state directly. It is the single seam with `supplies_calls`: when
/// the package contract evolves, only [agentCallsSnapshotOf] and
/// [SupportAgentCallActions] change, and widget tests override
/// [agentCallsProvider] / [agentCallActionsProvider] without building the
/// whole calls stack.
class AgentCallsSnapshot {
  const AgentCallsSnapshot({
    this.identity,
    this.active,
    this.incoming = const [],
    this.availability = SupportAgentAvailability.offline,
    this.callsEnabled = true,
    this.queueLength = 0,
    this.agentsAvailable = 0,
    this.history = const [],
    this.historyLoaded = false,
    this.error,
    this.busy = false,
  });

  final String? identity;

  /// Call this agent is part of (accepted here, callback, or the call shown
  /// on the call screen). Ringing offers live in [incoming].
  final SupportCall? active;

  /// Calls currently offered to this agent, oldest first.
  final List<SupportCall> incoming;

  /// One of [SupportAgentAvailability] values.
  final String availability;

  /// Server kill switch. When false, no call UI is offered.
  final bool callsEnabled;

  /// Customer calls waiting for any agent.
  final int queueLength;
  final int agentsAvailable;
  final List<SupportCall> history;
  final bool historyLoaded;
  final String? error;
  final bool busy;

  /// The agent is talking (or connecting) on an accepted call.
  bool get inCall =>
      active != null &&
      active!.status == SupportCallStatus.accepted &&
      (identity == null || active!.agentId == identity);

  /// Outgoing callback still ringing on the customer side.
  bool get callbackRinging =>
      active != null &&
      active!.isCallback &&
      active!.status == SupportCallStatus.ringing;
}

/// Single definition of a missed call, shared by the history filter, the
/// Calls badge and notifications (spec §1.5). Delegates to the package.
bool supportCallMissedFor(SupportCall call, String? viewerId) =>
    isMissedFor(call, viewerId ?? '');

/// Maps the package state to the agent snapshot.
///
/// The package keeps the oldest offer in `active` for legacy callers; here an
/// offer only lives in [AgentCallsSnapshot.incoming], so `active` always means
/// a call this device takes part in (or the last outcome).
AgentCallsSnapshot agentCallsSnapshotOf(SupportCallState state) {
  final identity = state.identity;
  final active = state.active;
  final isOffer =
      identity != null &&
      active != null &&
      !active.isCallback &&
      active.offeredTo(identity);
  return AgentCallsSnapshot(
    identity: identity,
    active: isOffer ? null : active,
    incoming: state.incoming,
    availability: identity == null
        ? SupportAgentAvailability.offline
        : state.availability,
    callsEnabled: state.callsEnabled,
    queueLength: state.queueLength,
    agentsAvailable: state.agentsAvailable,
    history: state.history,
    historyLoaded: state.historyLoaded,
    error: state.error,
    busy: state.busy,
  );
}

/// Commands the agent UI can issue. Always by call id: with several offers on
/// screen, acting on "the current call" would answer the wrong customer.
abstract interface class AgentCallActions {
  Future<void> accept(String callId);
  Future<void> reject(String callId);
  Future<void> setAvailability(String mode);
  Future<void> callback(String conversationId);
  Future<void> end();

  /// Whether the OS already granted the microphone. Null when the platform
  /// has no runtime permission (desktop builds without a permission plugin).
  Future<bool?> microphoneGranted();

  /// Asks the OS for the microphone. Call only after explaining why.
  Future<void> requestMicrophone();
}

@Riverpod(keepAlive: true)
AgentCallsSnapshot agentCalls(Ref ref) =>
    agentCallsSnapshotOf(ref.watch(supportCallControllerProvider));

@Riverpod(keepAlive: true)
AgentCallActions agentCallActions(Ref ref) => SupportAgentCallActions(ref);

class SupportAgentCallActions implements AgentCallActions {
  SupportAgentCallActions(this._ref);
  final Ref _ref;

  SupportCallController get _controller =>
      _ref.read(supportCallControllerProvider.notifier);

  @override
  Future<void> accept(String callId) => _controller.accept(callId);

  @override
  Future<void> reject(String callId) => _controller.reject(callId);

  @override
  Future<void> setAvailability(String mode) =>
      _controller.setAvailability(mode);

  @override
  Future<void> callback(String conversationId) =>
      _controller.start(conversationId);

  @override
  Future<void> end() => _controller.end();

  @override
  Future<bool?> microphoneGranted() async =>
      _ref.read(supportMicrophonePermissionProvider)?.isGranted();

  @override
  Future<void> requestMicrophone() => _controller.prepareMicrophone();
}

/// Persists when the agent last looked at the call history, per account.
abstract interface class MissedCallsSeenStore {
  Future<DateTime?> read(String identity);
}

class InMemoryMissedCallsSeenStore implements MissedCallsSeenStore {
  @override
  Future<DateTime?> read(String identity) async => null;
}

@Riverpod(keepAlive: true)
MissedCallsSeenStore missedCallsSeenStore(Ref ref) =>
    InMemoryMissedCallsSeenStore();

/// Last time the history was viewed; missed calls after it are "new".
@Riverpod(keepAlive: true)
class MissedCallsSeen extends _$MissedCallsSeen {
  @override
  DateTime? build() {
    final identity = ref.watch(agentCallsProvider.select((s) => s.identity));
    if (identity != null) unawaited(_load(identity));
    return null;
  }

  Future<void> _load(String identity) async {
    final seen = await ref.read(missedCallsSeenStoreProvider).read(identity);
    if (!ref.mounted || seen == null) return;
    if (ref.read(agentCallsProvider).identity != identity) return;
    if (state == null || seen.isAfter(state!)) state = seen;
  }

  /// Clears the badge. The package persists the timestamp and clears the
  /// native missed-call notification.
  Future<void> markViewed() async {
    state = DateTime.now().toUtc();
    await ref.read(supportCallControllerProvider.notifier).markHistoryViewed();
  }
}

/// Missed calls since the history was last viewed, for the Calls badge.
@Riverpod(keepAlive: true)
int missedCallsCount(Ref ref) {
  final calls = ref.watch(agentCallsProvider);
  final seen = ref.watch(missedCallsSeenProvider);
  return calls.history
      .where(
        (call) =>
            supportCallMissedFor(call, calls.identity) &&
            (seen == null || (call.endedAt ?? call.expiresAt).isAfter(seen)),
      )
      .map((call) => call.id)
      .toSet()
      .length;
}
