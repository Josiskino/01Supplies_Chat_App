import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/apple_type.dart';
import '../../../../config/theme/design_tokens.dart';

/// Groupe de réglages : une carte arrondie contenant des lignes séparées.
///
/// C'est la présentation *inset grouped* d'iOS. Le regroupement fait le travail
/// qu'un titre de section ferait autrement : des lignes réunies dans une même
/// carte se lisent comme relevant du même sujet, sans qu'il faille le nommer.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, required this.children, this.header});

  final List<Widget> children;

  /// Intitulé au-dessus de la carte, en petites capitales.
  final String? header;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (header != null)
          Padding(
            padding: const EdgeInsets.only(
              left: DesignTokens.spaceL,
              bottom: DesignTokens.spaceS,
            ),
            child: Text(
              header!.toUpperCase(),
              style: theme.textTheme.labelSmall
                  ?.merge(AppleType.caption1)
                  .copyWith(
                    letterSpacing: 0.5,
                    color: DesignTokens.getTextColorWithOpacity(context, 0.45),
                  ),
            ),
          ),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1F1F22) : Colors.white,
            borderRadius: DesignTokens.borderRadiusL,
          ),
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: DesignTokens.borderWidthThin,
                    thickness: DesignTokens.borderWidthThin,
                    // Séparateur **indenté** : il part sous le texte et non du
                    // bord de la carte. C'est ce décalage qui donne son rythme à
                    // une liste iOS, et qui rattache la ligne à son icône.
                    indent: 52,
                    color: DesignTokens.getBorderColor(isDark, opacity: 0.10),
                  ),
                children[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Une ligne de réglage : icône, intitulé, puis valeur ou contrôle.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.icon,
    required this.title,
    this.value,
    this.trailing,
    this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String title;

  /// Valeur courante, affichée en gris avant le chevron.
  final String? value;

  /// Contrôle à droite — un interrupteur, par exemple. Prend la place du
  /// couple valeur/chevron.
  final Widget? trailing;

  final VoidCallback? onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isDestructive
        ? theme.colorScheme.error
        : DesignTokens.getTextColorWithOpacity(context, 0.95);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spaceL,
          vertical: DesignTokens.spaceM,
        ),
        child: Row(
          children: [
            Icon(icon, size: DesignTokens.iconS, color: color),
            const SizedBox(width: DesignTokens.spaceM),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.bodyMedium
                    ?.merge(AppleType.body)
                    .copyWith(color: color),
              ),
            ),
            if (trailing != null)
              trailing!
            else ...[
              if (value != null)
                Text(
                  value!,
                  style: theme.textTheme.bodyMedium
                      ?.merge(AppleType.body)
                      .copyWith(
                        color: DesignTokens.getTextColorWithOpacity(
                          context,
                          0.4,
                        ),
                      ),
                ),
              if (onTap != null) ...[
                const SizedBox(width: DesignTokens.spaceS),
                Icon(
                  CupertinoIcons.chevron_right,
                  size: 14,
                  color: DesignTokens.getTextColorWithOpacity(context, 0.3),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
