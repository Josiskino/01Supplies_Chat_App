import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../../config/theme/design_tokens.dart';

/// Modern Notification Widget
/// Flat design with subtle border, slides in from top
///
/// Widget for displaying animated notification messages
/// Slides in from the top of the screen with a smooth animation
class NotificationWidget extends StatefulWidget {
  final String? title;
  final String? body;
  final String? severity; // 'error', 'warning', 'info', 'success'
  final bool canDismiss;
  final VoidCallback? onDismiss;
  final Duration displayDuration;

  const NotificationWidget({
    super.key,
    this.title,
    this.body,
    this.severity,
    this.canDismiss = true,
    this.onDismiss,
    this.displayDuration = const Duration(seconds: 4),
  });

  @override
  State<NotificationWidget> createState() => _NotificationWidgetState();
}

class _NotificationWidgetState extends State<NotificationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      reverseDuration: const Duration(milliseconds: 250),
      vsync: this,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Curves.easeOut,
            reverseCurve: Curves.easeIn,
          ),
        );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
        reverseCurve: Curves.easeIn,
      ),
    );

    // Start animation
    _controller.forward();

    // Auto-dismiss after displayDuration
    Future.delayed(widget.displayDuration, () {
      if (mounted && widget.canDismiss) {
        _dismiss();
      }
    });
  }

  void _dismiss() {
    _controller.reverse().then((_) {
      if (mounted && widget.onDismiss != null) {
        widget.onDismiss!();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getBackgroundColor(BuildContext context) {
    final severity = widget.severity?.toLowerCase() ?? 'info';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return switch (severity) {
      'error' => isDark ? Colors.red.shade900 : Colors.red.shade50,
      'warning' => isDark ? Colors.orange.shade900 : Colors.orange.shade50,
      'success' => isDark ? Colors.green.shade900 : Colors.green.shade50,
      _ => isDark ? Colors.blue.shade900 : Colors.blue.shade50,
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

  IconData _getIcon() {
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
    final icon = _getIcon();

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spaceL,
              vertical: DesignTokens.spaceS,
            ),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: DesignTokens.borderRadiusM,
              // Subtle border instead of heavy shadow (flat design)
              border: Border.all(
                color: textColor.withValues(alpha: 0.2),
                width: DesignTokens.borderWidthThin,
              ),
              // Minimal shadow for depth
              boxShadow: DesignTokens.shadowLow(
                Theme.of(context).brightness == Brightness.dark,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.all(DesignTokens.spaceL),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, color: textColor, size: DesignTokens.iconM),
                    const SizedBox(width: DesignTokens.spaceM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.title != null &&
                              widget.title!.isNotEmpty) ...[
                            Text(
                              widget.title!,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: textColor,
                                fontWeight: FontWeight.w600, // Modern weight
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: DesignTokens.spaceXs),
                          ],
                          if (widget.body != null && widget.body!.isNotEmpty)
                            Text(
                              widget.body!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: textColor,
                                fontSize: 14,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (widget.canDismiss) ...[
                      const SizedBox(width: DesignTokens.spaceS),
                      IconButton(
                        icon: Icon(
                          Iconsax.close_circle,
                          color: textColor,
                          size: DesignTokens.iconS,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: _dismiss,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
