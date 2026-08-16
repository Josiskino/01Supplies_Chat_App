import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../config/theme/apple_type.dart';
import '../../../config/theme/design_tokens.dart';
import '../../../core/platform/platform_ui.dart';
import '../../pages/conversation_detail/widgets/reaction_bar.dart';

/// Panneau ouvert à l'appui long : aperçu de l'élément, puis ses actions.
///
/// Sert au fil de discussion comme à la liste de conversations, avec ou sans
/// barre de réactions selon ce que l'élément accepte.
///
/// **Un seul geste, un seul panneau.** Une première version posait la barre de
/// réactions sur un `GestureDetector` par-dessus le menu contextuel natif : les
/// deux réclamaient l'appui long, et le menu gagnait systématiquement. iOS ne
/// superpose jamais deux interactions au même endroit — dans Messages, l'appui
/// long ouvre un panneau unique qui porte les Tapbacks en haut et les actions en
/// dessous.
///
/// Il remplace aussi `CupertinoContextMenu`, dont l'extraction de l'enfant hors
/// de l'arbre lui fait perdre ses contraintes de largeur et exige des
/// contournements à chaque appelant.
///
/// L'ensemble est centré verticalement plutôt qu'ancré sur l'élément : un
/// élément proche du bas laisserait la barre de réactions sous le clavier, et
/// les actions hors écran.
Future<void> showContextActions({
  required BuildContext context,
  required Widget preview,
  required List<PlatformMenuAction> actions,
  ValueChanged<String?>? onReact,
  bool alignEnd = false,
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
        preview: preview,
        actions: actions,
        onReact: onReact,
        alignEnd: alignEnd,
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
    required this.preview,
    required this.actions,
    required this.alignEnd,
    this.onReact,
    this.selectedReaction,
  });

  final Widget preview;
  final List<PlatformMenuAction> actions;

  /// Sans callback, la barre de réactions n'est pas montée : on ne réagit pas à
  /// une conversation comme on réagit à un message.
  final ValueChanged<String?>? onReact;

  final bool alignEnd;
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
                crossAxisAlignment: alignEnd
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  if (onReact != null) ...[
                    ReactionBar(
                      selected: selectedReaction,
                      onSelect: (emoji) {
                        Navigator.of(context).pop();
                        onReact!(emoji);
                      },
                    ),
                    const SizedBox(height: DesignTokens.spaceM),
                  ],
                  // L'aperçu est rendu tel quel, sans ses gestes : dans le
                  // panneau il n'est plus manipulable, il sert de repère.
                  IgnorePointer(child: preview),
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
