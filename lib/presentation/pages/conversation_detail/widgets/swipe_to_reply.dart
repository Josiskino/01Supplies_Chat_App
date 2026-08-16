import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Glisser une bulle vers la droite pour y répondre.
///
/// Une flèche se révèle à gauche pendant le geste ; passé le seuil, une
/// vibration confirme que relâcher déclenchera la réponse. En deçà, la bulle
/// revient sans rien faire.
///
/// Le retour est animé par un [AnimatedContainer] et non par un
/// `AnimationController` : chaque bulle porte une clé qui se déplace quand la
/// liste se reconstruit, et un contrôleur déclencherait alors un `setState` sur
/// un élément déjà démonté. L'animation implicite n'a pas ce problème.
class SwipeToReply extends StatefulWidget {
  const SwipeToReply({
    super.key,
    required this.child,
    required this.onReply,
    this.enabled = true,
  });

  final Widget child;
  final VoidCallback onReply;
  final bool enabled;

  @override
  State<SwipeToReply> createState() => _SwipeToReplyState();
}

class _SwipeToReplyState extends State<SwipeToReply> {
  /// Distance à franchir pour armer la réponse.
  static const double _threshold = 56;

  /// Au-delà, la bulle cesse de suivre le doigt : la course a une fin visible,
  /// sinon le geste paraît sans effet une fois le seuil dépassé.
  static const double _maxDrag = 78;

  double _dx = 0;
  bool _dragging = false;
  bool _armed = false;

  void _onUpdate(DragUpdateDetails d) {
    var next = (_dx + d.delta.dx).clamp(0.0, _maxDrag);

    if (!_armed && next >= _threshold) {
      _armed = true;
      // Le même retour haptique que Messages au moment où le geste prend.
      HapticFeedback.mediumImpact();
    } else if (_armed && next < _threshold) {
      _armed = false;
    }
    setState(() => _dx = next);
  }

  void _onEnd(DragEndDetails d) {
    final fire = _armed;
    _armed = false;
    setState(() {
      _dragging = false;
      _dx = 0;
    });
    if (fire) widget.onReply();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    final theme = Theme.of(context);
    final progress = (_dx / _threshold).clamp(0.0, 1.0);

    return GestureDetector(
      // Translucide : la bulle en dessous garde son appui long et ses taps.
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: (_) => _dragging = true,
      onHorizontalDragUpdate: _onUpdate,
      onHorizontalDragEnd: _onEnd,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 14),
            child: Opacity(
              opacity: progress,
              child: Transform.scale(
                // L'icône grandit avec le geste : c'est ce qui signale
                // l'approche du seuil sans avoir à l'expliquer.
                scale: 0.6 + 0.4 * progress,
                child: Icon(
                  CupertinoIcons.arrowshape_turn_up_left_fill,
                  size: 20,
                  color: theme.colorScheme.primary.withValues(
                    alpha: 0.4 + 0.6 * progress,
                  ),
                ),
              ),
            ),
          ),
          AnimatedContainer(
            // Pendant le glissement la bulle colle au doigt ; au relâchement
            // seulement, elle revient en douceur.
            duration: _dragging
                ? Duration.zero
                : const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            transform: Matrix4.translationValues(_dx, 0, 0),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}
