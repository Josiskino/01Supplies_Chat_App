import 'package:flutter/material.dart';

/// Reusable GestureDetector widget with common gesture handlers.
/// Provides a convenient way to handle taps, long presses, and other gestures.
///
/// This widget follows the Composition over Inheritance pattern:
/// - Wraps any widget with gesture detection
/// - Receives callbacks via Dependency Injection pattern
class GestureDetectorWidget extends StatelessWidget {
  /// The child widget to wrap with gesture detection
  final Widget child;

  /// Callback when tapped
  final VoidCallback? onTap;

  /// Callback when long pressed
  final VoidCallback? onLongPress;

  /// Callback when double tapped
  final VoidCallback? onDoubleTap;

  /// Callback when tap is cancelled
  final VoidCallback? onTapCancel;

  /// Behavior for tap gestures
  final HitTestBehavior? behavior;

  /// Whether to exclude this widget from semantics
  final bool excludeFromSemantics;

  const GestureDetectorWidget({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.onDoubleTap,
    this.onTapCancel,
    this.behavior,
    this.excludeFromSemantics = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      onDoubleTap: onDoubleTap,
      onTapCancel: onTapCancel,
      behavior: behavior ?? HitTestBehavior.opaque,
      excludeFromSemantics: excludeFromSemantics,
      child: child,
    );
  }
}

/// InkWell wrapper widget for Material Design ripple effects.
/// Provides tap feedback with Material ripple animation.
class InkWellWidget extends StatelessWidget {
  /// The child widget to wrap with InkWell
  final Widget child;

  /// Callback when tapped
  final VoidCallback? onTap;

  /// Callback when long pressed
  final VoidCallback? onLongPress;

  /// Border radius for the ripple effect
  final BorderRadius? borderRadius;

  /// Custom splash color
  final Color? splashColor;

  /// Custom highlight color
  final Color? highlightColor;

  const InkWellWidget({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.borderRadius,
    this.splashColor,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: borderRadius,
      splashColor: splashColor,
      highlightColor: highlightColor,
      child: child,
    );
  }
}
