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
/// ## Deux dispositions, selon l'ampleur du lot
///
/// Jusqu'à cinq images, les cartes s'échelonnent de gauche à droite : chacune
/// reste assez découverte pour qu'on devine ce qu'elle montre, et l'escalier
/// suffit à dire qu'il y en a plusieurs.
///
/// Au-delà, cet échelonnement mentirait — trois cartes rangées côte à côte
/// donnent l'image d'un petit lot, quand il y en a vingt. La pile prend alors la
/// forme d'un **paquet** : deux tirages de front, penchés en sens contraires, et
/// entre eux des bords qui affleurent par le bas. Ce sont eux qui disent qu'il y
/// a « du fond » derrière, ce que le compteur seul ne montrerait pas.
///
/// ## Ce que porte l'aperçu
///
/// Le nombre de cartes dessinées est plafonné dans les deux cas : au-delà, on
/// n'ajoute que des liserés déjà illisibles. C'est le compteur, non la pile, qui
/// porte la quantité — et il annonce le total réel, pas les cartes visibles.
class PhotoStack extends StatelessWidget {
  const PhotoStack({
    super.key,
    required this.images,
    required this.onTap,
    this.timeLabel,
    this.height = 190,
    this.isUploading = false,
  });

  /// Toutes les images du lot, dans l'ordre d'envoi.
  final List<String> images;

  /// Ouvre la visionneuse. L'index de départ est toujours la première image :
  /// on ne peut pas viser une carte précise dans une pile, et prétendre le
  /// contraire ouvrirait au hasard.
  final VoidCallback onTap;

  /// Heure d'envoi, posée sur le tirage de front lorsqu'aucune bulle ne
  /// l'accueille.
  ///
  /// Portée par la pile et non par la bulle : sa place dépend de la hauteur cédée
  /// aux bords entrevus, que seule la mise en page connaît. Posée de l'extérieur,
  /// elle tombait sous le tirage de front, dans la tranche du paquet.
  final String? timeLabel;

  /// Le téléversement est en cours : la pile s'assombrit et porte un
  /// indicateur.
  ///
  /// Le retour est posé **sur l'image** et non ailleurs dans l'écran : c'est
  /// elle qu'on regarde en attendant, et un indicateur logé dans la barre de
  /// saisie n'apprend pas laquelle des photos est concernée.
  final bool isUploading;

  /// Hauteur de l'aperçu.
  ///
  /// Calée sur ~0,65 de la largeur d'une bulle : au-delà, un envoi de photos
  /// chasse le reste du fil hors de l'écran, et il faut remonter pour retrouver
  /// le message qui l'accompagnait.
  final double height;

  /// Part de la largeur disponible occupée par une carte, en escalier.
  ///
  /// En dessous de ~0,6 les cartes se chevauchent trop pour qu'on distingue deux
  /// photos ; au-dessus, l'éventail se referme et la pile ressemble à une image
  /// unique mal cadrée.
  static const double _cardWidthRatio = 0.66;

  /// Part occupée par chacun des deux tirages de front, en paquet.
  ///
  /// Juste au-delà de la moitié : les deux tirages se **juxtaposent**, en se
  /// recouvrant d'un doigt au centre. Plus large, celui de gauche mange l'autre
  /// et le paquet redevient une photo unique flanquée d'un bord — c'est ce qui
  /// distinguait le rendu de la référence.
  static const double _bundleCardWidthRatio = 0.52;

  /// Inclinaison d'un tirage de front, en radians (~4,9°).
  ///
  /// Plus franche que dans l'escalier : deux cartes qui se touchent sans se
  /// couvrir n'ont que leur angle pour dire qu'elles sont posées l'une sur
  /// l'autre, là où l'escalier le dit déjà par son décalage.
  static const double _bundleTilt = 0.085;

  /// Inclinaison maximale d'une carte, en radians (~3,2°).
  ///
  /// L'œil lit l'empilement dès une très faible rotation ; au-delà de 5° la pile
  /// paraît tombée plutôt que posée, et les coins mordent les bulles voisines.
  static const double _maxTilt = 0.056;

  /// Au-delà de ce nombre d'images, la pile passe en paquet.
  static const int _bundleThreshold = 5;

  /// Cartes dessinées en escalier.
  static const int _maxCards = 3;

  /// Bords entrevus au centre d'un paquet.
  ///
  /// Deux suffisent à créer une profondeur ; un troisième liseré se confondrait
  /// avec l'ombre des tirages de front.
  static const int _peekCards = 2;

  /// Décalage vertical d'un bord entrevu.
  ///
  /// Volontairement court : ce qui affleure doit se **deviner** sous la jointure,
  /// pas s'afficher. Un décalage franc donnait un bandeau bien lisible en bas du
  /// paquet, que l'œil lit comme une troisième photo mal placée.
  static const double _peekStep = 6;

  /// Part de la largeur d'un tirage occupée par un bord entrevu.
  ///
  /// Étroit et centré sur la jointure des deux tirages : c'est là que le regard
  /// cherche le fond du paquet.
  static const double _peekWidthRatio = 0.62;

  /// Marge réservée au débordement de l'inclinaison.
  ///
  /// Une carte tournée de θ occupe `w·cos θ + h·sin θ` : ses coins sortent donc
  /// de la boîte qu'elle occupait d'aplomb. Sans cette réserve, la carte de
  /// queue mordait le bord de l'écran et son ombre s'y trouvait coupée — un
  /// défaut invisible sur la pile de gauche, systématique sur celle de droite.
  double _tiltMarginFor(double height) =>
      height * math.sin(_isBundle ? _bundleTilt : _maxTilt);

  bool get _isBundle => images.length > _bundleThreshold;

  /// Hauteur cédée aux bords entrevus, sous le tirage de front.
  double get _peekReserve => _isBundle ? _peekCards * _peekStep : 0;

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) return const SizedBox.shrink();

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cards = _layout(constraints.maxWidth);

          return SizedBox(
            width: constraints.maxWidth,
            height: height,
            child: Stack(
              children: [
                // `_layout` rend les cartes du fond vers l'avant : dans un Stack
                // le dernier enfant est au-dessus, et c'est le tirage de tête qui
                // doit couvrir les autres.
                for (final card in cards)
                  Positioned(
                    left: card.left,
                    top: card.top,
                    child: Transform.rotate(
                      angle: card.angle,
                      child: _PhotoCard(
                        path: images[card.imageIndex],
                        width: card.width,
                        height: card.height,
                        dimmed: isUploading,
                      ),
                    ),
                  ),
                if (images.length > 1 && !isUploading)
                  Positioned.fill(
                    child: Center(child: _CountBadge(count: images.length)),
                  ),
                // L'indicateur seul est posé sur la boîte ; l'assombrissement,
                // lui, appartient à chaque carte — appliqué ici, il peindrait
                // aussi la marge de rotation et cernerait la pile d'un
                // rectangle gris.
                if (isUploading)
                  const Positioned.fill(
                    child: IgnorePointer(
                      child: Center(
                        child: SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (timeLabel != null && timeLabel!.isNotEmpty)
                  Positioned(
                    // Calée sur le coin du tirage de front, marge de rotation et
                    // tranche du paquet déduites.
                    right: _tiltMarginFor(height) + DesignTokens.spaceS,
                    bottom:
                        _tiltMarginFor(height) +
                        _peekReserve +
                        DesignTokens.spaceS,
                    child: _TimeBadge(label: timeLabel!),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Position de chaque carte, **du fond vers l'avant**.
  ///
  /// Séparé de `build` parce que c'est la seule part de la pile qui se raisonne :
  /// une géométrie faite d'un ratio, d'un angle et d'une réserve de rotation se
  /// vérifie sur des nombres, là où l'arbre de widgets ne se vérifie qu'à l'œil.
  List<_CardPlacement> _layout(double width) {
    if (images.length == 1) {
      // Une seule photo n'a rien à empiler : elle prend toute la largeur,
      // d'aplomb, comme dans Messages — et n'a donc pas de marge à réserver.
      return [
        _CardPlacement(
          left: 0,
          top: 0,
          width: width,
          height: height,
          angle: 0,
          imageIndex: 0,
        ),
      ];
    }

    final margin = _tiltMarginFor(height);
    final usableWidth = width - 2 * margin;

    if (!_isBundle) {
      final count = math.min(images.length, _maxCards);
      final cardWidth = usableWidth * _cardWidthRatio;
      final travel = usableWidth - cardWidth;
      final cardHeight = height - 2 * margin;

      return [
        for (var i = count - 1; i >= 0; i--)
          _CardPlacement(
            left: margin + travel * i / (count - 1),
            top: margin,
            width: cardWidth,
            height: cardHeight,
            // Normalisé pour que la carte extrême atteigne exactement
            // [_maxTilt] : à trois cartes, la forme naïve
            // `(i - (count - 1) / 2) * 2 * _maxTilt` en donnait le double, que
            // la marge de rotation ne couvrait pas — l'escalier débordait alors
            // à gauche.
            angle: ((i - (count - 1) / 2) / ((count - 1) / 2)) * _maxTilt,
            imageIndex: i,
          ),
      ];
    }

    // Les bords entrevus descendent sous les tirages de front : la hauteur qui
    // leur est cédée doit être retirée des cartes, sinon le paquet dépasse de la
    // boîte annoncée.
    final cardHeight = height - 2 * margin - _peekCards * _peekStep;
    final cardWidth = usableWidth * _bundleCardWidthRatio;
    final peekWidth = cardWidth * _peekWidthRatio;
    final peekLeft = margin + (usableWidth - peekWidth) / 2;

    return [
      // Du plus enfoui au plus proche : le dernier bord entrevu est celui qui
      // affleure le moins.
      for (var i = _peekCards; i >= 1; i--)
        _CardPlacement(
          left: peekLeft,
          top: margin + _peekStep * i,
          width: peekWidth,
          height: cardHeight,
          // D'aplomb : incliné, un bord entrevu ne se lirait plus comme la
          // tranche d'un paquet mais comme une quatrième photo de travers.
          angle: 0,
          imageIndex: i + 1,
        ),
      // La droite avant la gauche : c'est le tirage de gauche qui chevauche
      // l'autre sur la référence, donc lui qui doit être peint en dernier.
      _CardPlacement(
        left: margin + usableWidth - cardWidth,
        top: margin,
        width: cardWidth,
        height: cardHeight,
        angle: _bundleTilt,
        imageIndex: 1,
      ),
      _CardPlacement(
        left: margin,
        top: margin,
        width: cardWidth,
        height: cardHeight,
        angle: -_bundleTilt,
        imageIndex: 0,
      ),
    ];
  }
}

/// Position calculée d'une carte dans la pile.
class _CardPlacement {
  const _CardPlacement({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.angle,
    required this.imageIndex,
  });

  final double left;
  final double top;
  final double width;
  final double height;

  /// Inclinaison en radians, positive vers la droite.
  final double angle;

  final int imageIndex;
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
    this.dimmed = false,
  });

  final String path;
  final double width;
  final double height;

  /// Assombrit le tirage pendant le téléversement.
  final bool dimmed;

  /// Le liseré reste fin : sur un tirage de la taille d'une vignette, un bord
  /// épais tient plus de place que ce qu'il encadre.
  static const double _border = 3;

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
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 8,
            offset: const Offset(0, 2),
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
          // Assombri par la couche de peinture plutôt que par un widget
          // superposé : le voile épouse ainsi exactement le tirage, coins
          // arrondis compris.
          color: dimmed ? Colors.black.withValues(alpha: 0.45) : null,
          colorBlendMode: dimmed ? BlendMode.darken : null,
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

/// Heure d'envoi posée sur la photo.
///
/// Le voile sombre est indispensable : une heure blanche sur un ciel clair
/// disparaît, et sur un bâtiment sombre une heure grise en fait autant.
class _TimeBadge extends StatelessWidget {
  const _TimeBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall
            ?.merge(AppleType.caption2)
            .copyWith(color: Colors.white),
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
