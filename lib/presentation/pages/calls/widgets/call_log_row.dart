import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/apple_type.dart';
import '../../../../config/theme/design_tokens.dart';
import '../../../desktop/widgets/presence_avatar.dart';
import '../../../shared/models/call_view_data.dart';

/// Une ligne de l'historique des appels.
///
/// Suit la disposition de l'app Téléphone : avatar, nom, puis sous le nom le
/// sens de l'appel. L'heure et un bouton d'information ferment la ligne.
///
/// Un appel manqué met **le nom** en rouge, pas seulement son icône : c'est ce
/// qui permet de repérer les manqués en parcourant la liste du regard, sans
/// avoir à lire chaque ligne.
class CallLogRow extends StatelessWidget {
  const CallLogRow({
    super.key,
    required this.entry,
    required this.onTap,
    required this.onInfo,
  });

  final CallLogEntry entry;
  final VoidCallback onTap;
  final VoidCallback onInfo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nameColor = entry.isMissed
        ? theme.colorScheme.error
        : DesignTokens.getTextColorWithOpacity(context, 0.95);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spaceL,
          vertical: DesignTokens.spaceS + 2,
        ),
        child: Row(
          children: [
            PresenceAvatar(name: entry.name, avatarUrl: entry.avatarUrl, size: 44),
            const SizedBox(width: DesignTokens.spaceM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          entry.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyLarge
                              ?.merge(AppleType.headline)
                              .copyWith(color: nameColor),
                        ),
                      ),
                      // Les tentatives répétées sont regroupées : cinq lignes
                      // identiques n'apprendraient rien de plus qu'un compteur.
                      if (entry.repeatCount > 1)
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Text(
                            '(${entry.repeatCount})',
                            style: theme.textTheme.bodyMedium
                                ?.merge(AppleType.subheadline)
                                .copyWith(color: nameColor),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 1),
                  Row(
                    children: [
                      Icon(
                        _directionIcon,
                        size: 13,
                        color: DesignTokens.getTextColorWithOpacity(
                          context,
                          0.45,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          _subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium
                              ?.merge(AppleType.subheadline)
                              .copyWith(
                                color: DesignTokens.getTextColorWithOpacity(
                                  context,
                                  0.5,
                                ),
                              ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: DesignTokens.spaceS),
            Text(
              entry.timeLabel,
              style: theme.textTheme.bodySmall
                  ?.merge(AppleType.footnote)
                  .copyWith(
                    color: DesignTokens.getTextColorWithOpacity(context, 0.45),
                  ),
            ),
            GestureDetector(
              onTap: onInfo,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.only(left: DesignTokens.spaceS),
                child: Icon(
                  CupertinoIcons.info_circle,
                  size: 22,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData get _directionIcon => switch (entry.direction) {
    CallDirection.incoming => CupertinoIcons.arrow_down_left,
    CallDirection.outgoing => CupertinoIcons.arrow_up_right,
    CallDirection.missed => CupertinoIcons.arrow_down_left,
  };

  /// Sous-titre : nature de l'appel, puis sa durée quand il a eu lieu.
  String get _subtitle {
    final kind = entry.isVideo ? 'Vidéo' : 'Audio';
    return switch (entry.direction) {
      CallDirection.missed => '$kind · manqué',
      _ when entry.durationLabel != null =>
        '$kind · ${entry.durationLabel}',
      _ => kind,
    };
  }
}
