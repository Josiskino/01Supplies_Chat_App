import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../../config/theme/app_colors.dart';

/// Reusable card widget for settings sections
///
/// Provides consistent styling across all settings pages
class SettingsCard extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsets? margin;

  const SettingsCard({super.key, required this.children, this.margin});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceColorDark : Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: _buildChildrenWithDividers(children)),
    );
  }

  List<Widget> _buildChildrenWithDividers(List<Widget> children) {
    final List<Widget> result = [];
    for (int i = 0; i < children.length; i++) {
      result.add(children[i]);
      if (i < children.length - 1) {
        result.add(
          Divider(
            height: 1,
            thickness: 1,
            color: Colors.grey.withValues(alpha: 0.1),
            indent: 56,
          ),
        );
      }
    }
    return result;
  }
}

/// Reusable settings item widget
///
/// Provides consistent styling for individual settings items
class SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool isDestructive;

  const SettingsItem({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDarkMode
                    ? Colors.grey.withValues(alpha: 0.2)
                    : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isDestructive
                    ? Colors.red
                    : (isDarkMode
                          ? AppColors.textColorDark
                          : AppColors.textColorLight),
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            // Title and subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: isDestructive
                          ? Colors.red
                          : (isDarkMode
                                ? AppColors.textColorDark
                                : AppColors.textColorLight),
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDarkMode
                            ? AppColors.subTextColorDark
                            : AppColors.subTextColorLight,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Trailing widget (arrow, toggle, checkmark, etc.)
            if (trailing != null)
              trailing!
            else
              Icon(
                Iconsax.arrow_right_3,
                color: isDarkMode
                    ? AppColors.subTextColorDark
                    : AppColors.subTextColorLight,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

/// Checkmark trailing widget for selected items
class SettingsCheckmark extends StatelessWidget {
  final bool isSelected;

  const SettingsCheckmark({super.key, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    if (!isSelected) {
      return const SizedBox(width: 24, height: 24);
    }

    return Icon(
      // `tick_circle` et non `tick_circle5` : la variante pleine est sur
      // U+0610, une marque combinante arabe, que le shaper décale vers la
      // droite (voir `nav_destinations.dart`).
      Iconsax.tick_circle,
      color: isDarkMode
          ? AppColors.primaryColorDark
          : AppColors.primaryColorLight,
      size: 24,
    );
  }
}
