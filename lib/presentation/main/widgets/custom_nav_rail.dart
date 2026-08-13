import 'package:flutter/material.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/design_tokens.dart';
import 'custom_bottom_nav_bar_item.dart';

/// Rail de navigation latéral, pour les formats medium et expanded
/// (desktop Windows / macOS, tablette, fenêtre large).
///
/// Volontairement construit à la main plutôt qu'avec `NavigationRail` : la barre
/// du bas et le rail doivent partager exactement les mêmes pastille de sélection,
/// badges et courbes d'animation. Avec le widget Material, l'apparence divergerait
/// à chaque redimensionnement de fenêtre.
class CustomNavRail extends StatelessWidget {
  const CustomNavRail({
    super.key,
    required this.selectedTab,
    required this.children,
    required this.onTap,
    this.extended = false,
    this.header,
    this.footer,
  });

  final int selectedTab;
  final List<CustomBottomAppBarItem> children;
  final ValueChanged<int> onTap;

  /// `true` : libellés à droite de l'icône. `false` : libellés sous l'icône.
  final bool extended;

  final Widget? header;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return AnimatedContainer(
      duration: DesignTokens.durationNormal,
      curve: DesignTokens.curveDecelerate,
      width: extended
          ? DesignTokens.railWidthExtended
          : DesignTokens.railWidth,
      decoration: BoxDecoration(
        color: isDarkMode
            ? AppColors.appBarColorDark
            : AppColors.appBarColorLight,
        // `BorderDirectional` plutôt que `Border` : la séparation doit passer à
        // gauche du rail si l'interface est un jour lue de droite à gauche.
        border: BorderDirectional(
          end: BorderSide(
            color: DesignTokens.getBorderColor(isDarkMode, opacity: 0.1),
            width: DesignTokens.borderWidthThin,
          ),
        ),
      ),
      child: SafeArea(
        right: false,
        child: Column(
          children: [
            if (header != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: DesignTokens.spaceL,
                  horizontal: DesignTokens.spaceM,
                ),
                child: header,
              )
            else
              const SizedBox(height: DesignTokens.spaceL),

            // Le rail défile si la fenêtre est courte : sans cela, les dernières
            // destinations deviendraient inatteignables sur un petit écran en
            // paysage.
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    for (var index = 0; index < children.length; index++)
                      _RailItem(
                        item: children[index],
                        isSelected: selectedTab == index,
                        extended: extended,
                        onTap: () => onTap(index),
                      ),
                  ],
                ),
              ),
            ),

            if (footer != null)
              Padding(
                padding: const EdgeInsets.all(DesignTokens.spaceS),
                child: footer,
              ),
          ],
        ),
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  const _RailItem({
    required this.item,
    required this.isSelected,
    required this.extended,
    required this.onTap,
  });

  final CustomBottomAppBarItem item;
  final bool isSelected;
  final bool extended;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final iconColor = isSelected
        ? theme.colorScheme.primary
        : DesignTokens.getTextColorWithOpacity(
            context,
            DesignTokens.opacityMedium,
          );

    final labelStyle = (theme.textTheme.labelMedium ?? const TextStyle())
        .copyWith(
          color: isSelected
              ? theme.colorScheme.primary
              : DesignTokens.getTextColorWithOpacity(
                  context,
                  DesignTokens.opacityHigh,
                ),
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          fontSize: extended ? 13 : 10,
        );

    final badgedIcon = Badge(
      isLabelVisible: item.badgeCount > 0,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      label: Text(
        item.badgeCount > 9 ? '9+' : '${item.badgeCount}',
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
      ),
      child: Icon(
        isSelected ? item.selectedIcon : item.icon,
        color: iconColor,
        size: DesignTokens.iconM,
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spaceS,
        vertical: DesignTokens.spaceXs,
      ),
      child: Semantics(
        button: true,
        selected: isSelected,
        label: item.text,
        child: Tooltip(
          // Le libellé sous l'icône est tronqué en mode replié : l'infobulle
          // reste le seul moyen de lire la destination complète à la souris.
          message: extended ? '' : item.text,
          waitDuration: const Duration(milliseconds: 500),
          child: Material(
            color: Colors.transparent,
            borderRadius: DesignTokens.borderRadiusM,
            child: InkWell(
              key: item.itemKey,
              onTap: onTap,
              borderRadius: DesignTokens.borderRadiusM,
              child: AnimatedContainer(
                duration: DesignTokens.durationNormal,
                curve: DesignTokens.curveDecelerate,
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.spaceM,
                  vertical: DesignTokens.spaceM,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary.withValues(
                          alpha: DesignTokens.opacityBackground10,
                        )
                      : Colors.transparent,
                  borderRadius: DesignTokens.borderRadiusM,
                ),
                child: extended
                    ? Row(
                        children: [
                          badgedIcon,
                          const SizedBox(width: DesignTokens.spaceM),
                          Expanded(
                            child: Text(
                              item.text,
                              style: labelStyle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          badgedIcon,
                          const SizedBox(height: DesignTokens.spaceXs),
                          Text(
                            item.text,
                            style: labelStyle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
