import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../../config/theme/design_tokens.dart';

/// Modern Snackbar Widget
/// Flat design with rounded corners and minimal shadows
///
/// Utility class for showing snackbar messages.
/// Provides convenient methods to display different types of snackbars.
///
/// This follows the Dependency Injection pattern:
/// - Receives message and callbacks as parameters
/// - Doesn't know about business logic
class SnackbarWidget {
  SnackbarWidget._();

  /// Show a success snackbar
  static void showSuccess({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    _showSnackbar(
      context: context,
      message: message,
      backgroundColor: Colors.green,
      // Variante contour : la pleine est sur une marque combinante, décalée
      // au rendu (voir `nav_destinations.dart`).
      icon: Iconsax.tick_circle,
      duration: duration,
      onAction: onAction,
      actionLabel: actionLabel,
    );
  }

  /// Show an error snackbar
  static void showError({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    _showSnackbar(
      context: context,
      message: message,
      backgroundColor: Colors.red,
      icon: Iconsax.danger,
      duration: duration,
      onAction: onAction,
      actionLabel: actionLabel,
    );
  }

  /// Show a warning snackbar
  static void showWarning({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    _showSnackbar(
      context: context,
      message: message,
      backgroundColor: Colors.orange,
      icon: Iconsax.warning_2,
      duration: duration,
      onAction: onAction,
      actionLabel: actionLabel,
    );
  }

  /// Show an info snackbar
  static void showInfo({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    _showSnackbar(
      context: context,
      message: message,
      backgroundColor: Colors.blue,
      icon: Iconsax.info_circle,
      duration: duration,
      onAction: onAction,
      actionLabel: actionLabel,
    );
  }

  /// Show a custom snackbar
  static void showCustom({
    required BuildContext context,
    required String message,
    Color? backgroundColor,
    IconData? icon,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    _showSnackbar(
      context: context,
      message: message,
      backgroundColor: backgroundColor ?? Colors.grey,
      icon: icon,
      duration: duration,
      onAction: onAction,
      actionLabel: actionLabel,
    );
  }

  static void _showSnackbar({
    required BuildContext context,
    required String message,
    required Color backgroundColor,
    IconData? icon,
    required Duration duration,
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: DesignTokens.iconS),
              const SizedBox(width: DesignTokens.spaceS),
            ],
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: duration,
        // Modern rounded corners (flat design)
        shape: RoundedRectangleBorder(borderRadius: DesignTokens.borderRadiusM),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(DesignTokens.spaceL),
        elevation: 2, // Minimal elevation
        action: (onAction != null && actionLabel != null)
            ? SnackBarAction(
                label: actionLabel,
                textColor: Colors.white,
                onPressed: onAction,
              )
            : null,
      ),
    );
  }
}
