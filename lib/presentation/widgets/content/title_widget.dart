import 'package:flutter/material.dart';
import '../../../config/theme/design_tokens.dart';

/// Modern Title Widget
/// Clean, consistent typography with proper spacing
///
/// This widget is composable and doesn't know about state management.
/// It receives data via constructor parameters (Dependency Injection pattern).
class TitleWidget extends StatelessWidget {
  /// The title text to display
  final String text;

  /// Optional subtitle text to display below the title
  final String? subtitle;

  /// Optional custom text style for the title
  final TextStyle? textStyle;

  /// Optional custom text style for the subtitle
  final TextStyle? subtitleStyle;

  /// Optional padding around the title
  final EdgeInsets? padding;

  /// Spacing between title and subtitle
  final double? subtitleSpacing;

  const TitleWidget({
    super.key,
    required this.text,
    this.subtitle,
    this.textStyle,
    this.subtitleStyle,
    this.padding,
    this.subtitleSpacing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultTitleStyle = theme.textTheme.titleLarge;
    final defaultSubtitleStyle = theme.textTheme.bodyMedium?.copyWith(
      color: DesignTokens.getTextColorWithOpacity(
        context,
        DesignTokens.opacityMedium,
      ),
    );

    final titleStyle = textStyle ?? defaultTitleStyle;
    final subStyle = subtitleStyle ?? defaultSubtitleStyle;
    final titlePadding =
        padding ??
        const EdgeInsets.only(
          top: DesignTokens.spaceL,
          bottom: DesignTokens.spaceS,
        );
    final spacing = subtitleSpacing ?? DesignTokens.spaceXs;

    return Padding(
      padding: titlePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text, style: titleStyle),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            SizedBox(height: spacing),
            Text(subtitle!, style: subStyle),
          ],
        ],
      ),
    );
  }
}
