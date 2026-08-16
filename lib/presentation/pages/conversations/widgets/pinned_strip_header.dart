import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../config/theme/apple_type.dart';
import '../../../../config/theme/design_tokens.dart';
import '../../../desktop/widgets/presence_avatar.dart';
import '../../../shared/models/conversation_view_data.dart';

/// Bande de contacts épinglés, repliable au défilement.
///
/// Déployée, elle montre des pastilles de 64 px espacées, chacune sous son
/// prénom. Au défilement vers le bas, les pastilles rétrécissent, se resserrent
/// jusqu'à se chevaucher, les prénoms s'effacent, et la bande reste accrochée en
/// haut de l'écran sous forme d'une pile compacte. Le retour vers le haut rejoue
/// l'inverse.
///
/// C'est un [SliverPersistentHeader] et non un widget animé par un contrôleur :
/// l'interpolation est pilotée par la **position de défilement**, pas par une
/// durée. Une animation déclenchée par un seuil se désynchroniserait du doigt et
/// resterait figée à mi-course si l'utilisateur s'arrête entre deux états.
class PinnedStripHeader extends SliverPersistentHeaderDelegate {
  const PinnedStripHeader({
    required this.favorites,
    required this.background,
    required this.borderColor,
  });

  final List<WorkspaceFavoriteData> favorites;

  /// Couleur peinte derrière la bande une fois repliée.
  ///
  /// Indispensable : épinglée, la bande recouvre la liste qui continue de
  /// défiler dessous. Sans fond opaque, les lignes de conversation la
  /// traverseraient.
  final Color background;

  final Color borderColor;

  static const double _expandedAvatar = 64;
  static const double _collapsedAvatar = 30;
  static const double _expandedGap = DesignTokens.spaceL;

  /// Écart négatif : c'est lui qui fait la pile.
  static const double _collapsedGap = -11;

  static const double _labelGap = DesignTokens.spaceS;
  static const double _labelHeight = 16;
  static const double _expandedPadding = DesignTokens.spaceL;
  static const double _collapsedPadding = DesignTokens.spaceS;

  /// Largeur d'une colonne déployée, dictée par le prénom.
  static const double _labelWidth = 68;

  @override
  double get maxExtent =>
      _expandedPadding * 2 + _expandedAvatar + _labelGap + _labelHeight;

  @override
  double get minExtent => _collapsedPadding * 2 + _collapsedAvatar;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) {
    final theme = Theme.of(context);
    // Progression du repli, 0 déployé → 1 replié.
    final t = ((shrinkOffset) / (maxExtent - minExtent)).clamp(0.0, 1.0);

    final avatarSize = lerpDouble(_expandedAvatar, _collapsedAvatar, t);
    final gap = lerpDouble(_expandedGap, _collapsedGap, t);
    final padding = lerpDouble(_expandedPadding, _collapsedPadding, t);

    // Les prénoms s'effacent bien avant la fin du repli : maintenus jusqu'au
    // bout, ils se retrouveraient à chevaucher les pastilles voisines dès que
    // l'écart devient négatif.
    final labelOpacity = (1 - t * 2.2).clamp(0.0, 1.0);

    // L'anneau n'apparaît qu'au moment où les pastilles commencent à se
    // recouvrir : c'est ce qui les détache les unes des autres dans la pile.
    final ringWidth = lerpDouble(0, 2, ((t - 0.35) / 0.65).clamp(0.0, 1.0));

    // Déployée, la colonne est plus large que la pastille pour porter le
    // prénom ; repliée, elle se réduit à la pastille, sinon un écart fantôme
    // subsisterait entre les éléments de la pile.
    final itemWidth = labelOpacity > 0
        ? math.max(avatarSize, _labelWidth)
        : avatarSize;
    final step = itemWidth + gap;

    return DecoratedBox(
      decoration: BoxDecoration(
        // Le fond n'apparaît qu'au repli : déployée, la bande doit laisser voir
        // ce que la coquille peint derrière elle.
        color: background.withValues(alpha: t),
        border: Border(
          bottom: BorderSide(
            color: borderColor.withValues(alpha: t * 0.6),
            width: DesignTokens.borderWidthThin,
          ),
        ),
      ),
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.topLeft,
          maxHeight: maxExtent,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: padding),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              // Replié, la pile tient toujours dans la largeur : laisser le
              // défilement actif y donnerait un rebond dans le vide.
              physics: t > 0.9
                  ? const NeverScrollableScrollPhysics()
                  : const BouncingScrollPhysics(),
              clipBehavior: Clip.none,
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.spaceL,
              ),
              // Positionnement explicite plutôt qu'un `Row` : l'empilement
              // demande un écart **négatif**, et Flutter refuse une marge
              // négative (`EdgeInsets` doit être non négatif). Poser chaque
              // pastille à son abscisse permet au pas de devenir plus petit que
              // la pastille elle-même, ce qui est précisément la pile.
              child: SizedBox(
                width: math.max(0, favorites.length * step - gap),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    for (var i = 0; i < favorites.length; i++)
                      Positioned(
                        left: i * step,
                        top: 0,
                        child: _PinnedAvatar(
                          favorite: favorites[i],
                          size: avatarSize,
                          width: itemWidth,
                          ringWidth: ringWidth,
                          ringColor: background,
                          labelOpacity: labelOpacity,
                          labelHeight: lerpDouble(_labelHeight, 0, t),
                          labelGap: lerpDouble(_labelGap, 0, t),
                          theme: theme,
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

  static double lerpDouble(double a, double b, double t) => a + (b - a) * t;

  @override
  bool shouldRebuild(covariant PinnedStripHeader old) =>
      old.favorites != favorites ||
      old.background != background ||
      old.borderColor != borderColor;
}

class _PinnedAvatar extends StatelessWidget {
  const _PinnedAvatar({
    required this.favorite,
    required this.size,
    required this.width,
    required this.ringWidth,
    required this.ringColor,
    required this.labelOpacity,
    required this.labelHeight,
    required this.labelGap,
    required this.theme,
  });

  final WorkspaceFavoriteData favorite;
  final double size;
  final double width;
  final double ringWidth;
  final Color ringColor;
  final double labelOpacity;
  final double labelHeight;
  final double labelGap;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: ringWidth > 0
                  ? Border.all(color: ringColor, width: ringWidth)
                  : null,
            ),
            child: Badge(
              // Le compteur disparaît avec les prénoms : sur une pastille de
              // 30 px prise dans une pile, il déborde sur la voisine.
              isLabelVisible: favorite.badgeCount > 0 && labelOpacity > 0.5,
              backgroundColor: theme.colorScheme.primary,
              textColor: theme.colorScheme.onPrimary,
              label: Text(
                favorite.badgeCount > 9 ? '9+' : '${favorite.badgeCount}',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: PresenceAvatar(
                name: favorite.name,
                avatarUrl: favorite.avatarUrl,
                presence: favorite.presence,
                size: size,
              ),
            ),
          ),
          SizedBox(height: labelGap),
          if (labelHeight > 0)
            SizedBox(
              height: labelHeight,
              child: Opacity(
                opacity: labelOpacity,
                child: Text(
                  // Prénom seul : un nom complet sous une pastille de 64 px se
                  // tronque systématiquement.
                  favorite.name.split(' ').first,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall
                      ?.merge(AppleType.caption1)
                      .copyWith(
                        color: DesignTokens.getTextColorWithOpacity(
                          context,
                          0.7,
                        ),
                      ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
