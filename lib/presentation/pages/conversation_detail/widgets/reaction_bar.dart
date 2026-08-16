import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../config/theme/design_tokens.dart';

/// Barre de réactions rapides, présentée au-dessus d'une bulle à l'appui long.
///
/// Six emojis fréquents et un bouton d'ouverture du sélecteur complet. Celui
/// déjà posé par l'utilisateur est mis en évidence, et le toucher le retire —
/// c'est le comportement d'iOS, où la réaction est une bascule et non un ajout.
///
/// Présentation iOS : capsule de verre floutée plutôt qu'un aplat blanc, la même
/// matière que les menus contextuels du système.
class ReactionBar extends StatefulWidget {
  const ReactionBar({
    super.key,
    required this.onSelect,
    this.onMore,
    this.selected,
    this.emojis = const ['👍', '❤️', '😂', '😮', '😢', '🙏'],
  });

  /// Reçoit `null` quand l'utilisateur retire sa réaction.
  final ValueChanged<String?> onSelect;
  final VoidCallback? onMore;

  final String? selected;
  final List<String> emojis;

  @override
  State<ReactionBar> createState() => _ReactionBarState();
}

class _ReactionBarState extends State<ReactionBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  )..forward();

  late final Animation<double> _scale = CurvedAnimation(
    parent: _controller,
    // Un léger dépassement : la barre « arrive » au lieu de simplement
    // apparaître, ce qui la rattache au geste qui l'a ouverte.
    curve: Curves.easeOutBack,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return FadeTransition(
      opacity: _controller,
      child: ScaleTransition(
        scale: _scale,
        // L'échelle part du bas : la barre semble sortir de la bulle.
        alignment: Alignment.bottomCenter,
        child: ClipRRect(
          borderRadius: DesignTokens.borderRadiusPill,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF2A2A2E).withValues(alpha: 0.82)
                    : Colors.white.withValues(alpha: 0.86),
                borderRadius: DesignTokens.borderRadiusPill,
                border: Border.all(
                  color: Colors.white.withValues(alpha: isDark ? 0.12 : 0.5),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final emoji in widget.emojis)
                      _EmojiButton(
                        emoji: emoji,
                        selected: emoji == widget.selected,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          // Retoucher la réaction posée la retire.
                          widget.onSelect(
                            emoji == widget.selected ? null : emoji,
                          );
                        },
                      ),
                    if (widget.onMore != null)
                      GestureDetector(
                        onTap: widget.onMore,
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: DesignTokens.getSubtleBackground(
                              context,
                              opacity: 0.08,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            CupertinoIcons.plus,
                            size: 18,
                            color: DesignTokens.getTextColorWithOpacity(
                              context,
                              0.6,
                            ),
                          ),
                        ),
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

class _EmojiButton extends StatelessWidget {
  const _EmojiButton({
    required this.emoji,
    required this.onTap,
    this.selected = false,
  });

  final String emoji;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: DesignTokens.durationFast,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        // La pastille sélectionnée gagne du padding : l'emoji respire dans son
        // cercle, ce qui rend l'état actif lisible sans changer sa taille.
        padding: selected
            ? const EdgeInsets.all(8)
            : const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
        decoration: selected
            ? BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.20),
                shape: BoxShape.circle,
              )
            : null,
        child: Text(emoji, style: const TextStyle(fontSize: 21)),
      ),
    );
  }
}
