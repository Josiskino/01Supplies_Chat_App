import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supplies_calls/support.dart';

import '../../../../core/calls/agent_calls.dart';
import '../../../../core/calls/desktop_call_alerts.dart';
import '../../../../core/constants/app_ui_route.dart';
import '../../../../core/platform/platform_ui_provider.dart';
import '../../../../core/utils/localization_helper.dart';
import '../../../desktop/widgets/presence_avatar.dart';
import '../call_copy.dart';

/// Explains why the microphone is needed before the OS prompt appears.
///
/// Runs on the first availability switch or the first call, never right after
/// login. Returns false when the agent backs out.
Future<bool> prepareCallMicrophone(BuildContext context, WidgetRef ref) async {
  final actions = ref.read(agentCallActionsProvider);
  final granted = await actions.microphoneGranted();
  if (granted != false) return true;
  if (!context.mounted) return false;
  final l10n = LocalizationHelper.of(context);
  final confirmed = await ref
      .read(platformUiProvider)
      .overlays
      .confirm(
        context: context,
        title: l10n.callsMicrophoneDialogTitle,
        message: l10n.callsMicrophoneDialogMessage,
        confirmLabel: l10n.callsMicrophoneDialogContinue,
        cancelLabel: l10n.cancel,
      );
  if (confirmed != true) return false;
  await actions.requestMicrophone();
  return await actions.microphoneGranted() != false;
}

/// Answers the offer the agent tapped, by id, then opens the call screen.
Future<void> acceptIncomingCall(
  BuildContext context,
  WidgetRef ref,
  String callId,
) async {
  if (!await prepareCallMicrophone(context, ref)) return;
  if (!context.mounted) return;
  // The tile disappears as soon as the offer is accepted: keep the router and
  // container rather than the widget's context and ref.
  final router = GoRouter.maybeOf(context);
  final container = ProviderScope.containerOf(context, listen: false);
  await container.read(agentCallActionsProvider).accept(callId);
  final calls = container.read(agentCallsProvider);
  if (router != null &&
      calls.active?.id == callId &&
      calls.active?.isActive == true &&
      router.routerDelegate.currentConfiguration.last.matchedLocation !=
          AppUiRoute.call) {
    unawaited(router.push(AppUiRoute.call));
  }
}

String availabilityLabel(AppLocalizations l10n, String availability) =>
    switch (availability) {
      SupportAgentAvailability.available => l10n.availabilityAvailable,
      SupportAgentAvailability.paused => l10n.availabilityPaused,
      SupportAgentAvailability.busy => l10n.availabilityBusy,
      _ => l10n.availabilityOffline,
    };

Color availabilityColor(ColorScheme scheme, String availability) =>
    switch (availability) {
      SupportAgentAvailability.available => const Color(0xFF2EB872),
      SupportAgentAvailability.paused => const Color(0xFFF5A524),
      SupportAgentAvailability.busy => scheme.error,
      _ => scheme.outline,
    };

/// Disponible / En pause switch. Busy and offline are shown, not chosen:
/// the server derives them from the call and the connection.
class AvailabilityToggle extends ConsumerWidget {
  const AvailabilityToggle({super.key, this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = LocalizationHelper.of(context);
    final theme = Theme.of(context);
    final availability = ref.watch(
      agentCallsProvider.select((s) => s.availability),
    );
    final selectable =
        availability == SupportAgentAvailability.available ||
        availability == SupportAgentAvailability.paused;
    final hint = switch (availability) {
      SupportAgentAvailability.available => l10n.availabilityAvailableHint,
      SupportAgentAvailability.paused => l10n.availabilityPausedHint,
      SupportAgentAvailability.busy => l10n.availabilityBusyHint,
      _ => l10n.availabilityOfflineHint,
    };
    final dot = Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: availabilityColor(theme.colorScheme, availability),
      ),
    );
    return Semantics(
      label: l10n.availabilityLabel,
      child: Row(
        children: [
          dot,
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  availabilityLabel(l10n, availability),
                  key: const ValueKey('availability-label'),
                  style: theme.textTheme.titleSmall,
                ),
                if (!compact)
                  Text(
                    hint,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          Switch.adaptive(
            key: const ValueKey('availability-switch'),
            value: availability == SupportAgentAvailability.available,
            onChanged: selectable
                ? (value) => setAgentAvailability(context, ref, value)
                : null,
          ),
        ],
      ),
    );
  }
}

Future<void> setAgentAvailability(
  BuildContext context,
  WidgetRef ref,
  bool available,
) async {
  if (available && !await prepareCallMicrophone(context, ref)) return;
  await ref
      .read(agentCallActionsProvider)
      .setAvailability(
        available
            ? SupportAgentAvailability.available
            : SupportAgentAvailability.paused,
      );
}

/// Every call currently offered to this agent, oldest first, each with its
/// own Answer / Decline.
class IncomingCallsPanel extends ConsumerStatefulWidget {
  const IncomingCallsPanel({super.key, this.elevated = false, this.router});

  /// Floating overlay style (app-wide) rather than an inline section.
  final bool elevated;

  /// Set when the panel floats above the app's Navigator (calls host): dialogs
  /// and navigation then go through the router's navigator.
  final GoRouter? router;

  @override
  ConsumerState<IncomingCallsPanel> createState() => _IncomingCallsPanelState();
}

class _IncomingCallsPanelState extends ConsumerState<IncomingCallsPanel> {
  Timer? _clock;
  final _pending = <String>{};

  @override
  void initState() {
    super.initState();
    // Refreshes waiting times only.
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  Future<void> _act(String id, Future<void> Function() action) async {
    if (!_pending.add(id)) return;
    setState(() {});
    try {
      await action();
    } finally {
      if (mounted) setState(() => _pending.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final incoming = ref.watch(agentCallsProvider.select((s) => s.incoming));
    if (incoming.isEmpty) return const SizedBox.shrink();
    final l10n = LocalizationHelper.of(context);
    final theme = Theme.of(context);
    final ordered = [...incoming]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final now = DateTime.now().toUtc();
    final muted = ref.watch(desktopRingtoneMutedProvider);
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.incomingCallsTitle(ordered.length),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (ref.watch(desktopCallAlertsProvider) != null)
                IconButton(
                  tooltip: muted
                      ? l10n.callRingtoneUnmute
                      : l10n.callRingtoneMute,
                  onPressed: () =>
                      ref.read(desktopRingtoneMutedProvider.notifier).toggle(),
                  icon: Icon(
                    muted
                        ? Icons.notifications_off
                        : Icons.notifications_active,
                  ),
                ),
            ],
          ),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 320),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.only(bottom: 8),
            children: [
              for (final call in ordered)
                IncomingCallTile(
                  key: ValueKey('incoming-${call.id}'),
                  call: call,
                  waiting: now.difference(call.createdAt.toUtc()),
                  pending: _pending.contains(call.id),
                  onAccept: () => _act(
                    call.id,
                    () => acceptIncomingCall(
                      widget
                              .router
                              ?.routerDelegate
                              .navigatorKey
                              .currentContext ??
                          context,
                      ref,
                      call.id,
                    ),
                  ),
                  onDecline: () => _act(
                    call.id,
                    () => ref.read(agentCallActionsProvider).reject(call.id),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
    if (!widget.elevated) return content;
    return Material(
      color: theme.colorScheme.surfaceContainerHigh,
      elevation: 6,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: content,
    );
  }
}

class IncomingCallTile extends StatelessWidget {
  const IncomingCallTile({
    super.key,
    required this.call,
    required this.waiting,
    required this.onAccept,
    required this.onDecline,
    this.pending = false,
  });
  final SupportCall call;
  final Duration waiting;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final bool pending;

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationHelper.of(context);
    final clamped = waiting.isNegative
        ? Duration.zero
        : waiting > const Duration(minutes: 30)
        ? const Duration(minutes: 30)
        : waiting;
    return ListTile(
      leading: PresenceAvatar(
        name: call.caller.name,
        avatarUrl: call.caller.avatarUrl,
        size: 40,
      ),
      title: Text(
        call.caller.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${CallCopy.role(l10n, call.caller.role)} · ${call.context.reference}\n'
        '${l10n.incomingCallWaiting(CallCopy.duration(l10n, clamped))}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      isThreeLine: true,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton.filled(
            key: ValueKey('decline-${call.id}'),
            tooltip: l10n.incomingCallDecline,
            onPressed: pending ? null : onDecline,
            style: IconButton.styleFrom(backgroundColor: Colors.red),
            icon: const Icon(Icons.call_end, color: Colors.white),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            key: ValueKey('accept-${call.id}'),
            tooltip: l10n.incomingCallAccept,
            onPressed: pending ? null : onAccept,
            style: IconButton.styleFrom(backgroundColor: Colors.green),
            icon: const Icon(Icons.call, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

/// While the agent talks, tells them other customers are waiting (other
/// agents will pick them up).
class CallsWaitingIndicator extends ConsumerWidget {
  const CallsWaitingIndicator({super.key, this.color});
  final Color? color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(agentCallsProvider.select((s) => s.queueLength));
    if (count <= 0) return const SizedBox.shrink();
    final l10n = LocalizationHelper.of(context);
    final theme = Theme.of(context);
    final foreground = color ?? theme.colorScheme.onSecondaryContainer;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.hourglass_bottom, size: 14, color: foreground),
          const SizedBox(width: 4),
          Text(
            l10n.callsWaitingQueue(count),
            style: theme.textTheme.labelMedium?.copyWith(color: foreground),
          ),
        ],
      ),
    );
  }
}
