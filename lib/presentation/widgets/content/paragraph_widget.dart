import 'package:flutter/material.dart';
import '../../../config/theme/design_tokens.dart';

/// Modern Paragraph Widget
/// Clean typography with consistent line height
///
/// This widget is composable and doesn't know about state management.
/// It receives data via constructor parameters (Dependency Injection pattern).
class ParagraphWidget extends StatelessWidget {
  /// The paragraph text to display
  final String text;

  /// Optional custom text style
  final TextStyle? textStyle;

  /// Optional padding around the paragraph
  final EdgeInsets? padding;

  /// Text alignment
  final TextAlign textAlign;

  const ParagraphWidget({
    super.key,
    required this.text,
    this.textStyle,
    this.padding,
    this.textAlign = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    final defaultStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      height: 1.5, // Modern line height for readability
    );
    final style = textStyle ?? defaultStyle;
    final paragraphPadding =
        padding ?? const EdgeInsets.only(bottom: DesignTokens.spaceS);

    return Padding(
      padding: paragraphPadding,
      child: Text(text, style: style, textAlign: textAlign),
    );
  }
}
