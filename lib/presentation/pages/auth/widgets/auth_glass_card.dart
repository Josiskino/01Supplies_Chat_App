import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../config/theme/design_tokens.dart';

/// Carte de verre de l'écran de connexion.
///
/// N'utilise pas `GlassPanel` : celui-ci tire ses teintes du thème pour se poser
/// sur le fond de l'app, alors qu'il s'agit ici de laisser transparaître une
/// photographie. Le voile est donc plus sombre et le dégradé orienté, ce qui
/// donne le fondu haut-clair / bas-sombre de la maquette.
class AuthGlassCard extends StatelessWidget {
  const AuthGlassCard({super.key, required this.child});

  final Widget child;

  static final BorderRadius _radius = BorderRadius.circular(28);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      // Clip obligatoire : un `BackdropFilter` non borné flouterait tout l'écran
      // sous lui, pas seulement la carte.
      borderRadius: _radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: _radius,
            border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
            // Le dégradé n'est pas décoratif : il assombrit la carte pour que le
            // texte blanc tienne au-dessus d'un fond très lumineux. Les deux
            // arrêts sont sombres — un départ clair suffisait sur un fond noir,
            // mais il fait disparaître le sous-titre et les bordures des champs
            // dès que l'orange vif passe derrière le haut de la carte.
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.black.withValues(alpha: 0.24),
                Colors.black.withValues(alpha: 0.46),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spaceXxl,
              vertical: DesignTokens.spaceXxxl,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
