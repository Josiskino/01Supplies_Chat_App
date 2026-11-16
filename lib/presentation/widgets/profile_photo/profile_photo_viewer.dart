import 'dart:math' as math;
import 'dart:ui' show ImageFilter, lerpDouble;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:supplies_chat_app/core/utils/localization_helper.dart';

/// True when [url] points to a remote photo that the viewer can display.
bool isViewablePhotoUrl(String? url) {
  final value = url?.trim() ?? '';
  return value.startsWith('https://') || value.startsWith('http://');
}

/// Arguments of the profile photo viewer route.
///
/// They travel as a plain map ([toExtra]) so the router's restoration codec
/// can encode them like any other route extra.
class ProfilePhotoViewerArgs {
  const ProfilePhotoViewerArgs({
    required this.photoUrl,
    required this.name,
    required this.heroTag,
    this.roleLabel,
  });

  final String photoUrl;
  final String name;
  final String heroTag;
  final String? roleLabel;

  Map<String, dynamic> toExtra() => {
    'photoUrl': photoUrl,
    'name': name,
    'heroTag': heroTag,
    if (roleLabel != null) 'roleLabel': roleLabel,
  };

  /// Reads the route extra; null when it is missing or unusable (e.g. a
  /// restored route without its arguments).
  static ProfilePhotoViewerArgs? fromExtra(Object? extra) {
    if (extra is ProfilePhotoViewerArgs) return extra;
    if (extra is! Map) return null;
    final url = extra['photoUrl'];
    if (url is! String || !isViewablePhotoUrl(url)) return null;
    final name = extra['name'];
    final heroTag = extra['heroTag'];
    final role = extra['roleLabel'];
    return ProfilePhotoViewerArgs(
      photoUrl: url.trim(),
      name: name is String ? name : '',
      heroTag: heroTag is String ? heroTag : 'profile-photo:$url',
      roleLabel: role is String && role.trim().isNotEmpty ? role : null,
    );
  }
}

/// Transparent page of the viewer route: the conversation stays visible,
/// blurred, behind the photo. [wrap] lets the router guard the content.
CustomTransitionPage<void> buildProfilePhotoViewerPage(
  GoRouterState state, {
  Widget Function(Widget child)? wrap,
}) {
  final viewer = ProfilePhotoViewer(
    args: ProfilePhotoViewerArgs.fromExtra(state.extra),
  );
  return CustomTransitionPage<void>(
    key: state.pageKey,
    restorationId: state.pageKey.value,
    opaque: false,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    child: wrap?.call(viewer) ?? viewer,
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        ),
  );
}

/// Hero shuttle shared by the avatar and the viewer: the photo grows from a
/// circle into the viewer's square (and back on dismiss).
Widget profilePhotoFlightShuttle(
  BuildContext flightContext,
  Animation<double> animation,
  HeroFlightDirection flightDirection,
  BuildContext fromHeroContext,
  BuildContext toHeroContext,
) {
  final viewerContext = flightDirection == HeroFlightDirection.push
      ? toHeroContext
      : fromHeroContext;
  final viewerHero = viewerContext.widget as Hero;
  return AnimatedBuilder(
    animation: animation,
    child: viewerHero.child,
    builder: (context, child) => LayoutBuilder(
      builder: (context, constraints) {
        final half = constraints.biggest.shortestSide / 2;
        final radius = lerpDouble(half, 0, animation.value) ?? 0;
        return ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: child,
        );
      },
    ),
  );
}

/// Full-screen view of a person's profile photo: pinch or double-tap to
/// zoom, swipe down (or the close button) to dismiss.
class ProfilePhotoViewer extends StatefulWidget {
  const ProfilePhotoViewer({super.key, required this.args});

  /// Null when the route was opened without usable arguments.
  final ProfilePhotoViewerArgs? args;

  static const closeButtonKey = ValueKey('profile-photo-viewer-close');
  static const zoomAreaKey = ValueKey('profile-photo-viewer-zoom');

  @override
  State<ProfilePhotoViewer> createState() => _ProfilePhotoViewerState();
}

class _ProfilePhotoViewerState extends State<ProfilePhotoViewer>
    with SingleTickerProviderStateMixin {
  static const double _dismissDistance = 120;
  static const double _dismissVelocity = 800;
  static const double _doubleTapScale = 2.5;

  final _transform = TransformationController();
  late final AnimationController _snapBack;

  double _dragOffset = 0;
  double _snapBackFrom = 0;
  bool _zoomed = false;
  bool _closing = false;
  Offset? _doubleTapPosition;

  @override
  void initState() {
    super.initState();
    _snapBack = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    )..addListener(_onSnapBack);
    _transform.addListener(_onTransformChanged);
  }

  @override
  void dispose() {
    _transform
      ..removeListener(_onTransformChanged)
      ..dispose();
    _snapBack.dispose();
    super.dispose();
  }

  void _onTransformChanged() {
    final zoomed = _transform.value.getMaxScaleOnAxis() > 1.01;
    if (zoomed != _zoomed) setState(() => _zoomed = zoomed);
  }

  void _onSnapBack() {
    setState(() {
      _dragOffset =
          _snapBackFrom * (1 - Curves.easeOut.transform(_snapBack.value));
    });
  }

  void _onInteractionUpdate(ScaleUpdateDetails details) {
    if (_zoomed || details.pointerCount != 1 || _closing) return;
    _snapBack.stop();
    setState(() => _dragOffset += details.focalPointDelta.dy);
  }

  void _onInteractionEnd(ScaleEndDetails details) {
    if (_dragOffset == 0 || _closing) return;
    final velocity = details.velocity.pixelsPerSecond.dy.abs();
    if (_dragOffset.abs() > _dismissDistance || velocity > _dismissVelocity) {
      _close();
      return;
    }
    _snapBackFrom = _dragOffset;
    _snapBack.forward(from: 0);
  }

  void _toggleZoom() {
    if (widget.args == null) return;
    if (_zoomed) {
      _transform.value = Matrix4.identity();
      return;
    }
    final focal = _doubleTapPosition ?? Offset.zero;
    _transform.value = Matrix4.identity()
      ..translateByDouble(
        -focal.dx * (_doubleTapScale - 1),
        -focal.dy * (_doubleTapScale - 1),
        0,
        1,
      )
      ..scaleByDouble(_doubleTapScale, _doubleTapScale, 1, 1);
  }

  void _close() {
    if (_closing) return;
    _closing = true;
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final args = widget.args;
    final progress = (_dragOffset.abs() / 300).clamp(0.0, 1.0);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Material(
        type: MaterialType.transparency,
        child: Stack(
          fit: StackFit.expand,
          children: [
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: ColoredBox(
                color: Colors.black.withValues(
                  alpha: 0.88 * (1 - progress * 0.7),
                ),
              ),
            ),
            GestureDetector(
              onDoubleTapDown: (details) =>
                  _doubleTapPosition = details.localPosition,
              onDoubleTap: _toggleZoom,
              child: InteractiveViewer(
                key: ProfilePhotoViewer.zoomAreaKey,
                transformationController: _transform,
                minScale: 1,
                maxScale: 4,
                panEnabled: _zoomed,
                onInteractionUpdate: _onInteractionUpdate,
                onInteractionEnd: _onInteractionEnd,
                child: SizedBox.expand(
                  child: Center(
                    child: Transform.translate(
                      offset: Offset(0, _dragOffset),
                      child: args == null
                          ? const _PhotoUnavailable()
                          : _Photo(args: args),
                    ),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: Opacity(
                opacity: 1 - progress,
                child: SafeArea(
                  bottom: false,
                  child: _TopBar(args: args, onClose: _close),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Photo extends StatelessWidget {
  const _Photo({required this.args});

  final ProfilePhotoViewerArgs args;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final side = math.min(size.width, size.height);
    return SizedBox.square(
      dimension: side,
      child: Hero(
        tag: args.heroTag,
        flightShuttleBuilder: profilePhotoFlightShuttle,
        child: CachedNetworkImage(
          imageUrl: args.photoUrl,
          fit: BoxFit.contain,
          fadeInDuration: const Duration(milliseconds: 150),
          placeholder: (_, _) => const Center(
            child: SizedBox.square(
              dimension: 36,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.5,
              ),
            ),
          ),
          errorWidget: (_, _, _) => const _PhotoUnavailable(),
        ),
      ),
    );
  }
}

class _PhotoUnavailable extends StatelessWidget {
  const _PhotoUnavailable();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.no_photography_outlined,
            color: Colors.white54,
            size: 56,
          ),
          const SizedBox(height: 12),
          Text(
            LocalizationHelper.of(context).profilePhotoUnavailable,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.args, required this.onClose});

  final ProfilePhotoViewerArgs? args;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final name = args?.name.trim() ?? '';
    final role = args?.roleLabel;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 16, 4),
      child: Row(
        children: [
          IconButton(
            key: ProfilePhotoViewer.closeButtonKey,
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            iconSize: 26,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (name.isNotEmpty)
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                if (role != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      role,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
