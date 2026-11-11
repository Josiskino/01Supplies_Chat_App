import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;

import '../../../../config/theme/apple_type.dart';
import '../../../../config/theme/design_tokens.dart';
import '../../../../core/utils/chat_date_formatter.dart';

/// Un message prêt à être posé dans [StickyDateList].
class DatedMessage {
  const DatedMessage({required this.sentAt, required this.child});

  /// Sert au regroupement par jour et au libellé du séparateur.
  final DateTime sentAt;

  /// La bulle, déjà construite par l'écran : la liste ne connaît pas le message.
  final Widget child;
}

/// Fil de discussion avec séparateurs de jour et pilule de date flottante.
///
/// Deux mécanismes distincts, souvent confondus :
///
/// - un **séparateur** est inséré dans le flux à chaque changement de jour, et
///   défile avec les messages ;
/// - une **pilule flottante** reste en haut pendant le défilement et affiche le
///   jour du groupe en cours de lecture, puis s'efface une seconde après l'arrêt.
///
/// Sans la seconde, remonter une longue conversation fait perdre le repère
/// temporel dès que le séparateur sort de l'écran.
///
/// Portage du comportement de l'app cliente, avec la présentation d'iOS : pilule
/// de verre plutôt qu'un aplat gris, et libellé en Footnote.
class StickyDateList extends StatefulWidget {
  const StickyDateList({
    super.key,
    required this.messages,
    required this.now,
    this.controller,
    this.padding = EdgeInsets.zero,
    this.restorationId,
  });

  /// Messages en ordre **chronologique croissant**, le plus ancien d'abord.
  final List<DatedMessage> messages;

  /// Heure courante, injectée : les libellés sont relatifs, et « Aujourd'hui »
  /// cesse d'être vrai à minuit. La passer permet aussi de la figer en test.
  final DateTime now;

  final ScrollController? controller;
  final EdgeInsets padding;
  final String? restorationId;

  @override
  State<StickyDateList> createState() => _StickyDateListState();
}

class _StickyDateListState extends State<StickyDateList> {
  final GlobalKey _viewportKey = GlobalKey();
  final Map<int, GlobalKey> _headerKeys = {};
  final List<_Header> _headers = [];

  String? _label;
  bool _visible = false;
  Timer? _hideTimer;

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  /// Construit les enfants et relève au passage la position de chaque
  /// séparateur, qui servira à décider du libellé de la pilule.
  List<Widget> _buildChildren() {
    _headers.clear();
    final out = <Widget>[];
    int? lastDay;

    for (final message in widget.messages) {
      final day = ChatDateFormatter.dayKey(
        message.sentAt,
      ).millisecondsSinceEpoch;
      if (lastDay != day) {
        final key = _headerKeys.putIfAbsent(day, GlobalKey.new);
        final label = ChatDateFormatter.dayLabel(
          message.sentAt,
          now: widget.now,
        );
        _headers.add(_Header(label, key));
        out.add(
          KeyedSubtree(
            key: key,
            child: DatePill(label: label),
          ),
        );
        lastDay = day;
      }
      out.add(message.child);
    }

    // `reverse: true` ancre le fil sur le dernier message sans piloter de
    // contrôleur : la liste est donc fournie à l'envers.
    return out.reversed.toList();
  }

  void _onScroll() {
    _hideTimer?.cancel();
    _updateLabel();
    if (!_visible) setState(() => _visible = true);
    _hideTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _visible = false);
    });
  }

  /// Le jour affiché est celui du dernier séparateur passé au-dessus du bord
  /// haut — c'est-à-dire le groupe dans lequel on lit.
  void _updateLabel() {
    final viewport =
        _viewportKey.currentContext?.findRenderObject() as RenderBox?;
    if (viewport == null) return;
    final top = viewport.localToGlobal(Offset.zero).dy;

    String? label;
    var best = -double.infinity;
    for (final header in _headers) {
      final box = header.key.currentContext?.findRenderObject() as RenderBox?;
      if (box == null) continue;
      final dy = box.localToGlobal(Offset.zero).dy;
      if (dy <= top + 14 && dy > best) {
        best = dy;
        label = header.label;
      }
    }
    // Aucun séparateur franchi : on est encore dans le premier groupe.
    label ??= _headers.isNotEmpty ? _headers.first.label : null;

    if (label != null && label != _label) setState(() => _label = label);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      key: _viewportKey,
      children: [
        NotificationListener<ScrollNotification>(
          onNotification: (n) {
            if (n is ScrollStartNotification || n is ScrollUpdateNotification) {
              _onScroll();
            }
            return false;
          },
          child: ListView(
            restorationId: widget.restorationId,
            controller: widget.controller,
            reverse: true,
            padding: widget.padding,
            // Les séparateurs hors écran doivent rester montés : leur position
            // est ce qui décide du libellé de la pilule.
            scrollCacheExtent: const ScrollCacheExtent.pixels(800),
            children: _buildChildren(),
          ),
        ),
        Positioned(
          top: DesignTokens.spaceS,
          left: 0,
          right: 0,
          // La pilule ne doit intercepter aucun geste : elle flotte au-dessus
          // de bulles qui restent cliquables.
          child: IgnorePointer(
            child: AnimatedOpacity(
              opacity: _visible && _label != null ? 1 : 0,
              duration: DesignTokens.durationNormal,
              child: Center(
                child: _label == null
                    ? const SizedBox.shrink()
                    : DatePill(label: _label!, floating: true),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Header {
  const _Header(this.label, this.key);
  final String label;
  final GlobalKey key;
}

/// Pilule de date — « Aujourd'hui », « Hier », « Jeudi », « 26 juin 2026 ».
class DatePill extends StatelessWidget {
  const DatePill({super.key, required this.label, this.floating = false});

  final String label;

  /// Variante flottante : plus contrastée et ombrée, puisqu'elle se superpose
  /// aux bulles au lieu de reposer sur le fond du fil.
  final bool floating;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: DesignTokens.spaceM),
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spaceM,
          vertical: 5,
        ),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: floating ? 0.16 : 0.10)
              : Colors.black.withValues(alpha: floating ? 0.10 : 0.06),
          borderRadius: DesignTokens.borderRadiusPill,
          boxShadow: floating
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.14),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: theme.textTheme.labelSmall
              ?.merge(AppleType.footnote)
              .copyWith(
                fontWeight: FontWeight.w600,
                color: DesignTokens.getTextColorWithOpacity(context, 0.6),
              ),
        ),
      ),
    );
  }
}
