import 'package:flutter/material.dart';

import '../../config/theme/design_tokens.dart';

class SnackBarHelper {
  SnackBarHelper._();

  static void showCustomSnackBar(
    BuildContext context,
    String message, {
    Color backgroundColor = Colors.redAccent,
    Duration duration = const Duration(seconds: 4),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Padding(
          padding: const EdgeInsets.all(DesignTokens.spaceS),
          child: Text(
            message,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ),
        backgroundColor: backgroundColor,
        duration: duration,
        margin: const EdgeInsets.fromLTRB(20.0, 5.0, 20.0, 20.0),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static void showSuccess(BuildContext context, String message) =>
      showCustomSnackBar(context, message, backgroundColor: Colors.green);

  static void showError(BuildContext context, String message) =>
      showCustomSnackBar(context, message);
}
