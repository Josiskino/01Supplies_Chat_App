import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../config/theme/design_tokens.dart';

/// Modern Link Widget
/// Clean underline with subtle hover effect
///
/// Atomic widget for rendering clickable links.
/// Used in DataViewLayout and other components that need link functionality.
///
/// This widget is composable and doesn't know about state management.
/// It receives callbacks via Dependency Injection pattern.
class LinkWidget extends StatelessWidget {
  /// The link text to display
  final String text;

  /// The URL to navigate to (optional, can be handled by onTap)
  final String? url;

  /// Callback when link is tapped
  final VoidCallback? onTap;

  /// Optional custom text style
  final TextStyle? textStyle;

  /// Optional padding around the link
  final EdgeInsets? padding;

  const LinkWidget({
    super.key,
    required this.text,
    this.url,
    this.onTap,
    this.textStyle,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultStyle = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.primary,
      decoration: TextDecoration.underline,
      decorationColor: theme.colorScheme.primary.withValues(alpha: 0.5),
      fontWeight: FontWeight.w500,
      fontSize: 14,
    );

    final linkStyle = textStyle ?? defaultStyle;
    final linkPadding =
        padding ??
        const EdgeInsets.only(
          top: DesignTokens.spaceS,
          bottom: DesignTokens.spaceS,
        );

    return Padding(
      padding: linkPadding,
      child: InkWell(
        onTap: onTap ?? (url == null ? null : () => _openUrl(url!)),
        borderRadius: DesignTokens.borderRadiusXs,
        // Modern ripple effect
        splashColor: theme.colorScheme.primary.withValues(alpha: 0.1),
        highlightColor: theme.colorScheme.primary.withValues(alpha: 0.05),
        child: Text(text, style: linkStyle),
      ),
    );
  }

  Future<void> _openUrl(String rawUrl) async {
    final uri = Uri.tryParse(rawUrl);
    if (uri == null) {
      debugPrint('LinkWidget: invalid URL "$rawUrl"');
      return;
    }
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('LinkWidget: could not launch $uri');
    }
  }
}
