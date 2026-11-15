import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../../config/theme/apple_type.dart';
import '../../../config/theme/design_tokens.dart';
import '../../../core/utils/localization_helper.dart';
import '../../shared/models/conversation_view_data.dart';
import 'conversation_title.dart';
import 'inbox_avatar.dart';

/// Where a conversation row is displayed.
enum InboxDensity {
  /// Phone list: larger avatar, two reserved preview lines.
  mobile,

  /// Desktop workspace column: compact, one preview line, hover and
  /// selection states.
  desktop,
}

/// One conversation of the inbox, shared by the phone list and the desktop
/// workspace column.
///
/// Layout, top to bottom:
/// - name, then the order number in grey, then the time;
/// - the support ownership pill, the preview, then the unread counter.
///
/// Every row of a given density has the same height whatever its content: the
/// preview area is reserved even when the text is short, and the ownership pill
/// sits inline rather than on a line of its own. A realtime refresh that claims
/// a request or shortens a preview therefore never moves the rows below it.
class InboxConversationTile extends StatefulWidget {
  const InboxConversationTile({
    super.key,
    required this.data,
    required this.onTap,
    this.density = InboxDensity.mobile,
    this.isSelected = false,
    this.showChevron = false,
    this.appleTypography = false,
    this.ringColor,
  });

  final ConversationListItemData data;
  final VoidCallback onTap;
  final InboxDensity density;
  final bool isSelected;

  /// iOS list convention: a faint chevron next to the time.
  final bool showChevron;

  /// Uses the iOS type ramp (line heights matching Messages).
  final bool appleTypography;

  /// Background the avatar sits on, for its role badge ring.
  final Color? ringColor;

  @override
  State<InboxConversationTile> createState() => _InboxConversationTileState();
}

class _InboxConversationTileState extends State<InboxConversationTile> {
  bool _hovered = false;

  bool get _isDesktop => widget.density == InboxDensity.desktop;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final data = widget.data;
    final scaler = MediaQuery.textScalerOf(context);
    final hasUnread = data.unreadCount > 0 || data.hasUnread;

    final base = theme.textTheme.bodyMedium ?? const TextStyle();
    final nameStyle = base
        .merge(
          widget.appleTypography
              ? AppleType.headline.copyWith(fontSize: 16, height: 21 / 16)
              : null,
        )
        .copyWith(
          fontSize: _isDesktop ? 13.5 : 16,
          height: _isDesktop ? 18 / 13.5 : 21 / 16,
          fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w600,
          color: theme.colorScheme.onSurface,
          letterSpacing: _isDesktop ? 0 : -0.2,
        );
    final orderStyle = nameStyle.copyWith(
      fontSize: _isDesktop ? 11.5 : 13,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      color: DesignTokens.getTextColorWithOpacity(
        context,
        DesignTokens.inboxMutedOpacity,
      ),
    );
    final previewLineHeight = _isDesktop ? 17.0 : 20.0;
    final previewStyle = base
        .merge(widget.appleTypography ? AppleType.subheadline : null)
        .copyWith(
          fontSize: _isDesktop ? 12.5 : 14.5,
          height: previewLineHeight / (_isDesktop ? 12.5 : 14.5),
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
          color: data.isMissedCall
              ? theme.colorScheme.error
              : DesignTokens.getTextColorWithOpacity(
                  context,
                  hasUnread ? 0.78 : DesignTokens.inboxMutedOpacity,
                ),
        );
    final timeStyle = base.copyWith(
      fontSize: _isDesktop ? 11 : 12.5,
      height: 1.3,
      fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w400,
      letterSpacing: 0,
      fontFeatures: const [FontFeature.tabularFigures()],
      color: hasUnread
          ? theme.colorScheme.primary
          : DesignTokens.getTextColorWithOpacity(
              context,
              DesignTokens.inboxFaintOpacity,
            ),
    );

    final previewLines = _isDesktop ? 1 : 2;
    // Reserved height of the preview area. It also covers the unread
    // counter, which is taller than one desktop preview line: without this,
    // a message arriving on a desktop row would grow it by a pixel and push
    // every row below.
    final previewAreaHeight = math.max(
      scaler.scale(previewLineHeight) * previewLines,
      DesignTokens.inboxUnreadBadge + 1,
    );
    final background = _background(theme, isDark);
    final ring =
        widget.ringColor ??
        (_isDesktop
            ? (isDark ? const Color(0xFF221E36) : Colors.white)
            : theme.scaffoldBackgroundColor);

    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        InboxAvatar(
          name: data.name,
          avatarUrl: data.avatarUrl,
          role: data.peerRole,
          size: _isDesktop
              ? DesignTokens.inboxAvatarDesktop
              : DesignTokens.inboxAvatarMobile,
          badgeSize: _isDesktop
              ? DesignTokens.inboxRoleBadgeDesktop
              : DesignTokens.inboxRoleBadgeMobile,
          ringColor: background == Colors.transparent
              ? ring
              : Color.alphaBlend(background, ring),
        ),
        SizedBox(width: _isDesktop ? 10 : DesignTokens.spaceM),
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
                      name: data.name,
                      orderNumber: data.orderNumber,
                      nameStyle: nameStyle,
                      orderStyle: orderStyle,
                      maxOrderShare: 0.5,
                    ),
                  ),
                  const SizedBox(width: DesignTokens.spaceS),
                  Text(data.timeLabel, style: timeStyle, maxLines: 1),
                  if (widget.showChevron) ...[
                    const SizedBox(width: 2),
                    Icon(
                      CupertinoIcons.chevron_right,
                      size: 12,
                      color: DesignTokens.getTextColorWithOpacity(
                        context,
                        0.25,
                      ),
                    ),
                  ],
                ],
              ),
              SizedBox(height: _isDesktop ? 2 : 1),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    // Reserved height: short previews keep the row height.
                    child: SizedBox(
                      height: previewAreaHeight,
                      child: Text.rich(
                        TextSpan(
                          children: [
                            if (data.ticketState != InboxTicketState.none)
                              WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: Padding(
                                  padding: const EdgeInsetsDirectional.only(
                                    end: 6,
                                  ),
                                  child: InboxTicketPill(
                                    state: data.ticketState,
                                    assigneeName: data.assigneeName,
                                    compact: _isDesktop,
                                  ),
                                ),
                              ),
                            if (data.isMissedCall)
                              WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: Padding(
                                  padding: const EdgeInsetsDirectional.only(
                                    end: 4,
                                  ),
                                  child: Icon(
                                    Iconsax.call_slash,
                                    size: _isDesktop ? 12 : 14,
                                    color: theme.colorScheme.error,
                                  ),
                                ),
                              ),
                            TextSpan(text: data.preview),
                          ],
                        ),
                        maxLines: previewLines,
                        overflow: TextOverflow.ellipsis,
                        style: previewStyle,
                      ),
                    ),
                  ),
                  if (data.unreadCount > 0) ...[
                    const SizedBox(width: DesignTokens.spaceS),
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: InboxUnreadBadge(count: data.unreadCount),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );

    if (_isDesktop) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: Semantics(
            selected: widget.isSelected,
            button: true,
            child: GestureDetector(
              onTap: widget.onTap,
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: DesignTokens.durationFast,
                curve: DesignTokens.curveDecelerate,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: content,
              ),
            ),
          ),
        ),
      );
    }

    // Explicit `Material`: `InkWell` needs one to paint, and the row is also
    // shown in overlays (long-press preview) where no Scaffold is around.
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        splashFactory: widget.appleTypography ? NoSplash.splashFactory : null,
        highlightColor: DesignTokens.getTextColorWithOpacity(context, 0.06),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spaceL,
            vertical: DesignTokens.spaceS,
          ),
          child: content,
        ),
      ),
    );
  }

  Color _background(ThemeData theme, bool isDark) {
    if (!_isDesktop) return Colors.transparent;
    if (widget.isSelected) {
      return theme.colorScheme.primary.withValues(alpha: isDark ? 0.24 : 0.12);
    }
    if (_hovered) {
      return DesignTokens.getTextColorWithOpacity(
        context,
        isDark ? 0.06 : 0.045,
      );
    }
    return Colors.transparent;
  }
}

/// Support ownership, shown inline before the preview.
///
/// Unclaimed requests are the only ones tinted with the accent color: they
/// are the ones waiting for someone to act. Requests held by the signed-in
/// agent use the brand color; the others stay neutral.
class InboxTicketPill extends StatelessWidget {
  const InboxTicketPill({
    super.key,
    required this.state,
    this.assigneeName,
    this.compact = false,
  });

  final InboxTicketState state;
  final String? assigneeName;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (state == InboxTicketState.none) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = LocalizationHelper.of(context);
    final name = assigneeName?.trim();

    final (label, semantics, foreground, background, icon) = switch (state) {
      InboxTicketState.unclaimed => (
        l10n.inboxTicketUnclaimed,
        l10n.inboxTicketUnclaimed,
        // Darkened in light mode: the raw accent fails contrast on glass.
        isDark
            ? theme.colorScheme.secondary
            : Color.lerp(theme.colorScheme.secondary, Colors.black, 0.28)!,
        theme.colorScheme.secondary.withValues(alpha: isDark ? 0.18 : 0.12),
        null,
      ),
      InboxTicketState.mine => (
        l10n.inboxTicketMine,
        l10n.inboxTicketAssignedTo(l10n.inboxTicketMine),
        theme.colorScheme.primary,
        theme.colorScheme.primary.withValues(alpha: isDark ? 0.2 : 0.1),
        Iconsax.user_tick,
      ),
      _ => (
        name == null || name.isEmpty ? l10n.inboxTicketAssigned : name,
        name == null || name.isEmpty
            ? l10n.inboxTicketAssigned
            : l10n.inboxTicketAssignedTo(name),
        DesignTokens.getTextColorWithOpacity(context, 0.6),
        DesignTokens.getTextColorWithOpacity(context, isDark ? 0.08 : 0.05),
        Iconsax.user,
      ),
    };
    final fontSize = compact ? 10.5 : 11.5;

    return Semantics(
      label: semantics,
      excludeSemantics: true,
      child: Container(
        constraints: BoxConstraints(maxWidth: compact ? 108 : 132),
        padding: EdgeInsets.symmetric(horizontal: 6, vertical: compact ? 1 : 2),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon == null)
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsetsDirectional.only(end: 4),
                decoration: BoxDecoration(
                  color: foreground,
                  shape: BoxShape.circle,
                ),
              )
            else
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 3),
                child: Icon(icon, size: fontSize + 1, color: foreground),
              ),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: fontSize,
                  height: 1.25,
                  letterSpacing: 0,
                  fontWeight: FontWeight.w600,
                  color: foreground,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Unread counter: a pill whose width follows the digits.
class InboxUnreadBadge extends StatelessWidget {
  const InboxUnreadBadge({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const height = DesignTokens.inboxUnreadBadge;

    return Container(
      height: height,
      constraints: const BoxConstraints(minWidth: height),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: Text(
        // Past 99 the exact number no longer helps decide what to open first.
        count > 99 ? '99+' : '$count',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onPrimary,
          fontSize: 11.5,
          height: 1,
          letterSpacing: 0,
          fontWeight: FontWeight.w700,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
