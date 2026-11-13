import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:supplies_calls/support.dart';

import '../../../config/theme/apple_type.dart';
import '../../../config/theme/design_tokens.dart';
import '../../../core/calls/agent_calls.dart';
import '../../../core/constants/app_ui_route.dart';
import '../../../core/utils/localization_helper.dart';
import '../../desktop/widgets/presence_avatar.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/platform_page.dart';
import 'call_copy.dart';
import 'widgets/agent_call_widgets.dart';

class CallsScreen extends ConsumerStatefulWidget {
  const CallsScreen({super.key, this.isVisible = true});
  final bool isVisible;
  @override
  ConsumerState<CallsScreen> createState() => _CallsScreenState();
}

class _CallsScreenState extends ConsumerState<CallsScreen>
    with WidgetsBindingObserver {
  bool _markedViewed = false;
  bool _markScheduled = false;
  String? _viewedIdentity;

  bool get _visible =>
      widget.isVisible &&
      (ModalRoute.isCurrentOf(context) ?? true) &&
      (WidgetsBinding.instance.lifecycleState == null ||
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed);

  @override
  void didUpdateWidget(covariant CallsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isVisible) _markedViewed = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _markVisibleHistory(AgentCallsSnapshot calls) {
    if (_viewedIdentity != calls.identity) {
      _viewedIdentity = calls.identity;
      _markedViewed = false;
    }
    if (!_visible) {
      _markedViewed = false;
      return;
    }
    if (_markedViewed || _markScheduled || !calls.historyLoaded) return;
    _markScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markScheduled = false;
      if (!mounted ||
          !_visible ||
          _markedViewed ||
          !ref.read(agentCallsProvider).historyLoaded) {
        return;
      }
      _markedViewed = true;
      unawaited(ref.read(missedCallsSeenProvider.notifier).markViewed());
    });
  }

  bool _missedOnly = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(() {
      if (mounted && ref.read(supportCallsEnabledProvider)) {
        ref.read(supportCallControllerProvider.notifier).refreshHistory();
      }
    });
  }

  Future<void> _callBack(SupportCall call) async {
    if (!await prepareCallMicrophone(context, ref)) return;
    if (!mounted) return;
    final router = GoRouter.of(context);
    unawaited(
      ref.read(agentCallActionsProvider).callback(call.context.conversationId),
    );
    unawaited(router.push(AppUiRoute.call));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationHelper.of(context);
    final enabled = ref.watch(supportCallsEnabledProvider);
    final calls = ref.watch(agentCallsProvider);
    final available = enabled && calls.callsEnabled;
    if (available) _markVisibleHistory(calls);
    final entries =
        calls.history
            .where(
              (call) =>
                  !_missedOnly || supportCallMissedFor(call, calls.identity),
            )
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final canCallBack = !calls.inCall && calls.active?.isActive != true;
    return PlatformPage(
      title: l10n.callsTitle,
      actions: const [],
      body: Column(
        children: [
          if (available) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 8, 24, 8),
              child: AvailabilityToggle(),
            ),
            if (calls.inCall)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: CallsWaitingIndicator(),
              ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: IncomingCallsPanel(),
            ),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: _MissedFilter(
              missedOnly: _missedOnly,
              onChanged: (value) => setState(() => _missedOnly = value),
            ),
          ),
          if (calls.error != null && available)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    CallCopy.error(l10n, calls.error!),
                    textAlign: TextAlign.center,
                  ),
                  if (calls.error == 'microphone_permission')
                    TextButton.icon(
                      onPressed: () => ref
                          .read(agentCallActionsProvider)
                          .requestMicrophone(),
                      icon: const Icon(Icons.mic),
                      label: Text(l10n.callsAllowMicrophone),
                    ),
                ],
              ),
            ),
          Expanded(
            child: !available
                ? EmptyStateWidget(
                    icon: Iconsax.call,
                    title: l10n.callsUnavailableTitle,
                    message: enabled
                        ? l10n.callErrorDisabled
                        : l10n.callsUnavailableMessage,
                  )
                : RefreshIndicator(
                    onRefresh: () => ref
                        .read(supportCallControllerProvider.notifier)
                        .refreshHistory(),
                    child: entries.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              EmptyStateWidget(
                                icon: Iconsax.call,
                                title: _missedOnly
                                    ? l10n.callsMissedEmptyTitle
                                    : l10n.callsEmptyTitle,
                                message: l10n.callsEmptyMessageAgent,
                              ),
                            ],
                          )
                        : ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: entries.length,
                            separatorBuilder: (_, _) =>
                                const Divider(height: 1, indent: 72),
                            itemBuilder: (context, index) {
                              final call = entries[index];
                              return SupportCallHistoryRow(
                                key: ValueKey(call.id),
                                call: call,
                                viewerId: calls.identity,
                                onOpenConversation: () => context.push(
                                  AppUiRoute.conversationDetailPath(
                                    call.context.conversationId,
                                  ),
                                ),
                                onCallback:
                                    canCallBack && _isCustomer(call.caller.role)
                                    ? () => _callBack(call)
                                    : null,
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}

bool _isCustomer(String role) =>
    const {'client', 'customer'}.contains(role.split('.').last);

class SupportCallHistoryRow extends StatelessWidget {
  const SupportCallHistoryRow({
    super.key,
    required this.call,
    this.viewerId,
    this.onOpenConversation,
    this.onCallback,
  });
  final SupportCall call;
  final String? viewerId;
  final VoidCallback? onOpenConversation;

  /// "Rappeler": calls the customer back on the same conversation.
  final VoidCallback? onCallback;

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationHelper.of(context);
    final theme = Theme.of(context);
    final created = call.createdAt.toLocal();
    final time =
        '${created.day.toString().padLeft(2, '0')}/${created.month.toString().padLeft(2, '0')} '
        '${created.hour.toString().padLeft(2, '0')}:${created.minute.toString().padLeft(2, '0')}';
    final missed = supportCallMissedFor(call, viewerId);
    final status = CallCopy.status(l10n, call, viewerId: viewerId);
    final reason = call.isActive
        ? null
        : CallCopy.endReason(l10n, call, viewerId: viewerId);
    final statusLine = [
      call.isCallback ? l10n.callOutgoing(status) : status,
      if (reason != null && reason != status) reason,
    ].join(' · ');
    final answered =
        call.agentName != null &&
        (call.isCallback ||
            call.acceptedAt != null ||
            call.connectedAt != null);
    return ListTile(
      onTap: onOpenConversation,
      leading: PresenceAvatar(
        name: call.caller.name,
        avatarUrl: call.caller.avatarUrl,
        size: 44,
      ),
      title: Text(
        call.caller.name,
        style: TextStyle(color: missed ? theme.colorScheme.error : null),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${CallCopy.role(l10n, call.caller.role)} · ${call.context.reference}',
          ),
          Text(statusLine),
          if (call.connectedAt != null && call.endedAt != null)
            Text(CallCopy.duration(l10n, call.durationAt(call.endedAt!))),
          if (answered)
            Text(
              call.isCallback
                  ? l10n.callStartedBy(call.agentName!)
                  : l10n.callAnsweredBy(call.agentName!),
            ),
        ],
      ),
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(time, style: theme.textTheme.bodySmall),
          if (onCallback != null)
            TextButton.icon(
              key: ValueKey('callback-${call.id}'),
              onPressed: onCallback,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              icon: const Icon(Icons.phone_callback, size: 16),
              label: Text(l10n.callCallback),
            ),
        ],
      ),
      isThreeLine: true,
    );
  }
}

/// "All / Missed" segmented filter: the only sort agents look for in a call
/// history, so it costs a single tap.
class _MissedFilter extends StatelessWidget {
  const _MissedFilter({required this.missedOnly, required this.onChanged});

  final bool missedOnly;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = LocalizationHelper.of(context);

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: DesignTokens.getSubtleBackground(context, opacity: 0.07),
        borderRadius: DesignTokens.borderRadiusS,
      ),
      child: Row(
        children: [
          for (final segment in [
            (false, l10n.callsFilterAll),
            (true, l10n.callsFilterMissed),
          ])
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(segment.$1),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: DesignTokens.durationFast,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: missedOnly == segment.$1
                        ? (isDark ? const Color(0xFF3A3A3F) : Colors.white)
                        : Colors.transparent,
                    borderRadius: DesignTokens.borderRadiusXs,
                    boxShadow: missedOnly == segment.$1
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    segment.$2,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium
                        ?.merge(AppleType.subheadline)
                        .copyWith(
                          fontWeight: missedOnly == segment.$1
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: DesignTokens.getTextColorWithOpacity(
                            context,
                            missedOnly == segment.$1 ? 0.95 : 0.55,
                          ),
                        ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
