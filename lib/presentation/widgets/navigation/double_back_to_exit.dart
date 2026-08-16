import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Intercepte le geste retour : un premier appui prévient, un second quitte.
///
/// À n'utiliser que sur Android. Ailleurs, `SystemNavigator.pop()` ne ferme rien
/// d'utile — sur iOS Apple interdit de quitter par programme, et sur desktop la
/// fermeture passe par la fenêtre. Voir [isSupportedPlatform].
class DoubleBackToExit extends StatefulWidget {
  const DoubleBackToExit({
    super.key,
    required this.child,
    required this.message,
    this.timeout = const Duration(seconds: 2),
    this.onBackBeforeExit,
  });

  /// `true` uniquement là où un geste retour système existe et où quitter
  /// l'application par programme a du sens.
  static bool get isSupportedPlatform => !kIsWeb && Platform.isAndroid;

  final Widget child;
  final String message;
  final Duration timeout;

  /// Appelé avant toute tentative de sortie. Renvoyer `true` signifie que le
  /// retour a été traité (remonter dans la pile d'onglets, fermer un panneau) et
  /// que l'app ne doit pas se fermer.
  final bool Function()? onBackBeforeExit;

  @override
  State<DoubleBackToExit> createState() => _DoubleBackToExitState();
}

class _DoubleBackToExitState extends State<DoubleBackToExit> {
  DateTime? _lastBackPressedAt;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackPressed();
      },
      child: widget.child,
    );
  }

  void _handleBackPressed() {
    final handledByParent = widget.onBackBeforeExit?.call() ?? false;
    if (handledByParent) {
      _lastBackPressedAt = null;
      ScaffoldMessenger.maybeOf(context)?.hideCurrentSnackBar();
      return;
    }

    final now = DateTime.now();
    final lastBackPressedAt = _lastBackPressedAt;
    final shouldExit =
        lastBackPressedAt != null &&
        now.difference(lastBackPressedAt) <= widget.timeout;

    if (shouldExit) {
      SystemNavigator.pop();
      return;
    }

    _lastBackPressedAt = now;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(widget.message),
          behavior: SnackBarBehavior.floating,
          duration: widget.timeout,
        ),
      );
  }
}
