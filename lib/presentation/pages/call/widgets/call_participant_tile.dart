import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/apple_type.dart';
import '../../../../config/theme/design_tokens.dart';
import '../../../desktop/widgets/presence_avatar.dart';
import '../../../shared/models/call_view_data.dart';
import 'speaking_aura.dart';

/// Un participant : avatar, pastille de micro, identifiant en dessous.
class CallParticipantTile extends StatelessWidget {
  const CallParticipantTile({
    super.key,
    required this.participant,
    this.size = 64,
    this.isEditing = false,
    this.onRemove,
    this.onLongPress,
  });

  final CallParticipantData participant;
  final double size;

  /// Mode retrait : une pastille « − » apparaît et l'avatar tressaute.
  final bool isEditing;

  final VoidCallback? onRemove;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Le geste enveloppe **toute** la tuile, libellé compris : viser le seul
    // cercle demande une précision que personne n'a en appel.
    return GestureDetector(
      onLongPress: onLongPress,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Le halo est peint **sous** l'avatar et déborde largement de
                // sa boîte : d'où `Clip.none` et le centrage manuel.
                if (participant.isSpeaking)
                  Positioned(
                    left: -size * 0.55,
                    top: -size * 0.55,
                    child: SpeakingAura(
                      size: size,
                      color: participant.isSelf
                          ? theme.colorScheme.primary
                          : CupertinoColors.systemGreen,
                    ),
                  ),
                _Jitter(
                  active: isEditing,
                  child: _AvatarRing(
                    participant: participant,
                    size: size,
                    accent: theme.colorScheme.primary,
                    secondary: theme.colorScheme.secondary,
                  ),
                ),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: _MicBadge(isMuted: participant.isMuted),
                ),
                if (isEditing && !participant.isSelf)
                  Positioned(
                    right: -6,
                    top: -6,
                    child: _RemoveBadge(onTap: onRemove),
                  ),
              ],
            ),
          ),
          const SizedBox(height: DesignTokens.spaceS),
          SizedBox(
            // Largeur bornée : un nom long pousserait sa colonne et désaxerait
            // toute la constellation.
            width: size + 26,
            child: Text(
              participant.isSelf ? 'Vous' : '@${participant.displayHandle}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall
                  ?.merge(AppleType.caption1)
                  .copyWith(
                    color: Colors.white.withValues(
                      alpha: participant.isSelf ? 0.95 : 0.75,
                    ),
                    fontWeight: participant.isSelf
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Avatar entouré de son anneau d'état.
class _AvatarRing extends StatelessWidget {
  const _AvatarRing({
    required this.participant,
    required this.size,
    required this.accent,
    required this.secondary,
  });

  final CallParticipantData participant;
  final double size;
  final Color accent;
  final Color secondary;

  @override
  Widget build(BuildContext context) {
    // Trois états, trois anneaux. L'utilisateur courant porte le dégradé de
    // marque en permanence : c'est le repère qui permet de se retrouver dans la
    // grille sans lire les noms.
    final Gradient? gradient = participant.isSelf
        ? SweepGradient(colors: [accent, secondary, accent])
        : null;

    final Color? solid = participant.isSelf
        ? null
        : participant.isSpeaking
        ? CupertinoColors.systemGreen
        : Colors.white.withValues(alpha: 0.16);

    return AnimatedContainer(
      duration: DesignTokens.durationFast,
      padding: EdgeInsets.all(participant.isSpeaking ? 3 : 2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: gradient,
        color: solid,
      ),
      child: ClipOval(
        child: PresenceAvatar(
          name: participant.name,
          avatarUrl: participant.avatarUrl,
          size: size - (participant.isSpeaking ? 6 : 4),
        ),
      ),
    );
  }
}

/// Pastille de micro, en bas à droite de l'avatar.
class _MicBadge extends StatelessWidget {
  const _MicBadge({required this.isMuted});

  final bool isMuted;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: isMuted
            ? CupertinoColors.systemRed
            : CupertinoColors.systemGreen,
        shape: BoxShape.circle,
        // Anneau sombre : sans lui, la pastille se confond avec l'avatar dès
        // que celui-ci porte une photo claire.
        border: Border.all(color: const Color(0xFF0B0B0D), width: 2),
      ),
      child: Icon(
        isMuted ? CupertinoIcons.mic_slash_fill : CupertinoIcons.mic_fill,
        size: 11,
        color: Colors.white,
      ),
    );
  }
}

/// Emplacement libre : une pastille « + » qui invite à ajouter quelqu'un.
///
/// Montrer la place vide invite plus sûrement qu'un bouton d'ajout relégué dans
/// un menu — c'est le procédé de la maquette, et il se comprend sans libellé.
class CallInviteSlot extends StatelessWidget {
  const CallInviteSlot({super.key, required this.onTap, this.size = 64});

  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              shape: BoxShape.circle,
            ),
            child: Icon(
              CupertinoIcons.plus,
              size: 24,
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: DesignTokens.spaceS),
          Text(
            'Inviter',
            style: theme.textTheme.labelSmall
                ?.merge(AppleType.caption1)
                .copyWith(color: Colors.white.withValues(alpha: 0.55)),
          ),
        ],
      ),
    );
  }
}

/// Tressautement d'un avatar en mode retrait.
///
/// Une rotation de moins d'un degré, alternée : c'est le geste d'iOS quand on
/// entre en réorganisation d'icônes, et il dit « ceci est manipulable » sans
/// aucun libellé. Plus ample, il deviendrait une alerte.
class _Jitter extends StatefulWidget {
  const _Jitter({required this.child, required this.active});

  final Widget child;
  final bool active;

  @override
  State<_Jitter> createState() => _JitterState();
}

class _JitterState extends State<_Jitter> with SingleTickerProviderStateMixin {
  /// Créé dans `initState`, jamais en `late final`.
  ///
  /// Un champ paresseux ne s'initialise qu'au premier accès : quand le
  /// tressautement ne démarre jamais, ce premier accès est `dispose()`, et le
  /// Ticker se crée alors sur un élément déjà retiré de l'arbre. Flutter le
  /// signale par « Looking up a deactivated widget's ancestor is unsafe », très
  /// loin de la cause.
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );
    if (widget.active) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_Jitter old) {
    super.didUpdateWidget(old);
    if (widget.active && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.active && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0.5;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) return widget.child;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Transform.rotate(
        angle: (_controller.value - 0.5) * 0.05,
        child: child,
      ),
      child: widget.child,
    );
  }
}

/// Pastille de retrait, en haut à droite de l'avatar.
class _RemoveBadge extends StatelessWidget {
  const _RemoveBadge({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: CupertinoColors.systemRed,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF0B0B0D), width: 2),
        ),
        child: const Icon(CupertinoIcons.minus, size: 14, color: Colors.white),
      ),
    );
  }
}
