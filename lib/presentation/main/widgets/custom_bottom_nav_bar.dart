import 'package:flutter/material.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/design_tokens.dart';
import 'custom_bottom_nav_bar_item.dart';

/// Barre de navigation basse — plate, bordure discrète, principes iOS / MD3.
///
/// Utilisée en format compact uniquement ; au-delà, [CustomNavRail] prend le
/// relais.
class CustomBottomAppBar extends StatelessWidget {
  const CustomBottomAppBar({
    super.key,
    required this.selectedTab,
    required this.children,
    required this.onTap,
  });

  final int selectedTab;
  final List<CustomBottomAppBarItem> children;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode
            ? AppColors.appBarColorDark
            : AppColors.appBarColorLight,
        border: Border(
          top: BorderSide(
            color: DesignTokens.getBorderColor(isDarkMode, opacity: 0.1),
            width: DesignTokens.borderWidthThin,
          ),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          height: DesignTokens.heightBottomNav,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spaceM,
              vertical: DesignTokens.spaceXs,
            ),
            child: Row(
              children: List.generate(children.length, (index) {
                final item = children[index];
                final isSelected = selectedTab == index;

                return Expanded(
                  child: Semantics(
                    button: true,
                    selected: isSelected,
                    label: item.text,
                    child: GestureDetector(
                      key: item.itemKey,
                      onTap: () => onTap(index),
                      behavior: HitTestBehavior.opaque,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedContainer(
                            duration: DesignTokens.durationNormal,
                            curve: DesignTokens.curveDecelerate,
                            padding: const EdgeInsets.symmetric(
                              horizontal: DesignTokens.spaceXl,
                              vertical: DesignTokens.spaceXs,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? theme.colorScheme.primary.withValues(
                                      alpha: DesignTokens.opacityBackground10,
                                    )
                                  : Colors.transparent,
                              borderRadius: DesignTokens.borderRadiusXl,
                            ),
                            child: Badge(
                              isLabelVisible: item.badgeCount > 0,
                              backgroundColor: Colors.red,
                              textColor: Colors.white,
                              label: Text(
                                item.badgeCount > 9 ? '9+' : '${item.badgeCount}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              child: Icon(
                                isSelected ? item.selectedIcon : item.icon,
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : DesignTokens.getTextColorWithOpacity(
                                        context,
                                        DesignTokens.opacityMedium,
                                      ),
                                size: DesignTokens.iconM,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          AnimatedDefaultTextStyle(
                            duration: DesignTokens.durationNormal,
                            style: (theme.textTheme.labelSmall ??
                                    const TextStyle())
                                .copyWith(
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : DesignTokens.getTextColorWithOpacity(
                                          context,
                                          DesignTokens.opacityHigh,
                                        ),
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  fontSize: 10,
                                ),
                            child: Text(
                              item.text,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
