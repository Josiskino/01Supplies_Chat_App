import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:supplies_calls/support.dart';

import '../../../../config/theme/apple_type.dart';
import '../../../../config/theme/design_tokens.dart';
import '../../../../core/utils/localization_helper.dart';
import '../../../../domain/entity/auth/user_role.dart';
import '../../../widgets/inbox/conversation_title.dart';
import '../../../widgets/inbox/inbox_avatar.dart';
import '../call_copy.dart';

/// One call of the history, laid out like an inbox conversation row.
///
/// - avatar with its role badge (the same [InboxAvatar] as the inbox);
/// - name, then the order reference in grey, then the time;
/// - one muted line: direction icon, short status, duration when answered,
///   and the agent who answered or launched the call;
/// - a round call-back button on the trailing edge.
///
/// Missed calls are the only ones painted red, iOS style.
class SupportCallHistoryRow extends StatelessWidget {
  const SupportCallHistoryRow({
    super.key,
    required this.call,
    this.viewerId,
    this.onOpenConversation,
    this.onCallback,
    this.reserveCallbackSlot = false,
    this.appleTypography = false,
    this.now,
  });

  final SupportCall call;
  final String? viewerId;
  final VoidCallback? onOpenConversation;

  /// "Call back": calls the customer back on the same conversation.
  final VoidCallback? onCallback;

  /// Keeps the call-back column even on rows that cannot call back, so the
  /// times of every row stay aligned.
  final bool reserveCallbackSlot;

  /// Uses the iOS type ramp, like the inbox rows on Apple platforms.
  final bool appleTypography;

  /// Clock used for the time column; defaults to now.
  final DateTime? now;

  static const double callbackButtonSize = 40;

  static const Color _answeredColor = Color(0xFF2EB872);

  static UserRole? roleOf(String role) => switch (role.split('.').last) {
    'client' || 'customer' => UserRole.client,
    'driver' || 'delivery' => UserRole.delivery,
    'vendor' => UserRole.vendor,
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationHelper.of(context);
    final theme = Theme.of(context);
    final kind = CallCopy.historyKind(call, viewerId: viewerId);
    final missed = kind == CallHistoryKind.missed;
    final muted = DesignTokens.getTextColorWithOpacity(
      context,
      DesignTokens.inboxMutedOpacity,
    );

    final base = theme.textTheme.bodyMedium ?? const TextStyle();
    final nameStyle = base
        .merge(
          appleTypography
              ? AppleType.headline.copyWith(fontSize: 16, height: 21 / 16)
              : null,
        )
        .copyWith(
          fontSize: 16,
          height: 21 / 16,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
          color: missed ? theme.colorScheme.error : theme.colorScheme.onSurface,
        );
    final referenceStyle = nameStyle.copyWith(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      color: muted,
    );
    final detailStyle = base
        .merge(appleTypography ? AppleType.subheadline : null)
        .copyWith(
          fontSize: 14,
          height: 20 / 14,
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
          color: muted,
        );
    final timeStyle = base.copyWith(
      fontSize: 12.5,
      height: 1.3,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      fontFeatures: const [FontFeature.tabularFigures()],
      color: DesignTokens.getTextColorWithOpacity(
        context,
        DesignTokens.inboxFaintOpacity,
      ),
    );

    final (icon, iconColor) = switch (kind) {
      CallHistoryKind.ongoing => (Icons.phone_in_talk_rounded, _answeredColor),
      CallHistoryKind.incoming => (Icons.call_received_rounded, _answeredColor),
      CallHistoryKind.outgoing => (
        Icons.call_made_rounded,
        theme.colorScheme.primary,
      ),
      CallHistoryKind.missed => (
        Icons.call_missed_rounded,
        theme.colorScheme.error,
      ),
      CallHistoryKind.declined => (
        Icons.call_end_rounded,
        theme.colorScheme.error,
      ),
      CallHistoryKind.noAnswer => (Icons.call_missed_outgoing_rounded, muted),
    };

    final duration = call.connectedAt != null && call.endedAt != null
        ? CallCopy.duration(l10n, call.durationAt(call.endedAt!))
        : null;
    final agent = switch (kind) {
      CallHistoryKind.incoming ||
      CallHistoryKind.outgoing ||
      CallHistoryKind.ongoing ||
      CallHistoryKind.noAnswer => _agentLabel(l10n.callsByYou),
      _ => null,
    };
    final detail = [
      CallCopy.historyLabel(l10n, call, viewerId: viewerId),
      ?duration,
      ?agent,
    ].join(' · ');

    final reference = call.context.reference.trim();
    final role = roleOf(call.caller.role);

    final content = Row(
      children: [
        InboxAvatar(
          name: call.caller.name,
          avatarUrl: call.caller.avatarUrl,
          role: role,
          size: DesignTokens.inboxAvatarMobile,
          badgeSize: DesignTokens.inboxRoleBadgeMobile,
          ringColor: theme.scaffoldBackgroundColor,
        ),
        const SizedBox(width: DesignTokens.spaceM),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(
                    child: ConversationTitle(
                      name: call.caller.name,
                      orderNumber: reference.isEmpty ? null : reference,
                      nameStyle: nameStyle,
                      orderStyle: referenceStyle,
                      // Narrow phones keep more room for the name.
                      maxOrderShare: MediaQuery.sizeOf(context).width < 375
                          ? 0.45
                          : 0.6,
                    ),
                  ),
                  const SizedBox(width: DesignTokens.spaceS),
                  Text(
                    CallCopy.historyTime(l10n, call.createdAt, now: now),
                    key: ValueKey('call-time-${call.id}'),
                    style: timeStyle,
                    maxLines: 1,
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text.rich(
                TextSpan(
                  children: [
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Padding(
                        padding: const EdgeInsetsDirectional.only(end: 4),
                        child: Icon(
                          icon,
                          key: ValueKey('call-kind-${kind.name}'),
                          size: 15,
                          color: iconColor,
                        ),
                      ),
                    ),
                    TextSpan(text: detail),
                  ],
                ),
                key: ValueKey('call-detail-${call.id}'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: detailStyle,
              ),
            ],
          ),
        ),
        if (onCallback != null || reserveCallbackSlot) ...[
          const SizedBox(width: DesignTokens.spaceS),
          SizedBox.square(
            dimension: callbackButtonSize,
            child: onCallback == null
                ? null
                : _CallbackButton(
                    key: ValueKey('callback-${call.id}'),
                    tooltip: l10n.callCallback,
                    onPressed: onCallback!,
                  ),
          ),
        ],
      ],
    );

    // Explicit `Material`: `InkWell` needs one to paint, and the Cupertino
    // shell provides none.
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpenConversation,
        splashFactory: appleTypography ? NoSplash.splashFactory : null,
        highlightColor: DesignTokens.getTextColorWithOpacity(context, 0.06),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            DesignTokens.spaceL,
            DesignTokens.spaceS + 2,
            DesignTokens.spaceM,
            DesignTokens.spaceS + 2,
          ),
          child: content,
        ),
      ),
    );
  }

  /// Agent who answered (incoming) or launched (callback) the call.
  String? _agentLabel(String you) {
    final name = call.agentName?.trim();
    if (viewerId != null && call.agentId == viewerId) return you;
    if (name == null || name.isEmpty) return null;
    return name;
  }
}

/// Round, brand-tinted phone button. The label lives in the tooltip and the
/// semantics, not on screen.
class _CallbackButton extends StatelessWidget {
  const _CallbackButton({
    super.key,
    required this.tooltip,
    required this.onPressed,
  });

  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    return Tooltip(
      message: tooltip,
      excludeFromSemantics: true,
      child: Semantics(
        container: true,
        button: true,
        label: tooltip,
        onTap: onPressed,
        excludeSemantics: true,
        child: Material(
          color: primary.withValues(alpha: isDark ? 0.22 : 0.1),
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: Center(
              child: Icon(CupertinoIcons.phone_fill, size: 18, color: primary),
            ),
          ),
        ),
      ),
    );
  }
}
