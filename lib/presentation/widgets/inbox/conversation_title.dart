import 'package:flutter/material.dart';

import '../../../config/theme/design_tokens.dart';
import '../../../core/utils/localization_helper.dart';

/// Contact name followed by the linked order number in parentheses.
///
/// The order number is smaller and grey so the name keeps the lead, and the
/// **name** is the part that gets ellipsized: the order number is what an
/// agent looks for when several requests come from the same customer, so it
/// must stay visible. When it alone would take more than [maxOrderShare] of
/// the line, it is shortened in the middle (see [fitOrderLabel]) so its
/// distinctive tail remains readable.
class ConversationTitle extends StatelessWidget {
  const ConversationTitle({
    super.key,
    required this.name,
    this.orderNumber,
    this.nameStyle,
    this.orderStyle,
    this.maxOrderShare = 0.6,
  });

  static const Key nameKey = ValueKey('conversation-title-name');
  static const Key orderKey = ValueKey('conversation-title-order');

  final String name;
  final String? orderNumber;
  final TextStyle? nameStyle;

  /// Defaults to [nameStyle] at 80 % of its size, regular weight, muted.
  final TextStyle? orderStyle;
  final double maxOrderShare;

  /// Order style derived from a name style: smaller, regular weight, grey.
  static TextStyle orderStyleFor(BuildContext context, TextStyle base) {
    final size = base.fontSize ?? 14;
    return base.copyWith(
      fontSize: (size * 0.8).roundToDouble(),
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      color: DesignTokens.getTextColorWithOpacity(
        context,
        DesignTokens.inboxMutedOpacity,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolvedName =
        nameStyle ??
        Theme.of(context).textTheme.titleSmall ??
        const TextStyle();
    final order = orderNumber?.trim();

    final nameText = Text(
      name,
      key: nameKey,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      softWrap: false,
      style: resolvedName,
    );
    if (order == null || order.isEmpty) return nameText;

    final l10n = LocalizationHelper.of(context);
    final style = orderStyle ?? orderStyleFor(context, resolvedName);
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxOrderWidth = constraints.maxWidth * maxOrderShare;
        final label = fitOrderLabel(
          order,
          format: l10n.inboxOrderNumber,
          style: style,
          maxWidth: maxOrderWidth,
          textScaler: MediaQuery.textScalerOf(context),
          textDirection: Directionality.of(context),
        );
        return Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Flexible(child: nameText),
            const SizedBox(width: DesignTokens.spaceXs),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxOrderWidth),
              child: Text(
                label,
                key: orderKey,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: style,
              ),
            ),
          ],
        );
      },
    );
  }

  /// Formats [order] so it fits [maxWidth], shortening it in the middle.
  ///
  /// Order numbers are long (`01-ORD 1731600000000AB12CD`) and their
  /// distinctive part is the end: a trailing ellipsis would keep the prefix
  /// every order shares and hide the characters that tell them apart. The
  /// prefix before the first space and as much of the tail as fits are kept
  /// (`(01-ORD …00AB12CD)`); in a narrower space only the tail (`(…AB12CD)`).
  static String fitOrderLabel(
    String order, {
    required String Function(String) format,
    required TextStyle style,
    required double maxWidth,
    TextScaler textScaler = TextScaler.noScaling,
    TextDirection textDirection = TextDirection.ltr,
  }) {
    final full = format(order);
    if (!maxWidth.isFinite) return full;
    final painter = TextPainter(
      textDirection: textDirection,
      textScaler: textScaler,
      maxLines: 1,
    );
    bool fits(String text) {
      painter.text = TextSpan(text: text, style: style);
      painter.layout();
      return painter.width <= maxWidth;
    }

    try {
      if (fits(full)) return full;
      final space = order.indexOf(' ');
      final head = space > 0 && space <= 8
          ? '${order.substring(0, space)} '
          : '';
      final body = order.substring(head.length);
      // Longest tail that fits after [prefix]; 0 when not even one char does.
      int longestTail(String prefix) {
        var low = 1;
        var high = body.length - 1;
        var best = 0;
        while (low <= high) {
          final mid = (low + high) ~/ 2;
          if (fits(format('$prefix…${body.substring(body.length - mid)}'))) {
            best = mid;
            low = mid + 1;
          } else {
            high = mid - 1;
          }
        }
        return best;
      }

      // Keep the shared prefix only while it leaves room for a useful tail;
      // past that, the tail alone is what tells two orders apart.
      for (final prefix in [if (head.isNotEmpty) head, '']) {
        final tail = longestTail(prefix);
        if (tail >= (prefix.isEmpty ? 4 : 6)) {
          return format('$prefix…${body.substring(body.length - tail)}');
        }
      }
      // Nothing meaningful fits: let the Text ellipsize the full label.
      return full;
    } finally {
      painter.dispose();
    }
  }
}
