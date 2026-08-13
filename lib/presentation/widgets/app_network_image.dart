import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Widget image réseau unifié — à utiliser partout où une image distante est affichée.
///
/// Exemples :
/// ```dart
/// // Image rectangulaire avec coins arrondis
/// AppNetworkImage(url: product['image'], height: 120, borderRadius: BorderRadius.circular(12))
///
/// // Avatar circulaire
/// AppNetworkImage(url: user.avatar, width: 48, height: 48, shape: BoxShape.circle)
///
/// // Image pleine largeur
/// AppNetworkImage(url: banner, width: double.infinity, height: 200, fit: BoxFit.cover)
/// ```
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.shape = BoxShape.rectangle,
    this.borderRadius,
    this.errorIcon = Icons.image_not_supported_outlined,
    this.errorIconSize = 32,
    this.cacheWidth,
    this.cacheHeight,
  });

  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;

  /// [BoxShape.circle] pour les avatars, [BoxShape.rectangle] pour le reste.
  final BoxShape shape;

  /// Ignoré si [shape] == [BoxShape.circle].
  final BorderRadius? borderRadius;

  /// Icône affichée en cas d'erreur ou d'URL vide.
  final IconData errorIcon;
  final double errorIconSize;

  /// Dimensions de décodage en pixels physiques pour éviter de garder en
  /// mémoire des images beaucoup plus grandes que leur taille affichée.
  final int? cacheWidth;
  final int? cacheHeight;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final clip = shape == BoxShape.circle
        ? BorderRadius.circular(9999)
        : (borderRadius ?? BorderRadius.zero);

    if (url == null || url!.isEmpty) {
      return _ErrorPlaceholder(
        width: width,
        height: height,
        borderRadius: clip,
        icon: errorIcon,
        iconSize: errorIconSize,
        isDark: isDark,
      );
    }

    // Décodage en préservant le ratio : ne contraindre QU'UNE seule dimension.
    // Passer à la fois une largeur ET une hauteur de décodage force un
    // redimensionnement exact (ResizeImagePolicy.exact, équivalent BoxFit.fill)
    // qui déforme le bitmap AVANT que `fit` ne s'applique. En ne fixant qu'une
    // dimension, le SDK calcule l'autre proportionnellement. On prend
    // max(cacheWidth, cacheHeight) pour garantir assez de pixels afin de couvrir
    // la boîte en BoxFit.cover sans étirer (allowUpscaling=false borne la mémoire).
    final decodeExtent = _decodeExtent();

    return ClipRRect(
      borderRadius: clip,
      child: CachedNetworkImage(
        imageUrl: url!,
        width: width,
        height: height,
        fit: fit,
        memCacheWidth: decodeExtent,
        memCacheHeight: null,
        maxWidthDiskCache: decodeExtent,
        maxHeightDiskCache: null,
        useOldImageOnUrlChange: true,
        // Cache-hit returns synchronously — no flicker when re-entering screens.
        fadeInDuration: const Duration(milliseconds: 120),
        fadeOutDuration: Duration.zero,
        placeholder: (context, _) =>
            _ShimmerPlaceholder(width: width, height: height, isDark: isDark),
        errorWidget: (context, _, _) => _ErrorPlaceholder(
          width: width,
          height: height,
          borderRadius: clip,
          icon: errorIcon,
          iconSize: errorIconSize,
          isDark: isDark,
        ),
      ),
    );
  }

  /// Dimension unique transmise au décodeur pour préserver le ratio source.
  /// Renvoie `null` si aucune contrainte n'est fournie (décodage pleine taille).
  int? _decodeExtent() {
    final w = cacheWidth;
    final h = cacheHeight;
    if (w == null && h == null) return null;
    if (w == null) return h;
    if (h == null) return w;
    return w > h ? w : h;
  }
}

class _ShimmerPlaceholder extends StatelessWidget {
  const _ShimmerPlaceholder({this.width, this.height, required this.isDark});

  final double? width;
  final double? height;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        color: isDark ? Colors.grey[800] : Colors.grey[300],
      ),
    );
  }
}

class _ErrorPlaceholder extends StatelessWidget {
  const _ErrorPlaceholder({
    this.width,
    this.height,
    required this.borderRadius,
    required this.icon,
    required this.iconSize,
    required this.isDark,
  });

  final double? width;
  final double? height;
  final BorderRadius borderRadius;
  final IconData icon;
  final double iconSize;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[200],
        borderRadius: borderRadius,
      ),
      child: Center(
        child: Icon(
          icon,
          size: iconSize,
          color: isDark ? Colors.grey[600] : Colors.grey[400],
        ),
      ),
    );
  }
}
