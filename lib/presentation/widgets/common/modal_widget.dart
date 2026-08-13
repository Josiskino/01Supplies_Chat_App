import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme/design_tokens.dart';

/// Modern Modal Widget Utility
/// Flat design with rounded corners and minimal shadows
///
/// Provides convenient methods to display different types of modals
/// following modern design principles.
///
/// This follows the Dependency Injection pattern:
/// - Receives content and callbacks as parameters
/// - Doesn't know about business logic
class ModalWidget {
  ModalWidget._();

  /// Show a simple alert dialog with title and message
  static Future<void> showAlert({
    required BuildContext context,
    required String title,
    required String message,
    String? confirmText,
    VoidCallback? onConfirm,
  }) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: DesignTokens.borderRadiusL),
        title: Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        content: Text(message, style: Theme.of(context).textTheme.bodyMedium),
        actions: [
          TextButton(
            onPressed: () {
              context.pop();
              onConfirm?.call();
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.spaceXl,
                vertical: DesignTokens.spaceM,
              ),
            ),
            child: Text(confirmText ?? 'OK'),
          ),
        ],
      ),
    );
  }

  /// Show a confirmation dialog with confirm and cancel actions
  static Future<bool> showConfirmation({
    required BuildContext context,
    required String title,
    required String message,
    String? confirmText,
    String? cancelText,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: DesignTokens.borderRadiusL),
        title: Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        content: Text(message, style: Theme.of(context).textTheme.bodyMedium),
        actions: [
          TextButton(
            onPressed: () {
              context.pop(false);
              onCancel?.call();
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.spaceXl,
                vertical: DesignTokens.spaceM,
              ),
            ),
            child: Text(cancelText ?? 'Cancel'),
          ),
          FilledButton(
            onPressed: () {
              context.pop(true);
              onConfirm?.call();
            },
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.spaceXl,
                vertical: DesignTokens.spaceM,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: DesignTokens.borderRadiusS,
              ),
            ),
            child: Text(confirmText ?? 'Confirm'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Show a custom dialog with custom content
  static Future<T?> showCustom<T>({
    required BuildContext context,
    required Widget content,
    String? title,
    List<Widget>? actions,
    bool barrierDismissible = true,
  }) async {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: DesignTokens.borderRadiusL),
        title: title != null
            ? Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              )
            : null,
        content: content,
        actions: actions,
      ),
    );
  }

  /// Show a modern bottom sheet modal with handle indicator
  static Future<T?> showBottomSheet<T>({
    required BuildContext context,
    required Widget content,
    String? title,
    bool isDismissible = true,
    bool enableDrag = true,
  }) async {
    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      isScrollControlled: true,
      backgroundColor:
          Colors.transparent, // Transparent to show custom background
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(DesignTokens.radiusXl),
            topRight: Radius.circular(DesignTokens.radiusXl),
          ),
        ),
        padding: EdgeInsets.only(
          left: DesignTokens.spaceXxl,
          right: DesignTokens.spaceXxl,
          top: DesignTokens.spaceM,
          bottom:
              MediaQuery.of(context).viewInsets.bottom + DesignTokens.spaceXxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle indicator (iOS style)
            Center(
              child: Container(
                width: DesignTokens.bottomSheetHandleWidth,
                height: DesignTokens.bottomSheetHandleHeight,
                margin: const EdgeInsets.only(bottom: DesignTokens.spaceL),
                decoration: BoxDecoration(
                  color: DesignTokens.getTextColorWithOpacity(
                    context,
                    DesignTokens.opacityDisabled,
                  ),
                  borderRadius: DesignTokens.borderRadiusPill,
                ),
              ),
            ),

            // Title
            if (title != null) ...[
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: DesignTokens.spaceL),
            ],

            // Content
            content,
          ],
        ),
      ),
    );
  }
}
