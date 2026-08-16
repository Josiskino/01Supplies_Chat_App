import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Shimmer widget with a pulsing heartbeat-like animation
///
/// Creates a shimmer effect that pulses like a heartbeat, perfect for image loading
class PulsingShimmerWidget extends StatefulWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const PulsingShimmerWidget({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  State<PulsingShimmerWidget> createState() => _PulsingShimmerWidgetState();
}

class _PulsingShimmerWidgetState extends State<PulsingShimmerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Create animation controller with heartbeat-like timing
    // Heartbeat pattern: quick pulse, pause, quick pulse, longer pause
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    )..repeat();

    // Create pulse animation with heartbeat curve
    _pulseAnimation = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _getOpacity(),
          child: Shimmer.fromColors(
            baseColor: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
            highlightColor: isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
            period: const Duration(milliseconds: 1500),
            child: Container(
              width: widget.width ?? double.infinity,
              height: widget.height ?? double.infinity,
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[850]! : Colors.grey[400]!,
                borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Calculate opacity based on animation progress to create heartbeat effect
  /// Heartbeat pattern: two quick pulses (lub-dub) followed by a longer pause
  double _getOpacity() {
    final progress = _controller.value;

    // Heartbeat pattern: two quick pulses followed by a pause
    if (progress < 0.12) {
      // First pulse (lub): quick rise
      return 0.5 + (progress / 0.12) * 0.5; // 0.5 to 1.0
    } else if (progress < 0.24) {
      // First pulse: quick fall
      return 1.0 - ((progress - 0.12) / 0.12) * 0.3; // 1.0 to 0.7
    } else if (progress < 0.36) {
      // Second pulse (dub): quick rise
      return 0.7 + ((progress - 0.24) / 0.12) * 0.3; // 0.7 to 1.0
    } else if (progress < 0.48) {
      // Second pulse: quick fall
      return 1.0 - ((progress - 0.36) / 0.12) * 0.3; // 1.0 to 0.7
    } else {
      // Pause: gradual return to base opacity
      final pauseProgress = (progress - 0.48) / 0.52;
      return 0.7 - (pauseProgress * 0.2); // 0.7 to 0.5
    }
  }
}
