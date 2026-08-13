import 'package:flutter/material.dart';

/// Barre d'action « annulable » façon SnackBar, mais pilotée par une **jauge de
/// temps** qui se remplit du bord gauche vers le bord droit.
///
/// Sémantique :
/// - Tant que la jauge se remplit, l'utilisateur peut **annuler** ([onUndo]).
/// - Quand la jauge atteint le bord droit, l'action est **validée** ([onCommit])
///   et la barre disparaît en glissant.
///
/// Contrairement au SnackBar natif, elle ne « fige » pas : entrée/sortie animées
/// (slide + fade) et retrait automatique de l'overlay en fin de course.
///
/// Utilisation typique depuis une vue :
/// ```dart
/// UndoActionBar.show(
///   context,
///   message: '${item.name} retiré du panier',
///   onUndo: () => cartNotifier.addItem(...),   // restaure
///   onCommit: () {},                            // suppression définitive
/// );
/// ```
///
/// Les callbacks doivent capturer des références **stables** (un notifier de
/// provider, pas un `WidgetRef` de widget susceptible d'être démonté) : la barre
/// vit dans l'overlay racine et survit donc au démontage de la vue appelante.
class UndoActionBar extends StatefulWidget {
  const UndoActionBar({
    super.key,
    required this.message,
    required this.onCommit,
    required this.onUndo,
    this.actionLabel = 'ANNULER',
    this.duration = const Duration(seconds: 4),
    this.icon = Icons.delete_outline,
    this.accentColor,
    this.onDismissed,
  });

  /// Texte affiché (ex. « X retiré du panier »).
  final String message;

  /// Appelé quand la jauge se remplit entièrement (action confirmée).
  final VoidCallback onCommit;

  /// Appelé quand l'utilisateur tape le bouton d'action (annulation).
  final VoidCallback onUndo;

  /// Libellé du bouton d'action.
  final String actionLabel;

  /// Durée de la jauge (= fenêtre pendant laquelle on peut annuler).
  final Duration duration;

  /// Icône d'en-tête.
  final IconData icon;

  /// Couleur d'accent (jauge + bouton). Défaut : `colorScheme.primary`.
  final Color? accentColor;

  /// Appelé après l'animation de sortie, pour retirer l'overlay.
  final VoidCallback? onDismissed;

  /// Overlay actuellement affiché (une seule barre à la fois).
  static OverlayEntry? _current;

  /// Affiche la barre dans l'overlay racine, ancrée en bas de l'écran.
  ///
  /// Ferme toute barre précédente encore visible. Retourne l'[OverlayEntry] au
  /// cas où l'appelant voudrait la fermer manuellement.
  static OverlayEntry show(
    BuildContext context, {
    required String message,
    required VoidCallback onCommit,
    required VoidCallback onUndo,
    String actionLabel = 'ANNULER',
    Duration duration = const Duration(seconds: 4),
    IconData icon = Icons.delete_outline,
    Color? accentColor,
  }) {
    _current?.remove();
    _current = null;

    final overlay = Overlay.of(context, rootOverlay: true);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => UndoActionBar(
        message: message,
        onCommit: onCommit,
        onUndo: onUndo,
        actionLabel: actionLabel,
        duration: duration,
        icon: icon,
        accentColor: accentColor,
        onDismissed: () {
          if (_current == entry) _current = null;
          entry.remove();
        },
      ),
    );
    _current = entry;
    overlay.insert(entry);
    return entry;
  }

  @override
  State<UndoActionBar> createState() => _UndoActionBarState();
}

class _UndoActionBarState extends State<UndoActionBar>
    with TickerProviderStateMixin {
  /// Contrôle l'entrée/sortie (slide + fade).
  late final AnimationController _enter;

  /// Contrôle le remplissage de la jauge (0 → 1 sur [widget.duration]).
  late final AnimationController _timer;

  late final Animation<Offset> _offset;
  late final Animation<double> _fade;

  /// Empêche une double résolution (commit + undo simultanés).
  bool _resolved = false;

  @override
  void initState() {
    super.initState();

    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _offset = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _enter, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _enter, curve: Curves.easeOut);

    _timer = AnimationController(vsync: this, duration: widget.duration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _finish(commit: true);
        }
      });

    _enter.forward();
    _timer.forward();
  }

  Future<void> _finish({required bool commit}) async {
    if (_resolved) return;
    _resolved = true;
    _timer.stop();

    if (commit) {
      widget.onCommit();
    } else {
      widget.onUndo();
    }

    if (mounted) {
      await _enter.reverse();
    }
    widget.onDismissed?.call();
  }

  @override
  void dispose() {
    _enter.dispose();
    _timer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final media = MediaQuery.of(context);

    final background = isDark ? const Color(0xFF2A2A2E) : Colors.white;
    final foreground = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final accent = widget.accentColor ?? theme.colorScheme.primary;
    final track = accent.withValues(alpha: isDark ? 0.18 : 0.12);

    return Positioned(
      left: 12,
      right: 12,
      bottom: media.padding.bottom + 12,
      child: SlideTransition(
        position: _offset,
        child: FadeTransition(
          opacity: _fade,
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                    child: Row(
                      children: [
                        Icon(widget.icon, color: accent, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.message,
                            style: TextStyle(
                              color: foreground,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () => _finish(commit: false),
                          style: TextButton.styleFrom(
                            foregroundColor: accent,
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                          child: Text(widget.actionLabel),
                        ),
                      ],
                    ),
                  ),
                  // Jauge de temps : se remplit du bord gauche vers le bord
                  // droit ; à 100 % la suppression est validée.
                  AnimatedBuilder(
                    animation: _timer,
                    builder: (_, _) => LinearProgressIndicator(
                      value: _timer.value,
                      minHeight: 5,
                      backgroundColor: track,
                      valueColor: AlwaysStoppedAnimation<Color>(accent),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
