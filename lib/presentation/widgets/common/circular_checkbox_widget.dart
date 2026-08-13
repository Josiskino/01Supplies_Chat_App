import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../../config/theme/design_tokens.dart';

/// Modern Circular Checkbox Widget
/// Simple, flat design with subtle animations
///
/// Provides a circular checkbox that follows modern design principles
/// with proper sizing, colors, and interactions.
class CircularCheckboxWidget extends StatelessWidget {
  /// Whether the checkbox is checked
  final bool value;

  /// Callback when checkbox state changes
  final ValueChanged<bool>? onChanged;

  /// Size of the checkbox (default: 20px for modern compact design)
  final double size;

  /// Color when checked
  final Color? activeColor;

  /// Color of the check icon
  final Color? checkColor;

  /// Border color when unchecked
  final Color? borderColor;

  const CircularCheckboxWidget({
    super.key,
    required this.value,
    this.onChanged,
    this.size = 20.0, // Modern compact size
    this.activeColor,
    this.checkColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final activeColorValue = activeColor ?? theme.colorScheme.primary;
    final checkColorValue = checkColor ?? theme.colorScheme.onPrimary;
    final borderColorValue =
        borderColor ?? DesignTokens.getBorderColor(isDarkMode, opacity: 0.3);

    return GestureDetector(
      onTap: onChanged != null ? () => onChanged!(!value) : null,
      child: AnimatedContainer(
        duration: DesignTokens.durationFast,
        curve: DesignTokens.curveDefault,
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: value ? activeColorValue : Colors.transparent,
          border: Border.all(
            color: value ? activeColorValue : borderColorValue,
            width: DesignTokens.borderWidthThick,
          ),
        ),
        child: value
            ? Icon(
                Iconsax.tick_circle, // Icône plus ronde, mieux centrée
                size: size * 0.7, // Légèrement plus grande (70% au lieu de 65%)
                color: checkColorValue,
              )
            : null,
      ),
    );
  }
}
