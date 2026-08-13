import 'package:flutter/material.dart';

import '../../../config/theme/design_tokens.dart';
import '../../shared/models/conversation_view_data.dart';

/// Avatar avec pastille de présence.
///
/// Les initiales servent de repli quand aucune image n'est disponible — cas
/// majoritaire dans une messagerie interne, où peu de contacts ont une photo. Un
/// carré gris à leur place rendrait la liste illisible.
class PresenceAvatar extends StatelessWidget {
  const PresenceAvatar({
    super.key,
    required this.name,
    this.avatarUrl,
    this.presence = PresenceStatus.offline,
    this.size = DesignTokens.avatarM,
  });

  final String name;
  final String? avatarUrl;
  final PresenceStatus presence;
  final double size;

  /// Une ou deux initiales, selon ce que le nom fournit.
  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }

  /// Couleur dérivée du nom : stable d'un rendu à l'autre, et deux contacts
  /// voisins dans la liste ont peu de chances de partager la même teinte.
  Color _avatarColor(BuildContext context) {
    const palette = [
      Color(0xFF6F52ED),
      Color(0xFFFF7D28),
      Color(0xFF2E9E6B),
      Color(0xFF3B7DD8),
      Color(0xFFD1487F),
      Color(0xFF9B6BD6),
      Color(0xFFC2871B),
    ];
    return palette[name.hashCode.abs() % palette.length];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _avatarColor(context);
    final dotSize = (size * 0.28).clamp(8.0, 14.0);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: isDark ? 0.28 : 0.16),
              image: avatarUrl != null && avatarUrl!.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(avatarUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            alignment: Alignment.center,
            child: avatarUrl != null && avatarUrl!.isNotEmpty
                ? null
                : Text(
                    _initials,
                    style: TextStyle(
                      color: isDark ? Colors.white : color,
                      fontSize: size * 0.36,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
          if (presence.isVisible)
            Positioned(
              right: -1,
              bottom: -1,
              child: Container(
                width: dotSize,
                height: dotSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: switch (presence) {
                    PresenceStatus.online => const Color(0xFF2ECC71),
                    PresenceStatus.away => const Color(0xFFF5A623),
                    PresenceStatus.offline => Colors.transparent,
                  },
                  // Le liseré reprend la couleur du fond de la carte : c'est ce
                  // qui détache la pastille de l'avatar sans ajouter d'ombre.
                  border: Border.all(
                    color: Theme.of(context).colorScheme.surface,
                    width: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Badge numérique ou textuel de la colonne de navigation.
class WorkspaceBadge extends StatelessWidget {
  const WorkspaceBadge({super.key, this.count = 0, this.label});

  final int count;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTextBadge = label != null && label!.isNotEmpty;

    if (!isTextBadge && count <= 0) return const SizedBox.shrink();

    // Un badge textuel signale une nouveauté (accent), un compteur signale une
    // charge de travail (neutre) : deux couleurs, deux significations.
    final background = isTextBadge
        ? theme.colorScheme.primary
        : theme.colorScheme.primary.withValues(
            alpha: DesignTokens.opacityBackground15,
          );
    final foreground = isTextBadge
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: DesignTokens.borderRadiusPill,
      ),
      child: Text(
        isTextBadge ? label! : (count > 99 ? '99+' : '$count'),
        style: theme.textTheme.labelSmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }
}
