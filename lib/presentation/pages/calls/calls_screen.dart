import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:supplies_calls/support.dart';

import '../../../config/theme/apple_type.dart';
import '../../../config/theme/design_tokens.dart';
import '../../../core/constants/app_ui_route.dart';
import '../../../core/utils/localization_helper.dart';
import '../../desktop/widgets/presence_avatar.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/platform_page.dart';

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

  void _markVisibleHistory(SupportCallState state) {
    if (_viewedIdentity != state.identity) {
      _viewedIdentity = state.identity;
      _markedViewed = false;
    }
    if (!_visible) {
      _markedViewed = false;
      return;
    }
    if (_markedViewed || _markScheduled || !state.historyLoaded) return;
    _markScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markScheduled = false;
      if (!mounted ||
          !_visible ||
          _markedViewed ||
          !ref.read(supportCallControllerProvider).historyLoaded) {
        return;
      }
      _markedViewed = true;
      ref.read(supportCallControllerProvider.notifier).markHistoryViewed();
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

  @override
  Widget build(BuildContext context) {
    final enabled = ref.watch(supportCallsEnabledProvider);
    final state = ref.watch(supportCallControllerProvider);
    if (enabled) _markVisibleHistory(state);
    final entries =
        state.history
            .where((call) => !_missedOnly || supportCallIsMissed(call))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return PlatformPage(
      title: LocalizationHelper.of(context).callsTitle,
      actions: const [],
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: _MissedFilter(
              missedOnly: _missedOnly,
              onChanged: (value) => setState(() => _missedOnly = value),
            ),
          ),
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    state.error == 'microphone_permission'
                        ? 'Autorisez le microphone pour passer et recevoir des appels.'
                        : state.error!,
                  ),
                  if (state.error == 'microphone_permission')
                    TextButton.icon(
                      onPressed: () => ref
                          .read(supportCallControllerProvider.notifier)
                          .prepareMicrophone(),
                      icon: const Icon(Icons.mic),
                      label: const Text('Autoriser le microphone'),
                    ),
                ],
              ),
            ),
          Expanded(
            child: !enabled
                ? const EmptyStateWidget(
                    icon: Iconsax.call,
                    title: 'Appels indisponibles',
                    message: 'Les appels au support ne sont pas activés.',
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
                                    ? 'Aucun appel manqué'
                                    : 'Aucun appel',
                                message:
                                    'Vos appels au support apparaîtront ici.',
                              ),
                            ],
                          )
                        : ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: entries.length,
                            separatorBuilder: (_, _) =>
                                const Divider(height: 1, indent: 72),
                            itemBuilder: (context, index) =>
                                SupportCallHistoryRow(
                                  key: ValueKey(entries[index].id),
                                  call: entries[index],
                                  onOpenConversation: () => context.push(
                                    AppUiRoute.conversationDetailPath(
                                      entries[index].context.conversationId,
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

/// An answered team call is never a missed call for the other agents.
bool supportCallIsMissed(SupportCall call) =>
    call.agentId == null && call.status == SupportCallStatus.expired;

String supportCallStatusLabel(SupportCall call) => switch (call.status) {
  SupportCallStatus.ringing =>
    call.isCallback ? 'Sonnerie' : 'Entrant · sonnerie',
  SupportCallStatus.accepted =>
    call.isCallback ? 'En cours' : 'Entrant · en cours',
  SupportCallStatus.rejected => 'Refusé',
  SupportCallStatus.cancelled => 'Annulé',
  SupportCallStatus.expired =>
    call.isCallback
        ? 'Sans réponse'
        : call.agentId == null
        ? 'Manqué'
        : 'Répondu',
  SupportCallStatus.unavailable => 'Support indisponible',
  SupportCallStatus.ended =>
    call.connectedAt == null || call.isCallback
        ? 'Terminé'
        : 'Entrant · terminé',
};

String supportCallDuration(Duration duration) {
  final seconds = duration.inSeconds;
  final minutes = seconds ~/ 60;
  return minutes == 0 ? '$seconds s' : '$minutes min ${seconds % 60} s';
}

class SupportCallHistoryRow extends StatelessWidget {
  const SupportCallHistoryRow({
    super.key,
    required this.call,
    this.onOpenConversation,
  });
  final SupportCall call;
  final VoidCallback? onOpenConversation;

  @override
  Widget build(BuildContext context) {
    final created = call.createdAt.toLocal();
    final time =
        '${created.day.toString().padLeft(2, '0')}/${created.month.toString().padLeft(2, '0')} '
        '${created.hour.toString().padLeft(2, '0')}:${created.minute.toString().padLeft(2, '0')}';
    final role = switch (call.caller.role.toString().split('.').last) {
      'client' || 'customer' => 'Client',
      'driver' => 'Livreur',
      'vendor' => 'Vendeur',
      _ => call.caller.role.toString().split('.').last,
    };
    return ListTile(
      onTap: onOpenConversation,
      leading: PresenceAvatar(
        name: call.caller.name,
        avatarUrl: call.caller.avatarUrl,
        size: 44,
      ),
      title: Text(
        call.caller.name,
        style: TextStyle(
          color: supportCallIsMissed(call)
              ? Theme.of(context).colorScheme.error
              : null,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$role · ${call.context.reference}'),
          Text(
            '${call.isCallback ? 'Sortant · ' : ''}${supportCallStatusLabel(call)}',
          ),
          if (call.connectedAt != null && call.endedAt != null)
            Text(supportCallDuration(call.durationAt(call.endedAt!))),
          if (call.agentName != null)
            Text(
              '${call.isCallback ? 'Lancé par' : 'Répondu par'} ${call.agentName}',
            ),
        ],
      ),
      trailing: Text(time, style: Theme.of(context).textTheme.bodySmall),
      isThreeLine: true,
    );
  }
}

/// Sélecteur « Tous / Manqués ».
///
/// Deux segments plutôt qu'un menu de filtres : c'est le seul tri que l'on
/// cherche dans un historique d'appels, et il doit coûter un geste.
class _MissedFilter extends StatelessWidget {
  const _MissedFilter({required this.missedOnly, required this.onChanged});

  final bool missedOnly;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: DesignTokens.getSubtleBackground(context, opacity: 0.07),
        borderRadius: DesignTokens.borderRadiusS,
      ),
      child: Row(
        children: [
          for (final segment in [(false, 'Tous'), (true, 'Manqués')])
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
