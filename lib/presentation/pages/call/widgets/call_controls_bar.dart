import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../config/theme/apple_type.dart';
import '../../../../config/theme/design_tokens.dart';

/// Réactions rapides envoyées pendant l'appel.
///
/// Une rangée d'emojis toujours visible, sans menu à ouvrir : pendant un appel,
/// les mains sont prises et l'attention est ailleurs. Réagir doit coûter un
/// seul geste.
class CallReactionsBar extends StatelessWidget {
  const CallReactionsBar({
    super.key,
    required this.onReact,
    this.emojis = const ['👏', '👍', '🎉', '💯', '🔥', '😮', '😂'],
  });

  final ValueChanged<String> onReact;
  final List<String> emojis;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spaceS,
        vertical: DesignTokens.spaceS,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: DesignTokens.borderRadiusL,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (final emoji in emojis)
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                onReact(emoji);
              },
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Text(emoji, style: const TextStyle(fontSize: 26)),
              ),
            ),
        ],
      ),
    );
  }
}

/// Barre de contrôles de l'appel.
///
/// Le bouton de raccroché est au centre, plus gros et rouge : c'est la seule
/// action irréversible de l'écran, elle doit être impossible à confondre avec la
/// coupure du micro juste à côté.
class CallControlsBar extends StatelessWidget {
  const CallControlsBar({
    super.key,
    required this.isMuted,
    required this.isCameraOn,
    required this.participantCount,
    required this.onToggleMute,
    required this.onToggleCamera,
    required this.onHangUp,
    required this.onShowParticipants,
    required this.onMore,
  });

  final bool isMuted;
  final bool isCameraOn;
  final int participantCount;
  final VoidCallback onToggleMute;
  final VoidCallback onToggleCamera;
  final VoidCallback onHangUp;
  final VoidCallback onShowParticipants;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ControlButton(
          icon: isCameraOn
              ? CupertinoIcons.video_camera_solid
              : CupertinoIcons.video_camera,
          label: 'Caméra',
          isActive: isCameraOn,
          onTap: onToggleCamera,
        ),
        _ControlButton(
          icon: isMuted ? CupertinoIcons.mic_slash_fill : CupertinoIcons.mic,
          label: isMuted ? 'Activer' : 'Couper',
          isActive: isMuted,
          onTap: onToggleMute,
        ),
        _HangUpButton(onTap: onHangUp),
        _ControlButton(
          icon: CupertinoIcons.person_2_fill,
          label: '$participantCount en ligne',
          onTap: onShowParticipants,
        ),
        _ControlButton(
          icon: CupertinoIcons.ellipsis,
          label: 'Plus',
          onTap: onMore,
        ),
      ],
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// Un contrôle actif s'éclaire : sur fond noir, un état ne se distingue que
  /// par le contraste, jamais par une simple nuance de gris.
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 62,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: DesignTokens.durationFast,
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 22,
                color: isActive ? Colors.black : Colors.white,
              ),
            ),
            const SizedBox(height: DesignTokens.spaceS),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall
                  ?.merge(AppleType.caption2)
                  .copyWith(color: Colors.white.withValues(alpha: 0.75)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bouton de raccroché — le seul geste irréversible de l'écran.
class _HangUpButton extends StatelessWidget {
  const _HangUpButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        HapticFeedback.heavyImpact();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 76,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: CupertinoColors.systemRed,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.phone_down_fill,
                size: 26,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: DesignTokens.spaceS),
            Text(
              'Raccrocher',
              style: theme.textTheme.labelSmall
                  ?.merge(AppleType.caption2)
                  .copyWith(color: Colors.white.withValues(alpha: 0.75)),
            ),
          ],
        ),
      ),
    );
  }
}
