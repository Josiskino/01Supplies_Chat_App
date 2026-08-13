import 'package:flutter/material.dart';

import '../../core/constants/app_images.dart';

/// Logo de l'app qui pulse en boucle, utilisé comme indicateur de chargement
/// au démarrage.
///
/// L'animation *remplace* un `CircularProgressIndicator` au lieu de s'y
/// ajouter : deux signaux d'attente concurrents à l'écran se parasitent, le
/// regard ne sachant plus lequel suivre.
///
/// `ScaleTransition` applique une `Transform` au moment du paint, sans
/// reconstruire l'`Image` à chaque frame — l'asset n'est décodé qu'une fois.
class PulsingLogo extends StatefulWidget {
  const PulsingLogo({
    super.key,
    this.size = 150,
    this.asset = AppImages.appIcon,
  });

  /// Taille de repos du logo, en pixels logiques. L'animation la fait varier
  /// autour de cette valeur.
  final double size;

  final String asset;

  @override
  State<PulsingLogo> createState() => _PulsingLogoState();
}

class _PulsingLogoState extends State<PulsingLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  // Amplitude volontairement modérée : au-delà de ~±10 % la pulsation devient
  // une respiration lourde plutôt qu'un signal d'attente discret.
  late final Animation<double> _scale = Tween<double>(
    begin: 0.88,
    end: 1.08,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Image.asset(
        widget.asset,
        width: widget.size,
        height: widget.size,
      ),
    );
  }
}
