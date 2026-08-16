import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

/// Fullscreen image viewer with zoom/pan and navigation between images.
///
/// Features:
/// - PageView for swipe navigation between images
/// - InteractiveViewer for zoom (1x-4x) and pan
/// - Double-tap to toggle zoom (1x ↔ 2x)
/// - AppBar with counter (X/Y) and transparent background
/// - Support for both network and local images
/// - Loading and error states
class ImageViewerWidget extends StatefulWidget {
  final List<String>
  imagePaths; // List of image paths (local File paths or HTTP URLs)
  final int initialIndex; // Index of the image to display first

  const ImageViewerWidget({
    super.key,
    required this.imagePaths,
    this.initialIndex = 0,
  });

  @override
  State<ImageViewerWidget> createState() => _ImageViewerWidgetState();
}

class _ImageViewerWidgetState extends State<ImageViewerWidget> {
  late PageController _pageController;
  late TransformationController _transformationController;
  int _currentIndex = 0;
  bool _isZoomed = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _transformationController = TransformationController();
    _transformationController.addListener(_onTransformationChanged);
  }

  @override
  void dispose() {
    _transformationController.removeListener(_onTransformationChanged);
    _transformationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  /// Listen to zoom changes and update state
  void _onTransformationChanged() {
    final scale = _transformationController.value.getMaxScaleOnAxis();
    final wasZoomed = _isZoomed;
    final isZoomedNow = scale > 1.0;

    if (wasZoomed != isZoomedNow) {
      setState(() {
        _isZoomed = isZoomedNow;
      });
    }
  }

  /// Handle double-tap to toggle zoom
  void _handleDoubleTap() {
    final scale = _transformationController.value.getMaxScaleOnAxis();

    if (scale > 1.1) {
      // Reset to 1x
      _transformationController.value = Matrix4.identity();
    } else {
      // Zoom to 2x centered
      _transformationController.value = Matrix4.identity()
        ..scaleByDouble(2.0, 2.0, 2.0, 1.0);
    }
  }

  /// Check if path is a network image
  bool _isNetworkImage(String path) {
    return path.startsWith('http://') || path.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          '${_currentIndex + 1}/${widget.imagePaths.length}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
      ),
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
            // Reset zoom when changing page
            _transformationController.value = Matrix4.identity();
          });
        },
        itemCount: widget.imagePaths.length,
        itemBuilder: (context, index) {
          return _buildImagePage(widget.imagePaths[index]);
        },
      ),
    );
  }

  /// Build individual image page with zoom/pan
  Widget _buildImagePage(String imagePath) {
    return GestureDetector(
      onDoubleTap: _handleDoubleTap,
      child: InteractiveViewer(
        transformationController: _transformationController,
        minScale: 1.0,
        maxScale: 4.0,
        panEnabled: _isZoomed, // Pan only when zoomed
        child: Center(
          child: _isNetworkImage(imagePath)
              ? _buildNetworkImage(imagePath)
              : _buildLocalImage(imagePath),
        ),
      ),
    );
  }

  /// Build network image with loading and error states.
  ///
  /// Utilise directement [CachedNetworkImage] au lieu du widget image partagé :
  /// sur fond noir plein écran, il faut un indicateur blanc, là où le widget
  /// partagé impose un shimmer clair pensé pour les listes.
  Widget _buildNetworkImage(String url) {
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.contain,
      placeholder: (context, _) => const Center(
        child: SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
        ),
      ),
      errorWidget: (context, _, _) => _buildErrorWidget(),
    );
  }

  /// Build local file image with error handling
  Widget _buildLocalImage(String path) {
    return Image.file(
      File(path),
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return _buildErrorWidget();
      },
    );
  }

  /// Build error widget with retry button
  Widget _buildErrorWidget() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Iconsax.gallery_slash, color: Colors.red.shade400, size: 64),
        const SizedBox(height: 16),
        const Text(
          'Impossible de charger l\'image',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () {
            // Force reload by resetting transformation and rebuilding
            _transformationController.value = Matrix4.identity();
            setState(() {});
          },
          icon: const Icon(Iconsax.refresh, size: 18),
          label: const Text('Réessayer'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ],
    );
  }
}
