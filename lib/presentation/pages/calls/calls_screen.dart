import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:supplies_calls/support.dart';

import '../../../config/theme/design_tokens.dart';
import '../../../core/calls/agent_calls.dart';
import '../../../core/constants/app_ui_route.dart';
import '../../../core/utils/localization_helper.dart';
import '../../../core/utils/refresh_gate.dart';
import '../../../core/platform/platform_ui_provider.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/platform_page.dart';
import '../../widgets/common/platform_refresh.dart';
import 'call_copy.dart';
import 'widgets/agent_call_widgets.dart';
import 'widgets/call_history_row.dart';

export 'widgets/call_history_row.dart' show SupportCallHistoryRow;

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
  final _refreshGate = RefreshGate();

  /// The controller logs and swallows history failures itself; the list
  /// simply keeps its previous rows.
  Future<void> _refreshHistory() => _refreshGate.run(
    () => ref.read(supportCallControllerProvider.notifier).refreshHistory(),
  );

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
    final isApple = ref.watch(platformUiProvider).platform.isApple;
    return PlatformPage(
      title: l10n.callsTitle,
      actions: const [],
      body: Column(
        children: [
          if (available) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: _AvailabilityCard(),
            ),
            if (calls.inCall)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: CallsWaitingIndicator(),
              ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: IncomingCallsPanel(),
            ),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
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
                : PlatformRefreshScrollView(
                    onRefresh: _refreshHistory,
                    slivers: [
                      if (entries.isEmpty)
                        SliverToBoxAdapter(
                          child: EmptyStateWidget(
                            icon: Iconsax.call,
                            title: _missedOnly
                                ? l10n.callsMissedEmptyTitle
                                : l10n.callsEmptyTitle,
                            message: l10n.callsEmptyMessageAgent,
                          ),
                        )
                      else
                        SliverPadding(
                          // The shell announces its floating tab bar in the
                          // bottom padding: the last row stays reachable.
                          padding: EdgeInsets.only(
                            bottom:
                                MediaQuery.paddingOf(context).bottom +
                                DesignTokens.spaceM,
                          ),
                          sliver: SliverList.separated(
                            itemCount: entries.length,
                            separatorBuilder: (context, _) => Divider(
                              height: DesignTokens.borderWidthThin,
                              thickness: DesignTokens.borderWidthThin,
                              indent:
                                  DesignTokens.spaceL +
                                  DesignTokens.inboxAvatarMobile +
                                  DesignTokens.spaceM,
                              color: DesignTokens.getBorderColor(
                                Theme.of(context).brightness == Brightness.dark,
                                opacity: 0.08,
                              ),
                            ),
                            itemBuilder: (context, index) {
                              final call = entries[index];
                              return SupportCallHistoryRow(
                                key: ValueKey(call.id),
                                call: call,
                                viewerId: calls.identity,
                                appleTypography: isApple,
                                reserveCallbackSlot: canCallBack,
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
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

bool _isCustomer(String role) =>
    const {'client', 'customer'}.contains(role.split('.').last);

/// Availability switch in a compact card, so it reads as a setting and not
/// as the first row of the history.
class _AvailabilityCard extends StatelessWidget {
  const _AvailabilityCard();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(14, 8, 8, 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: DesignTokens.getBorderColor(isDark, opacity: 0.06),
        ),
      ),
      child: const AvailabilityToggle(),
    );
  }
}

/// "All / Missed" filter, styled like the inbox Support / Direct tabs: the
/// only sort agents look for in a call history, so it costs a single tap.
class _MissedFilter extends StatelessWidget {
  const _MissedFilter({required this.missedOnly, required this.onChanged});

  final bool missedOnly;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = LocalizationHelper.of(context);
    final base = theme.textTheme.bodyMedium ?? const TextStyle();
    return SizedBox(
      width: double.infinity,
      child: CupertinoSlidingSegmentedControl<bool>(
        groupValue: missedOnly,
        backgroundColor: theme.brightness == Brightness.dark
            ? theme.colorScheme.surfaceContainerHighest
            : const Color(0xFFECECEC),
        thumbColor: theme.colorScheme.primary,
        padding: const EdgeInsets.all(4),
        onValueChanged: (value) {
          if (value != null) onChanged(value);
        },
        children: {
          for (final segment in [
            (false, l10n.callsFilterAll),
            (true, l10n.callsFilterMissed),
          ])
            segment.$1: Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Text(
                segment.$2,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: base.copyWith(
                  fontSize: 13,
                  height: 1.25,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                  color: segment.$1 == missedOnly
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurface,
                ),
              ),
            ),
        },
      ),
    );
  }
}
