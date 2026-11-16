import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supplies_chat_app/config/theme/theme.dart';
import 'package:supplies_chat_app/core/l10n/generated/app_localizations.dart';
import 'package:supplies_chat_app/core/platform/app_platform.dart';
import 'package:supplies_chat_app/core/platform/platform_ui_provider.dart';
import 'package:supplies_chat_app/domain/entity/auth/user_role.dart';
import 'package:supplies_chat_app/presentation/shared/models/conversation_view_data.dart';
import 'package:supplies_chat_app/presentation/widgets/inbox/conversation_title.dart';
import 'package:supplies_chat_app/presentation/widgets/inbox/inbox_avatar.dart';
import 'package:supplies_chat_app/presentation/widgets/inbox/inbox_conversation_tile.dart';

import '../../helpers/test_environment.dart';

const _order = '01-ORD 1731600000000AB12CD';
const _orderNoSpace = '1731600000000000AB12CD';
const _longName =
    'Établissements Kodjo Mensah et Fils — Distribution Lomé Grand Marché';

Widget _app(
  Widget child, {
  Brightness brightness = Brightness.light,
  Locale locale = const Locale('fr'),
  double textScale = 1,
  TextDirection? direction,
}) => ProviderScope(
  overrides: [appPlatformProvider.overrideWithValue(AppPlatform.android)],
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: locale,
    home: Builder(
      builder: (context) {
        Widget body = MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: Scaffold(body: child),
        );
        if (direction != null) {
          body = Directionality(textDirection: direction, child: body);
        }
        return Theme(
          data: brightness == Brightness.dark
              ? TAppTheme.darkThemeData(context)
              : TAppTheme.lightThemeData(context),
          child: body,
        );
      },
    ),
  ),
);

RenderParagraph _paragraph(WidgetTester tester, Finder text) =>
    tester.renderObject<RenderParagraph>(
      find.descendant(of: text, matching: find.byType(RichText)),
    );

void main() {
  setUpAll(setUpTestEnvironment);

  /// Every combination of content that a realtime refresh can toggle on a
  /// row: none of them may change its height.
  final variants = <String, ConversationListItemData>{
    'bare': const ConversationListItemData(
      id: 'a',
      name: 'A',
      preview: 'Ok',
      timeLabel: '09:00',
    ),
    'unread': const ConversationListItemData(
      id: 'a',
      name: 'A',
      preview: 'Ok',
      timeLabel: '09:00',
      unreadCount: 3,
    ),
    'unread 99+': const ConversationListItemData(
      id: 'a',
      name: 'A',
      preview: 'Ok',
      timeLabel: '09:00',
      unreadCount: 250,
    ),
    'order': const ConversationListItemData(
      id: 'a',
      name: 'A',
      preview: 'Ok',
      timeLabel: '09:00',
      orderNumber: _order,
    ),
    'unclaimed pill': const ConversationListItemData(
      id: 'a',
      name: 'A',
      preview: 'Ok',
      timeLabel: '09:00',
      ticketState: InboxTicketState.unclaimed,
    ),
    'assigned pill + long preview': const ConversationListItemData(
      id: 'a',
      name: _longName,
      preview:
          'Un aperçu bien plus long qui occupe les deux lignes réservées '
          'et déborde même au-delà de ce qui est affichable dans la ligne',
      timeLabel: '09:00',
      ticketState: InboxTicketState.assigned,
      assigneeName: 'Kodjo Agbeko Mensah-Lawson',
      unreadCount: 7,
      orderNumber: _order,
      peerRole: UserRole.delivery,
    ),
    'missed call': const ConversationListItemData(
      id: 'a',
      name: 'A',
      preview: 'Appel manqué',
      timeLabel: '09:00',
      isMissedCall: true,
    ),
  };

  for (final density in InboxDensity.values) {
    for (final scale in [1.0, 1.3]) {
      testWidgets('${density.name} x$scale: row height is fixed whatever the '
          'content', (tester) async {
        final heights = <String, double>{};
        for (final MapEntry(:key, :value) in variants.entries) {
          await tester.pumpWidget(
            _app(
              Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: density == InboxDensity.desktop ? 300 : 390,
                  child: InboxConversationTile(
                    data: value,
                    density: density,
                    onTap: () {},
                  ),
                ),
              ),
              textScale: scale,
            ),
          );
          heights[key] = tester
              .getSize(find.byType(InboxConversationTile))
              .height;
          expect(tester.takeException(), isNull, reason: key);
        }
        expect(
          heights.values.toSet(),
          hasLength(1),
          reason: 'heights per variant: $heights',
        );
      });
    }
  }

  group('narrow, RTL and locales', () {
    for (final direction in TextDirection.values) {
      for (final width in [320.0, 390.0]) {
        testWidgets('${direction.name} at $width px: no overflow, order tail '
            'stays readable', (tester) async {
          await tester.pumpWidget(
            _app(
              Center(
                child: SizedBox(
                  width: width,
                  child: const InboxConversationTile(
                    data: ConversationListItemData(
                      id: 'a',
                      name: _longName,
                      preview: 'Bonjour',
                      timeLabel: 'mercredi',
                      unreadCount: 12,
                      orderNumber: _orderNoSpace,
                      ticketState: InboxTicketState.unclaimed,
                      peerRole: UserRole.vendor,
                    ),
                    onTap: _noop,
                  ),
                ),
              ),
              direction: direction,
            ),
          );
          expect(tester.takeException(), isNull);
          final order = find.byKey(ConversationTitle.orderKey);
          expect(order, findsOneWidget);
          final label = tester.widget<Text>(order).data!;
          expect(label, startsWith('('));
          expect(label, endsWith(')'));
          // The distinctive end is kept even when the line is tight.
          expect(label, contains('…'));
          expect(label, endsWith('D)'));
          expect(_paragraph(tester, order).didExceedMaxLines, isFalse);
        });
      }
    }

    testWidgets('a short order number is shown whole and the name keeps the '
        'rest of the line', (tester) async {
      await tester.pumpWidget(
        _app(
          const SizedBox(
            width: 390,
            child: InboxConversationTile(
              data: ConversationListItemData(
                id: 'a',
                name: 'Aline',
                preview: 'Bonjour',
                timeLabel: '09:00',
                orderNumber: '1731',
              ),
              onTap: _noop,
            ),
          ),
        ),
      );
      expect(find.text('(1731)'), findsOneWidget);
      expect(
        _paragraph(
          tester,
          find.byKey(ConversationTitle.nameKey),
        ).didExceedMaxLines,
        isFalse,
      );
    });

    testWidgets('a blank order number renders the name alone', (tester) async {
      await tester.pumpWidget(
        _app(const ConversationTitle(name: 'Aline', orderNumber: '   ')),
      );
      expect(find.byKey(ConversationTitle.orderKey), findsNothing);
      expect(find.text('Aline'), findsOneWidget);
    });

    testWidgets('english ownership labels and role semantics', (tester) async {
      final handle = tester.ensureSemantics();
      Future<void> pump(InboxTicketState state, UserRole? role) =>
          tester.pumpWidget(
            _app(
              InboxConversationTile(
                data: ConversationListItemData(
                  id: 'a',
                  name: 'Aline',
                  preview: 'Hello',
                  timeLabel: '09:00',
                  ticketState: state,
                  peerRole: role,
                ),
                onTap: _noop,
              ),
              locale: const Locale('en'),
              brightness: Brightness.dark,
            ),
          );
      await pump(InboxTicketState.unclaimed, UserRole.client);
      expect(find.text('Unassigned'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('Customer')), findsOneWidget);
      await pump(InboxTicketState.mine, UserRole.delivery);
      expect(find.text('You'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('Assigned to You')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('Driver')), findsOneWidget);
      await pump(InboxTicketState.assigned, UserRole.vendor);
      expect(find.text('Assigned'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('Vendor')), findsOneWidget);
      handle.dispose();
    });
  });

  group('InboxAvatar role badge', () {
    test('client, driver and vendor have a color and an icon; staff none', () {
      for (final role in [
        UserRole.client,
        UserRole.delivery,
        UserRole.vendor,
      ]) {
        for (final dark in [true, false]) {
          expect(InboxAvatar.colorFor(role, isDark: dark), isNotNull);
        }
        expect(InboxAvatar.iconFor(role), isNotNull);
      }
      for (final role in [
        null,
        UserRole.admin,
        UserRole.support,
        UserRole.superAdmin,
      ]) {
        expect(InboxAvatar.colorFor(role, isDark: false), isNull);
        expect(InboxAvatar.iconFor(role), isNull);
      }
      final colors = {
        for (final r in [UserRole.client, UserRole.delivery, UserRole.vendor])
          InboxAvatar.colorFor(r, isDark: false),
      };
      expect(colors, hasLength(3), reason: 'each role is distinguishable');
    });

    testWidgets('the driver badge is a motorbike, not a truck', (
      tester,
    ) async {
      expect(InboxAvatar.iconFor(UserRole.delivery), Icons.two_wheeler);
      await tester.pumpWidget(
        _app(
          const InboxAvatar(
            name: 'Kossi',
            size: 40,
            badgeSize: 16,
            ringColor: Colors.white,
            role: UserRole.delivery,
          ),
        ),
      );
      final icon = tester.widget<Icon>(
        find.descendant(
          of: find.byType(InboxAvatar),
          matching: find.byType(Icon),
        ),
      );
      expect(icon.icon, Icons.two_wheeler);
      // Badge geometry is unchanged: 62 % of the badge diameter.
      expect(icon.size, closeTo(16 * 0.62, 0.001));
    });

    testWidgets('staff avatars draw no badge', (tester) async {
      await tester.pumpWidget(
        _app(
          const InboxAvatar(
            name: 'Admin',
            size: 40,
            badgeSize: 16,
            ringColor: Colors.white,
            role: UserRole.admin,
          ),
        ),
      );
      expect(
        find.descendant(
          of: find.byType(InboxAvatar),
          matching: find.byType(Icon),
        ),
        findsNothing,
      );
    });
  });

  group('InboxUnreadBadge', () {
    testWidgets('caps at 99+', (tester) async {
      for (final (count, label) in [(1, '1'), (99, '99'), (100, '99+')]) {
        await tester.pumpWidget(_app(InboxUnreadBadge(count: count)));
        expect(find.text(label), findsOneWidget);
      }
    });
  });

  group('fitOrderLabel', () {
    // The test font (Ahem) draws every glyph one em wide: 12 px per char.
    String fmt(String n) => '($n)';
    const style = TextStyle(fontSize: 12);
    String fit(String order, double maxWidth) =>
        ConversationTitle.fitOrderLabel(
          order,
          format: fmt,
          style: style,
          maxWidth: maxWidth,
        );

    test('keeps the prefix before the first space when there is room', () {
      expect(fit(_order, 220), '(01-ORD …00AB12CD)');
    });

    test('drops the prefix in a narrow space but keeps a 4+ char tail', () {
      expect(fit(_order, 100), '(…B12CD)');
    });

    test('a 24-char order without space is shortened from the start', () {
      expect(fit(_orderNoSpace, 132), '(…00AB12CD)');
    });

    test('below a 4-char tail, still prefers the end over the prefix', () {
      expect(fit(_order, 60), '(…CD)');
    });

    test('falls back to the full label when not one char fits', () {
      expect(fit(_order, 30), '($_order)');
    });

    test('unbounded width and single-character orders are untouched', () {
      expect(
        ConversationTitle.fitOrderLabel(
          _order,
          format: fmt,
          style: style,
          maxWidth: double.infinity,
        ),
        '($_order)',
      );
      expect(
        ConversationTitle.fitOrderLabel(
          '7',
          format: fmt,
          style: style,
          maxWidth: 1,
        ),
        '(7)',
      );
    });

    test('text scale shortens more aggressively', () {
      final plain = ConversationTitle.fitOrderLabel(
        _orderNoSpace,
        format: fmt,
        style: style,
        maxWidth: 110,
      );
      final scaled = ConversationTitle.fitOrderLabel(
        _orderNoSpace,
        format: fmt,
        style: style,
        maxWidth: 110,
        textScaler: const TextScaler.linear(1.3),
      );
      expect(scaled.length, lessThanOrEqualTo(plain.length));
    });
  });
}

void _noop() {}
