import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/apple_type.dart';
import '../../../../config/theme/design_tokens.dart';
import '../../../desktop/widgets/presence_avatar.dart';
import '../../../shared/models/call_view_data.dart';

/// Un participant : avatar, pastille de micro, identifiant en dessous.
class CallParticipantTile extends StatelessWidget {
  const CallParticipantTile({
    super.key,
    required this.participant,
    this.size = 64,
  });

  final CallParticipantData participant;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              _AvatarRing(
                participant: participant,
                size: size,
                accent: theme.colorScheme.primary,
                secondary: theme.colorScheme.secondary,
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: _MicBadge(isMuted: participant.isMuted),
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
