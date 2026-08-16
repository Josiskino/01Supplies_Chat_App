import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../../config/theme/design_tokens.dart';

/// Expandable Toast Widget
/// Modern toast-style notification with compact and expanded modes
/// Features:
/// - Compact mode: Shows only icon + title + expand button
/// - Expanded mode: Shows icon + title + body + collapse button
/// - Smooth animations for expand/collapse
/// - Theme-responsive design (light/dark)
/// - Swipe to dismiss gesture
/// - Auto-dismiss in compact mode (configurable)
class ExpandableToastWidget extends StatefulWidget {
  final String? title;
  final String? body;
  final String? severity; // 'error', 'warning', 'info', 'success'
  final bool canDismiss;
  final VoidCallback? onDismiss;
  final Duration displayDuration;
  final bool initiallyExpanded;

  const ExpandableToastWidget({
    super.key,
    this.title,
    this.body,
    this.severity,
    this.canDismiss = true,
    this.onDismiss,
    this.displayDuration = const Duration(seconds: 4),
    this.initiallyExpanded = false,
  });

  @override
  State<ExpandableToastWidget> createState() => _ExpandableToastWidgetState();
}

class _ExpandableToastWidgetState extends State<ExpandableToastWidget>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _expandController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _expandAnimation;

  bool _isExpanded = false;
  bool _hasBody = false;

  @override
  void initState() {
    super.initState();

    _hasBody = widget.body != null && widget.body!.isNotEmpty;
    _isExpanded = widget.initiallyExpanded && _hasBody;

    // Slide animation (entrance from top)
    _slideController = AnimationController(
      duration: DesignTokens.durationNormal,
      reverseDuration: DesignTokens.durationFast,
      vsync: this,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, -1.2), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _slideController,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          ),
        );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: Curves.easeOut,
        reverseCurve: Curves.easeIn,
      ),
    );

    // Expand animation (body reveal)
    _expandController = AnimationController(
      duration: DesignTokens.durationNormal,
      vsync: this,
    );

    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    // Start entrance animation
    _slideController.forward();

    // Initialize expanded state
    if (_isExpanded) {
      _expandController.value = 1.0;
    }

    // Auto-dismiss only in compact mode
    if (!_isExpanded) {
      Future.delayed(widget.displayDuration, () {
        if (mounted && widget.canDismiss && !_isExpanded) {
          _dismiss();
        }
      });
    }
  }

  void _toggleExpanded() {
    if (!_hasBody) return;

    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _expandController.forward();
      } else {
        _expandController.reverse();
      }
    });
  }

  void _dismiss() {
    _slideController.reverse().then((_) {
      if (mounted && widget.onDismiss != null) {
        widget.onDismiss!();
      }
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    _expandController.dispose();
    super.dispose();
  }

  Color _getBackgroundColor(BuildContext context) {
    final severity = widget.severity?.toLowerCase() ?? 'info';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return switch (severity) {
      'error' =>
        isDark
            ? Colors.red.shade900.withValues(alpha: 0.95)
            : Colors.red.shade50,
      'warning' =>
        isDark
            ? Colors.orange.shade900.withValues(alpha: 0.95)
            : Colors.orange.shade50,
      'success' =>
        isDark
            ? Colors.green.shade900.withValues(alpha: 0.95)
            : Colors.green.shade50,
      _ =>
        isDark
            ? Colors.blue.shade900.withValues(alpha: 0.95)
            : Colors.blue.shade50,
    };
  }

  Color _getTextColor(BuildContext context) {
    final severity = widget.severity?.toLowerCase() ?? 'info';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return switch (severity) {
      'error' => isDark ? Colors.red.shade100 : Colors.red.shade900,
      'warning' => isDark ? Colors.orange.shade100 : Colors.orange.shade900,
      'success' => isDark ? Colors.green.shade100 : Colors.green.shade900,
      _ => isDark ? Colors.blue.shade100 : Colors.blue.shade900,
    };
  }

  Color _getAccentColor(BuildContext context) {
    final severity = widget.severity?.toLowerCase() ?? 'info';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return switch (severity) {
      'error' => isDark ? Colors.red.shade300 : Colors.red.shade700,
      'warning' => isDark ? Colors.orange.shade300 : Colors.orange.shade700,
      'success' => isDark ? Colors.green.shade300 : Colors.green.shade700,
      _ => isDark ? Colors.blue.shade300 : Colors.blue.shade700,
    };
  }

  IconData _getSeverityIcon() {
    final severity = widget.severity?.toLowerCase() ?? 'info';

    return switch (severity) {
      'error' => Iconsax.danger,
      'warning' => Iconsax.warning_2,
      'success' => Iconsax.tick_circle,
      _ => Iconsax.info_circle,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = _getBackgroundColor(context);
    final textColor = _getTextColor(context);
    final accentColor = _getAccentColor(context);
    final severityIcon = _getSeverityIcon();

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.only(
              left: DesignTokens.spaceL,
              right: DesignTokens.spaceL,
              top: DesignTokens.spaceM,
            ),
            child: Dismissible(
              key: UniqueKey(),
              direction: DismissDirection.horizontal,
              onDismissed: (_) => _dismiss(),
              child: Container(
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: DesignTokens.borderRadiusM,
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.3),
                    width: DesignTokens.borderWidthThin,
                  ),
                  boxShadow: DesignTokens.shadowMedium(
                    Theme.of(context).brightness == Brightness.dark,
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: ClipRRect(
                    borderRadius: DesignTokens.borderRadiusM,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Compact header (always visible)
                        InkWell(
                          onTap: _hasBody ? _toggleExpanded : null,
                          borderRadius: DesignTokens.borderRadiusM,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: DesignTokens.spaceL,
                              vertical: DesignTokens.spaceM,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Severity icon
                                Container(
                                  padding: const EdgeInsets.all(
                                    DesignTokens.spaceXs,
                                  ),
                                  decoration: BoxDecoration(
                                    color: accentColor.withValues(alpha: 0.15),
                                    borderRadius: DesignTokens.borderRadiusS,
                                  ),
                                  child: Icon(
                                    severityIcon,
                                    color: accentColor,
                                    size: DesignTokens.iconS,
                                  ),
                                ),
                                const SizedBox(width: DesignTokens.spaceM),

                                // Title
                                Expanded(
                                  child: Text(
                                    widget.title ?? '',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      color: textColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                    maxLines: _isExpanded ? null : 2,
                                    overflow: _isExpanded
                                        ? null
                                        : TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: DesignTokens.spaceS),

                                // Expand/Collapse button (if body exists)
                                if (_hasBody)
                                  AnimatedRotation(
                                    turns: _isExpanded ? 0.5 : 0.0,
                                    duration: DesignTokens.durationNormal,
                                    child: IconButton(
                                      icon: Icon(
                                        Iconsax.arrow_down_1,
                                        color: accentColor,
                                        size: DesignTokens.iconS,
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: _toggleExpanded,
                                      splashRadius: 20,
                                    ),
                                  ),

                                // Dismiss button
                                if (widget.canDismiss) ...[
                                  const SizedBox(width: DesignTokens.spaceXs),
                                  IconButton(
                                    icon: Icon(
                                      Iconsax.close_circle,
                                      color: textColor.withValues(alpha: 0.6),
                                      size: DesignTokens.iconS,
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: _dismiss,
                                    splashRadius: 20,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),

                        // Expanded body (conditionally visible)
                        if (_hasBody)
                          SizeTransition(
                            sizeFactor: _expandAnimation,
                            // Le corps se déploie vers le bas en restant ancré
                            // en haut. `axisAlignment` est déprécié depuis
                            // Flutter 3.41 au profit d'`alignment`.
                            alignment: Alignment.topCenter,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.only(
                                left: DesignTokens.spaceL,
                                right: DesignTokens.spaceL,
                                bottom: DesignTokens.spaceL,
                              ),
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(
                                    color: accentColor.withValues(alpha: 0.2),
                                    width: DesignTokens.borderWidthThin,
                                  ),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  top: DesignTokens.spaceM,
                                ),
                                child: Text(
                                  widget.body!,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: textColor.withValues(alpha: 0.9),
                                    fontSize: 13,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
