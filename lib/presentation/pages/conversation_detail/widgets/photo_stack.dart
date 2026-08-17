import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../config/theme/apple_type.dart';
import '../../../../config/theme/design_tokens.dart';
import '../../../widgets/photo/image_source.dart';

/// Aperçu d'un envoi de plusieurs photos, en éventail.
///
/// ## Pourquoi un éventail et non une grille
///
/// Une mosaïque de vingt-quatre vignettes occuperait tout le fil et donnerait
/// chaque photo trop petite pour être lue. L'éventail dit deux choses à la fois :
/// qu'il s'agit d'un **lot** — les cartes sont visiblement empilées — et combien
/// il en contient, puisque le compte est peint au centre. Le fil garde alors sa
/// hauteur, et le détail se consulte en plein écran.
///
/// ## Ce que porte l'aperçu
///
/// Au plus trois cartes sont dessinées, quel que soit le nombre d'images : la
/// quatrième n'apporterait qu'un bord de plus, déjà illisible sous les autres.
/// C'est le compteur, non la pile, qui porte la quantité — et il annonce le total
/// réel, pas les cartes visibles.
class PhotoStack extends StatelessWidget {
  const PhotoStack({
    super.key,
    required this.images,
    required this.onTap,
    this.height = 190,
  });

  /// Toutes les images du lot, dans l'ordre d'envoi.
  final List<String> images;

  /// Ouvre la visionneuse. L'index de départ est toujours la première image :
  /// on ne peut pas viser une carte précise dans une pile, et prétendre le
  /// contraire ouvrirait au hasard.
  final VoidCallback onTap;

  /// Hauteur de l'aperçu.
  ///
  /// Calée sur ~0,65 de la largeur d'une bulle : au-delà, un envoi de photos
  /// chasse le reste du fil hors de l'écran, et il faut remonter pour retrouver
  /// le message qui l'accompagnait.
  final double height;

  /// Part de la largeur disponible occupée par une carte.
  ///
  /// En dessous de ~0,6 les cartes se chevauchent trop pour qu'on distingue deux
  /// photos ; au-dessus, l'éventail se referme et la pile ressemble à une image
  /// unique mal cadrée.
  static const double _cardWidthRatio = 0.66;

  /// Inclinaison maximale d'une carte, en radians (~3,2°).
  ///
  /// L'œil lit l'empilement dès une très faible rotation ; au-delà de 5° la pile
  /// paraît tombée plutôt que posée, et les coins mordent les bulles voisines.
  static const double _maxTilt = 0.056;

  static const int _maxCards = 3;

  /// Marge réservée au débordement de l'inclinaison.
  ///
  /// Une carte tournée de θ occupe `w·cos θ + h·sin θ` : ses coins sortent donc
  /// de la boîte qu'elle occupait d'aplomb. Sans cette réserve, la carte de
  /// queue mordait le bord de l'écran et son ombre s'y trouvait coupée — un
  /// défaut invisible sur la pile de gauche, systématique sur celle de droite.
  static double _tiltMarginFor(double height) => height * math.sin(_maxTilt);

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) return const SizedBox.shrink();

    final visible = images.length.clamp(1, _maxCards);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          // Une seule photo n'a rien à empiler : elle prend toute la largeur,
          // d'aplomb, comme dans Messages — et n'a donc pas de marge à réserver.
          final margin = visible == 1 ? 0.0 : _tiltMarginFor(height);
          final usableWidth = width - 2 * margin;
          final cardHeight = height - 2 * margin;
          final cardWidth = visible == 1
              ? usableWidth
              : usableWidth * _cardWidthRatio;
          final travel = usableWidth - cardWidth;

          return SizedBox(
            width: width,
            height: height,
            child: Stack(
              children: [
                // Peint de la dernière carte à la première : dans un Stack le
                // dernier enfant est au-dessus, et c'est la photo de tête qui
                // doit couvrir les autres.
                for (var i = visible - 1; i >= 0; i--)
                  Positioned(
                    left:
                        margin +
                        (visible == 1 ? 0 : travel * i / (visible - 1)),
                    top: margin,
                    child: Transform.rotate(
                      angle: visible == 1
                          ? 0
                          : (i - (visible - 1) / 2) * 2 * _maxTilt,
                      child: _PhotoCard(
                        path: images[i],
                        width: cardWidth,
                        height: cardHeight,
                      ),
                    ),
                  ),
                if (images.length > 1)
                  Positioned.fill(
                    child: Center(child: _CountBadge(count: images.length)),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Une photo de la pile, bordée de blanc comme un tirage papier.
///
/// La bordure n'est pas décorative : deux photographies de ville se ressemblent
/// assez pour que leurs bords se fondent l'un dans l'autre, et la pile perdrait
/// alors sa lisibilité d'empilement.
class _PhotoCard extends StatelessWidget {
  const _PhotoCard({
    required this.path,
    required this.width,
    required this.height,
  });

  final String path;
  final double width;
  final double height;

  static const double _border = 4;

  /// Coins d'un tirage photo — plus francs que le rayon des cartes de
  /// l'interface, dont la valeur (8) donnerait des angles presque droits à cette
  /// échelle.
  static const double _radius = 14;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(_border),
      child: ClipRRect(
        // Le rayon intérieur suit l'extérieur moins l'épaisseur du bord, sinon
        // le blanc s'épaissit dans les coins.
        borderRadius: BorderRadius.circular(_radius - _border),
        child: Image(
          image: imageProviderFor(path),
          fit: BoxFit.cover,
          width: width,
          height: height,
          errorBuilder: (context, error, stackTrace) => ColoredBox(
            color: Colors.black.withValues(alpha: 0.08),
            child: const Center(
              child: Icon(Icons.image_not_supported_outlined, size: 22),
            ),
          ),
        ),
      ),
    );
  }
}

/// Compteur posé au centre de l'éventail.
///
/// Il est peint par-dessus les photos et non à côté : le fond gris translucide
/// tient sur n'importe quel cliché, alors qu'un libellé placé sous la pile
/// s'ajouterait à la hauteur du fil pour chaque envoi.
class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spaceM,
        vertical: DesignTokens.spaceS - 2,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count photos',
        style: Theme.of(context).textTheme.bodyMedium
            ?.merge(AppleType.subheadline)
            .copyWith(color: Colors.white, fontWeight: FontWeight.w600),
      ),
    );
  }
}
