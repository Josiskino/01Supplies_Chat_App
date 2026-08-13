import 'package:flutter/material.dart';
import '../../../config/theme/design_tokens.dart';
import 'shimmer_widget.dart';

/// Ultra-Flat Card List Skeleton Loader
/// Mimics the card layout structure with shimmer effect
///
/// Features:
/// - Shows card placeholders in a list
/// - Displays thumbnail, title, description
/// - Follows ultra-flat design principles
class CardListShimmer extends StatelessWidget {
  final int cardCount;

  const CardListShimmer({super.key, this.cardCount = 3});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(cardCount, (index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: DesignTokens.spaceL),
          child: _buildCardShimmer(),
        );
      }),
    );
  }

  Widget _buildCardShimmer() {
    return Builder(
      builder: (context) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.all(DesignTokens.spaceL),
          decoration: BoxDecoration(
            border: Border.all(
              color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
              width: 1,
            ),
            borderRadius: DesignTokens.borderRadiusM,
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              ShimmerWidget.rounded(width: 80, height: 80),
              SizedBox(width: DesignTokens.spaceL),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    ShimmerWidget.rounded(width: double.infinity, height: 18),
                    SizedBox(height: DesignTokens.spaceS),
                    // Description line 1
                    ShimmerWidget.rounded(width: double.infinity, height: 14),
                    SizedBox(height: DesignTokens.spaceXs),
                    // Description line 2
                    ShimmerWidget.rounded(width: 150, height: 14),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
