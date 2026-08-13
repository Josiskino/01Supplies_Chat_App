import 'package:flutter/material.dart';
import '../../../config/theme/design_tokens.dart';
import 'shimmer_widget.dart';

/// Ultra-Flat Form Skeleton Loader
/// Mimics the form layout structure with shimmer effect
///
/// Features:
/// - Shows form field placeholders
/// - Displays submit button placeholder
/// - Follows ultra-flat design principles
class FormShimmer extends StatelessWidget {
  final int fieldCount;

  const FormShimmer({super.key, this.fieldCount = 5});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        const ShimmerWidget.rounded(width: 200, height: 28),
        const SizedBox(height: DesignTokens.spaceM),
        // Description
        const ShimmerWidget.rounded(width: double.infinity, height: 14),
        const SizedBox(height: DesignTokens.spaceS),
        const ShimmerWidget.rounded(width: 250, height: 14),
        const SizedBox(height: DesignTokens.sectionSpacing),
        // Form fields
        ...List.generate(fieldCount, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: DesignTokens.spaceL),
            child: _buildFormFieldShimmer(context),
          );
        }),
        const SizedBox(height: DesignTokens.spaceL),
        // Submit button
        const ShimmerWidget.rounded(width: double.infinity, height: 48),
      ],
    );
  }

  Widget _buildFormFieldShimmer(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        const ShimmerWidget.rounded(width: 120, height: 14),
        const SizedBox(height: DesignTokens.spaceS),
        // Input field
        Container(
          width: double.infinity,
          height: 48,
          padding: const EdgeInsets.all(DesignTokens.spaceM),
          decoration: BoxDecoration(
            border: Border.all(
              color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
              width: 1,
            ),
            borderRadius: DesignTokens.borderRadiusM,
          ),
          child: const Align(
            alignment: Alignment.centerLeft,
            child: ShimmerWidget.rounded(width: 200, height: 16),
          ),
        ),
      ],
    );
  }
}
