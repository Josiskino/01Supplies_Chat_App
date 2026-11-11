import 'dart:math' as math;

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
                                item.badgeCount > 9
                                    ? '9+'
                                    : '${item.badgeCount}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              child: _ActivationBounce(
                                selected: isSelected,
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
                          ),
                          const SizedBox(height: 2),
                          AnimatedDefaultTextStyle(
                            duration: DesignTokens.durationNormal,
                            style:
                                (theme.textTheme.labelSmall ??
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

/// A single playful lift when an Android destination becomes active.
class _ActivationBounce extends StatefulWidget {
  const _ActivationBounce({required this.selected, required this.child});

  final bool selected;
  final Widget child;

  @override
  State<_ActivationBounce> createState() => _ActivationBounceState();
}

class _ActivationBounceState extends State<_ActivationBounce>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: DesignTokens.durationSlow,
    value: 1,
  );

  bool get _canAnimate =>
      Theme.of(context).platform == TargetPlatform.android &&
      !MediaQuery.disableAnimationsOf(context);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_canAnimate) _controller.value = 1;
  }

  @override
  void didUpdateWidget(covariant _ActivationBounce oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected && !oldWidget.selected && _canAnimate) {
      _controller.forward(from: 0);
    } else if (!widget.selected || !_canAnimate) {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    child: widget.child,
    builder: (context, child) {
      final lift = math.sin(_controller.value * math.pi);
      return Transform.translate(
        offset: Offset(0, -3 * lift),
        child: Transform.scale(scale: 1 + 0.16 * lift, child: child),
      );
    },
  );
}
