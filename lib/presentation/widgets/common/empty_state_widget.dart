import 'package:flutter/material.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/design_tokens.dart';

/// Modern Empty State Widget
/// Flat, clean design with generous spacing and subtle colors
class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String message;
  final String? imageAsset;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? actionButton;

  const EmptyStateWidget({
    super.key,
    required this.title,
    required this.message,
    this.imageAsset,
    this.icon,
    this.actionLabel,
    this.onAction,
    this.actionButton,
  }) : assert(
         imageAsset != null || icon != null,
         'Either imageAsset or icon must be provided',
       );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: DesignTokens.pagePaddingLarge,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Image or Icon
            if (imageAsset != null)
              Image.asset(
                imageAsset!,
                width: DesignTokens.iconEmptyLarge,
                height: DesignTokens.iconEmptyLarge,
                fit: BoxFit.contain,
              )
            else
              Container(
                width: DesignTokens.iconEmptyLarge,
                height: DesignTokens.iconEmptyLarge,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary.withValues(alpha: 
                    DesignTokens.opacityBackground20,
                  ),
                ),
                child: Icon(
                  icon,
                  size: DesignTokens.iconXxxl,
                  color: theme.colorScheme.primary.withValues(alpha: 
                    DesignTokens.opacityHigh,
                  ),
                ),
              ),

            const SizedBox(height: DesignTokens.sectionSpacing),

            // Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDarkMode
                    ? AppColors.textColorDark
                    : AppColors.textColorLight,
              ),
            ),

            const SizedBox(height: DesignTokens.contentSpacing),

            // Message
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: DesignTokens.getTextColorWithOpacity(
                  context,
                  DesignTokens.opacityMedium,
                ),
                height: 1.5,
              ),
            ),

            // Action Button
            if (actionButton != null) ...[
              const SizedBox(height: DesignTokens.spaceXxxl),
              actionButton!,
            ] else if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: DesignTokens.spaceXxxl),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.spaceXxl,
                    vertical: DesignTokens.spaceL,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: DesignTokens.borderRadiusM,
                  ),
                  elevation: 0, // Flat design - no elevation
                ),
                child: Text(
                  actionLabel!,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
