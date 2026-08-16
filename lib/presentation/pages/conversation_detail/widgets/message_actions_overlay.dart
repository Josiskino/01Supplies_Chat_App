import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../config/theme/apple_type.dart';
import '../../../../config/theme/design_tokens.dart';
import '../../../../core/platform/platform_ui.dart';
import 'reaction_bar.dart';

/// Panneau ouvert à l'appui long sur une bulle : réactions, aperçu du message,
/// puis actions.
///
/// **Un seul geste, un seul panneau.** Une première version posait la barre de
/// réactions sur un `GestureDetector` par-dessus le menu contextuel natif : les
/// deux réclamaient l'appui long, et le menu gagnait systématiquement. iOS ne
/// superpose jamais deux interactions au même endroit — dans Messages, l'appui
/// long ouvre un panneau unique qui porte les Tapbacks en haut et les actions en
/// dessous. C'est ce que reproduit cet écran.
///
/// L'ensemble est centré verticalement plutôt qu'ancré sur la bulle : une bulle
/// proche du composer laisserait la barre de réactions sous le clavier, et les
/// actions hors écran.
Future<void> showMessageActions({
  required BuildContext context,
  required Widget bubble,
  required List<PlatformMenuAction> actions,
  required ValueChanged<String?> onReact,
  required bool isMine,
  String? selectedReaction,
}) {
  HapticFeedback.mediumImpact();

  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Fermer',
    // Le voile est peint par le flou ci-dessous : un barrier opaque en plus
    // assombrirait deux fois.
    barrierColor: Colors.transparent,
    transitionDuration: DesignTokens.durationNormal,
    pageBuilder: (dialogContext, animation, _) {
      return _ActionsPanel(
        bubble: bubble,
        actions: actions,
        onReact: onReact,
        isMine: isMine,
        selectedReaction: selectedReaction,
      );
    },
    transitionBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeIn,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          // Départ à 0,94 : le panneau « monte » vers le lecteur sans que le
          // mouvement devienne le sujet.
          scale: Tween<double>(begin: 0.94, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class _ActionsPanel extends StatelessWidget {
  const _ActionsPanel({
    required this.bubble,
    required this.actions,
    required this.onReact,
    required this.isMine,
    this.selectedReaction,
  });

  final Widget bubble;
  final List<PlatformMenuAction> actions;
  final ValueChanged<String?> onReact;
  final bool isMine;
  final String? selectedReaction;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Le fond flouté est ce qui isole le message : c'est le procédé du
        // menu contextuel d'iOS, et il rend le voile gris inutile.
        Positioned.fill(
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.22),
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ),
        SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.spaceL,
                vertical: DesignTokens.spaceXxl,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: isMine
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  ReactionBar(
                    selected: selectedReaction,
                    onSelect: (emoji) {
                      Navigator.of(context).pop();
                      onReact(emoji);
                    },
                  ),
                  const SizedBox(height: DesignTokens.spaceM),
                  // La bulle est rendue telle quelle, sans son geste de
                  // glissement : dans le panneau elle n'est plus manipulable,
                  // elle sert de repère.
                  IgnorePointer(child: bubble),
                  const SizedBox(height: DesignTokens.spaceM),
                  _ActionList(actions: actions),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Liste d'actions, à la manière d'un menu contextuel iOS.
class _ActionList extends StatelessWidget {
  const _ActionList({required this.actions});

  final List<PlatformMenuAction> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: DesignTokens.borderRadiusL,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          width: 250,
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF2A2A2E).withValues(alpha: 0.86)
                : Colors.white.withValues(alpha: 0.9),
            borderRadius: DesignTokens.borderRadiusL,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < actions.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: DesignTokens.borderWidthThin,
                    thickness: DesignTokens.borderWidthThin,
                    color: DesignTokens.getBorderColor(isDark, opacity: 0.12),
                  ),
                _ActionTile(action: actions[i]),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.action});

  final PlatformMenuAction action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = action.isDestructive
        ? CupertinoColors.systemRed.resolveFrom(context)
        : DesignTokens.getTextColorWithOpacity(context, 0.95);

    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop();
        action.onPressed();
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spaceL,
          vertical: DesignTokens.spaceM,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                action.label,
                style: theme.textTheme.bodyMedium
                    ?.merge(AppleType.body)
                    .copyWith(color: color),
              ),
            ),
            // L'icône est à droite, comme dans les menus d'iOS — à l'inverse de
            // Material, qui la place en tête de ligne.
            if (action.icon != null)
              Icon(action.icon, size: DesignTokens.iconS, color: color),
          ],
        ),
      ),
    );
  }
}
