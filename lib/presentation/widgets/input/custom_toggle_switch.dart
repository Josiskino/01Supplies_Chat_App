import 'package:flutter/material.dart';
import '../../../config/theme/design_tokens.dart';

/// Modern Toggle Switch Widget
/// Flat design with minimal shadow and smooth animation
class CustomToggleSwitch extends StatelessWidget {
  const CustomToggleSwitch({
    required this.value,
    required this.onChanged,
    super.key,
    this.activeColor,
  });
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? activeColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeColorValue = activeColor ?? theme.colorScheme.primary;
    final isDarkMode = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        width: 36, // Compact iOS-style size
        height: 20,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          borderRadius: DesignTokens.borderRadiusPill,
          color: value
              ? activeColorValue
              : DesignTokens.getBorderColor(isDarkMode, opacity: 0.2),
          // Subtle border for flat design
          border: Border.all(
            color: value
                ? activeColorValue
                : DesignTokens.getBorderColor(isDarkMode, opacity: 0.3),
            width: DesignTokens.borderWidthThin,
          ),
        ),
        child: AnimatedAlign(
          duration: DesignTokens.durationFast,
          curve: DesignTokens.curveEmphasized,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              // Minimal shadow for depth (flat design)
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
