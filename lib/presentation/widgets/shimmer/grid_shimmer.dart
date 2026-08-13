import 'package:flutter/material.dart';
import '../../../config/theme/design_tokens.dart';
import 'shimmer_widget.dart';

/// Ultra-Flat Grid Skeleton Loader
/// Mimics the grid layout structure with shimmer effect
///
/// Features:
/// - Shows grid item placeholders
/// - Displays thumbnail, title, description
/// - Follows ultra-flat design principles
class GridShimmer extends StatelessWidget {
  final int itemCount;
  final int crossAxisCount;

  const GridShimmer({super.key, this.itemCount = 6, this.crossAxisCount = 2});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: DesignTokens.spaceM,
        mainAxisSpacing: DesignTokens.spaceM,
        childAspectRatio: 0.85,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) => _buildGridItemShimmer(),
    );
  }

  Widget _buildGridItemShimmer() {
    return Builder(
      builder: (context) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.all(DesignTokens.spaceM),
          decoration: BoxDecoration(
            border: Border.all(
              color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
              width: 1,
            ),
            borderRadius: DesignTokens.borderRadiusM,
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              ShimmerWidget.rounded(width: double.infinity, height: 80),
              SizedBox(height: DesignTokens.spaceM),
              // Title
              ShimmerWidget.rounded(width: double.infinity, height: 16),
              SizedBox(height: DesignTokens.spaceS),
              // Description line 1
              ShimmerWidget.rounded(width: double.infinity, height: 12),
              SizedBox(height: DesignTokens.spaceXs),
              // Description line 2
              ShimmerWidget.rounded(width: 80, height: 12),
            ],
          ),
        );
      },
    );
  }
}
