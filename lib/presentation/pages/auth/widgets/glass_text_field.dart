import 'package:flutter/material.dart';

import '../../../../config/theme/design_tokens.dart';

/// Champ de saisie en pilule, posé sur du verre.
///
/// Ne passe pas par `PlatformControls.textField` — et c'est délibéré : ce
/// contrôle-là suit le thème de la plateforme, alors que l'écran de connexion
/// impose sa propre identité, sombre quel que soit le thème de l'appareil. Un
/// champ Material à fond opaque y trouerait la carte de verre.
///
/// Il reste confiné à `pages/auth/` : rien d'autre dans l'app ne doit hériter de
/// cette exception.
class GlassTextField extends StatelessWidget {
  const GlassTextField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.autofillHints,
    this.onIconTap,
    this.textInputAction,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String hint;

  /// Icône affichée **à droite**, comme dans la maquette — à l'inverse de la
  /// convention Material, qui la place en préfixe.
  final IconData icon;

  /// Rend l'icône actionnable (bascule d'affichage du mot de passe). Sans
  /// callback, elle reste un simple repère visuel.
  final VoidCallback? onIconTap;

  final bool obscureText;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    const foreground = Colors.white;

    return Container(
      decoration: BoxDecoration(
        borderRadius: DesignTokens.borderRadiusPill,
        color: Colors.white.withValues(alpha: 0.07),
        border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
      ),
      padding: const EdgeInsets.only(
        left: DesignTokens.spaceXl,
        right: DesignTokens.spaceM,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscureText,
              keyboardType: keyboardType,
              autofillHints: autofillHints,
              textInputAction: textInputAction,
              onSubmitted: onSubmitted,
              style: const TextStyle(
                color: foreground,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              cursorColor: foreground,
              decoration: InputDecoration(
                isDense: true,
                hintText: hint,
                hintStyle: TextStyle(
                  color: foreground.withValues(alpha: 0.65),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          // `IconButton` embarque une zone tactile de 48 px qui ferait grandir la
          // pilule ; le geste est donc porté par un `GestureDetector` neutre.
          GestureDetector(
            onTap: onIconTap,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(DesignTokens.spaceS),
              child: Icon(
                icon,
                size: DesignTokens.iconS,
                color: foreground.withValues(alpha: 0.85),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
