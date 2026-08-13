import 'package:flutter/material.dart';

import '../../../config/theme/design_tokens.dart';
import '../../../presentation/main/widgets/custom_bottom_nav_bar.dart';
import '../../../presentation/main/widgets/custom_bottom_nav_bar_item.dart';
import '../../../presentation/main/widgets/custom_nav_rail.dart';
import '../app_platform.dart';
import '../platform_ui.dart';

/// Rendu Material, cible Android.
///
/// Sert aussi de base à `DesktopPlatformUi`, qui n'en surcharge que ce qui
/// diverge réellement.
class MaterialPlatformUi implements PlatformUi {
  const MaterialPlatformUi();

  @override
  AppPlatform get platform => AppPlatform.android;

  @override
  PlatformShell get shell => const MaterialShell();

  @override
  PlatformControls get controls => const MaterialControls();

  @override
  PlatformOverlays get overlays => const MaterialOverlays();

  @override
  PlatformMotion get motion => const MaterialMotion();
}

class MaterialShell implements PlatformShell {
  const MaterialShell();

  @override
  Widget buildShell({
    Key? key,
    required PlatformLayout layout,
    required Widget body,
    required List<PlatformDestination> destinations,
    required int selectedIndex,
    required ValueChanged<int> onSelected,
    Color? backgroundColor,
  }) {
    final items = destinations.map(toBarItem).toList();

    if (layout.usesLateralNavigation) {
      return Scaffold(
        key: key,
        backgroundColor: backgroundColor,
        body: Row(
          children: [
            CustomNavRail(
              selectedTab: selectedIndex,
              children: items,
              onTap: onSelected,
              extended: layout.isExpanded,
            ),
            Expanded(child: body),
          ],
        ),
      );
    }

    return Scaffold(
      key: key,
      backgroundColor: backgroundColor,
      body: body,
      bottomNavigationBar: CustomBottomAppBar(
        selectedTab: selectedIndex,
        children: items,
        onTap: onSelected,
      ),
    );
  }

  @override
  Widget buildPage({
    Key? key,
    required String title,
    required Widget body,
    List<PlatformAction> actions = const [],
    Color? backgroundColor,
  }) {
    return Scaffold(
      key: key,
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(title),
        actions: [
          for (final action in actions)
            IconButton(
              icon: Icon(action.icon),
              tooltip: action.label,
              onPressed: action.onPressed,
            ),
        ],
      ),
      body: body,
    );
  }

  /// Protégé pour que l'implémentation desktop réutilise la conversion.
  @protected
  CustomBottomAppBarItem toBarItem(PlatformDestination d) {
    return CustomBottomAppBarItem(
      icon: d.icon,
      selectedIcon: d.selectedIcon,
      text: d.label,
      badgeCount: d.badgeCount,
      itemKey: d.key,
    );
  }
}

class MaterialControls implements PlatformControls {
  const MaterialControls();

  @override
  Widget switchToggle({
    Key? key,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return Switch(key: key, value: value, onChanged: onChanged);
  }

  @override
  Widget textField({
    Key? key,
    TextEditingController? controller,
    String? label,
    String? placeholder,
    Widget? prefixIcon,
    Widget? suffixIcon,
    bool obscureText = false,
    TextInputType? keyboardType,
    Iterable<String>? autofillHints,
    ValueChanged<String>? onSubmitted,
  }) {
    return TextField(
      key: key,
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      autofillHints: autofillHints,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        labelText: label,
        hintText: placeholder,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
      ),
    );
  }

  @override
  Widget primaryButton({
    Key? key,
    required Widget child,
    required VoidCallback? onPressed,
  }) {
    return ElevatedButton(key: key, onPressed: onPressed, child: child);
  }

  @override
  Widget progressIndicator({Key? key, Color? color, double? size}) {
    final indicator = CircularProgressIndicator(
      key: key,
      strokeWidth: 2,
      color: color,
    );
    if (size == null) return indicator;
    return SizedBox(width: size, height: size, child: indicator);
  }
}

class MaterialOverlays implements PlatformOverlays {
  const MaterialOverlays();

  @override
  Future<bool?> confirm({
    required BuildContext context,
    required String title,
    required String message,
    required String confirmLabel,
    required String cancelLabel,
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(cancelLabel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: isDestructive
                ? TextButton.styleFrom(
                    foregroundColor: Theme.of(dialogContext).colorScheme.error,
                  )
                : null,
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  @override
  void notify({
    required BuildContext context,
    required String message,
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: isError ? Colors.redAccent : null,
          margin: const EdgeInsets.all(DesignTokens.spaceL),
        ),
      );
  }
}

class MaterialMotion implements PlatformMotion {
  const MaterialMotion();

  @override
  Duration get pageTransitionDuration => DesignTokens.durationSlow;

  @override
  Widget buildPageTransition({
    required BuildContext context,
    required Animation<double> animation,
    required Animation<double> secondaryAnimation,
    required Widget child,
  }) {
    // Fondu + légère montée : la transition Material canonique.
    final curved = CurvedAnimation(
      parent: animation,
      curve: DesignTokens.curveEmphasized,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}
