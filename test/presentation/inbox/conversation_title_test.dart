import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supplies_chat_app/config/theme/theme.dart';
import 'package:supplies_chat_app/core/l10n/generated/app_localizations.dart';
import 'package:supplies_chat_app/core/platform/app_platform.dart';
import 'package:supplies_chat_app/core/platform/platform_ui_provider.dart';
import 'package:supplies_chat_app/core/providers/messaging/message_provider.dart';
import 'package:supplies_chat_app/core/providers/messaging/support_provider.dart';
import 'package:supplies_chat_app/domain/entity/auth/user_role.dart';
import 'package:supplies_chat_app/domain/entity/messaging/conversation_list_entry.dart';
import 'package:supplies_chat_app/presentation/pages/conversation_detail/conversation_detail_screen.dart';
import 'package:supplies_chat_app/presentation/shared/models/conversation_view_data.dart';
import 'package:supplies_chat_app/presentation/widgets/inbox/conversation_title.dart';
import 'package:supplies_chat_app/presentation/widgets/inbox/inbox_conversation_tile.dart';

import '../../helpers/test_environment.dart';

const _order = '01-ORD 1731600000000AB12CD';
const _longName =
    'Établissements Kodjo Mensah et Fils — Distribution Lomé Grand Marché';

class _StubQueue extends SupportQueue {
  _StubQueue(this.entries);
  final List<ConversationListEntry> entries;
  @override
  Future<List<ConversationListEntry>> build() async => entries;
}

class _EmptyThread extends Thread {
  @override
  Future<ThreadState> build(String conversationId) async =>
      const ThreadMessages([]);
  @override
  Future<void> markRead() async {}
}

Widget _app(Widget child, {Brightness brightness = Brightness.light}) =>
    ProviderScope(
      overrides: [appPlatformProvider.overrideWithValue(AppPlatform.android)],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        home: Builder(
          builder: (context) => Theme(
            data: brightness == Brightness.dark
                ? TAppTheme.darkThemeData(context)
                : TAppTheme.lightThemeData(context),
            child: Scaffold(body: child),
          ),
        ),
      ),
    );

/// The order label is shown (possibly shortened in the middle) and its
/// distinctive tail (at least four characters) is never cut.
void _expectOrderVisible(WidgetTester tester) {
  final finder = find.byKey(ConversationTitle.orderKey);
  expect(finder, findsOneWidget);
  final text = tester.widget<Text>(finder).data!;
  expect(text, startsWith('('));
  expect(text, endsWith('12CD)'));
  expect(_paragraph(tester, finder).didExceedMaxLines, isFalse);
}

RenderParagraph _paragraph(WidgetTester tester, Finder text) =>
    tester.renderObject<RenderParagraph>(
      find.descendant(of: text, matching: find.byType(RichText)),
    );

void main() {
  setUpAll(setUpTestEnvironment);

  group('ConversationTitle', () {
    testWidgets('order number follows the name, smaller and grey', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          const SizedBox(
            width: 360,
            child: ConversationTitle(
              name: 'Aline Kponton',
              orderNumber: _order,
              nameStyle: TextStyle(fontSize: 16, color: Colors.black),
            ),
          ),
        ),
      );

      expect(find.text('Aline Kponton'), findsOneWidget);
      _expectOrderVisible(tester);

      final name = tester.widget<Text>(find.byKey(ConversationTitle.nameKey));
      final order = tester.widget<Text>(find.byKey(ConversationTitle.orderKey));
      expect(order.style!.fontSize, lessThan(name.style!.fontSize!));
      expect(
        order.style!.color!.a,
        lessThan(1),
        reason: 'the order number is muted, the name is not',
      );
      expect(
        tester.getTopLeft(find.byKey(ConversationTitle.orderKey)).dx,
        greaterThan(
          tester.getTopRight(find.byKey(ConversationTitle.nameKey)).dx,
        ),
      );
    });

    testWidgets('a long name is ellipsized, the order number stays whole', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          const Center(
            child: SizedBox(
              key: ValueKey('box'),
              width: 300,
              child: ConversationTitle(
                name: _longName,
                orderNumber: '4821',
                nameStyle: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ),
      );

      final name = _paragraph(tester, find.byKey(ConversationTitle.nameKey));
      final order = _paragraph(tester, find.byKey(ConversationTitle.orderKey));
      expect(name.didExceedMaxLines, isTrue, reason: 'name is ellipsized');
      expect(order.didExceedMaxLines, isFalse, reason: 'order stays visible');
      expect(
        tester.getTopRight(find.byKey(ConversationTitle.orderKey)).dx,
        lessThanOrEqualTo(
          tester.getTopRight(find.byKey(const ValueKey('box'))).dx,
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('a long order number is shortened in the middle, keeping '
        'its distinctive tail', (tester) async {
      await tester.pumpWidget(
        _app(
          const Center(
            child: SizedBox(
              width: 220,
              child: ConversationTitle(
                name: _longName,
                orderNumber: _order,
                nameStyle: TextStyle(fontSize: 14),
                maxOrderShare: 0.5,
              ),
            ),
          ),
        ),
      );

      final order = tester.widget<Text>(find.byKey(ConversationTitle.orderKey));
      expect(order.data, contains('…'));
      expect(order.data, endsWith('12CD)'));
      expect(
        _paragraph(
          tester,
          find.byKey(ConversationTitle.orderKey),
        ).didExceedMaxLines,
        isFalse,
      );
    });

    test('fitOrderLabel keeps the full label when it fits', () {
      String format(String n) => '($n)';
      expect(
        ConversationTitle.fitOrderLabel(
          _order,
          format: format,
          style: const TextStyle(fontSize: 12),
          maxWidth: double.infinity,
        ),
        '($_order)',
      );
      expect(
        ConversationTitle.fitOrderLabel(
          '4821',
          format: format,
          style: const TextStyle(fontSize: 12),
          maxWidth: 400,
        ),
        '(4821)',
      );
    });

    testWidgets('without an order only the name is drawn', (tester) async {
      await tester.pumpWidget(
        _app(const ConversationTitle(name: 'Aline Kponton')),
      );
      expect(find.byKey(ConversationTitle.orderKey), findsNothing);
      expect(find.textContaining('('), findsNothing);
    });
  });

  group('InboxConversationTile', () {
    const base = ConversationListItemData(
      id: 'c1',
      name: _longName,
      preview: 'Bonjour, ma commande est-elle partie ?',
      timeLabel: '12:10',
      unreadCount: 3,
      peerRole: UserRole.client,
      orderNumber: _order,
    );

    for (final density in InboxDensity.values) {
      for (final brightness in Brightness.values) {
        testWidgets('${density.name} ${brightness.name}: name + order, '
            'time and badge fit', (tester) async {
          await tester.pumpWidget(
            _app(
              Center(
                child: SizedBox(
                  width: density == InboxDensity.desktop ? 320 : 390,
                  child: InboxConversationTile(
                    data: base,
                    density: density,
                    onTap: () {},
                  ),
                ),
              ),
              brightness: brightness,
            ),
          );

          expect(find.text(_longName), findsOneWidget);
          _expectOrderVisible(tester);
          expect(find.text('12:10'), findsOneWidget);
          expect(find.text('3'), findsOneWidget);
          final name = _paragraph(
            tester,
            find.byKey(ConversationTitle.nameKey),
          );
          expect(name.didExceedMaxLines, isTrue);
          expect(tester.takeException(), isNull);
        });
      }
    }

    testWidgets('row height does not depend on preview or ticket state', (
      tester,
    ) async {
      Future<double> height(ConversationListItemData data) async {
        await tester.pumpWidget(
          _app(
            Center(
              child: SizedBox(
                width: 390,
                child: InboxConversationTile(data: data, onTap: () {}),
              ),
            ),
          ),
        );
        return tester.getSize(find.byType(InboxConversationTile)).height;
      }

      final short = await height(
        const ConversationListItemData(
          id: 'a',
          name: 'A',
          preview: 'Ok',
          timeLabel: '09:00',
        ),
      );
      final claimed = await height(
        const ConversationListItemData(
          id: 'a',
          name: 'A',
          preview:
              'Un aperçu bien plus long qui occupe les deux lignes réservées '
              'à la ligne et déborde même au-delà de ce qui est affichable',
          timeLabel: '09:00',
          unreadCount: 12,
          orderNumber: _order,
          ticketState: InboxTicketState.assigned,
          assigneeName: 'Kodjo A.',
        ),
      );
      expect(claimed, short);
    });

    testWidgets('ticket ownership is rendered as a pill', (tester) async {
      Future<void> pumpState(InboxTicketState state, {String? assignee}) =>
          tester.pumpWidget(
            _app(
              InboxConversationTile(
                data: ConversationListItemData(
                  id: 'c',
                  name: 'Client',
                  preview: 'Bonjour',
                  timeLabel: '10:00',
                  ticketState: state,
                  assigneeName: assignee,
                ),
                density: InboxDensity.desktop,
                onTap: () {},
              ),
            ),
          );

      await pumpState(InboxTicketState.unclaimed);
      expect(find.text('Non assignée'), findsOneWidget);
      await pumpState(InboxTicketState.mine);
      expect(find.text('Vous'), findsOneWidget);
      await pumpState(InboxTicketState.assigned, assignee: 'Kodjo A.');
      expect(find.text('Kodjo A.'), findsOneWidget);
      await pumpState(InboxTicketState.assigned);
      expect(find.text('Assignée'), findsOneWidget);
      await pumpState(InboxTicketState.none);
      expect(find.byType(InboxTicketPill), findsNothing);
    });

    test('fromEntry derives ownership and keeps the order number', () {
      ConversationListItemData map(ConversationListEntry e) =>
          ConversationListItemData.fromEntry(
            e,
            timeLabel: '',
            currentUserId: 'me',
          );
      final now = DateTime(2026, 11, 14);
      final unclaimed = map(
        ConversationListEntry(
          conversationId: '1',
          title: 'A',
          preview: '',
          date: now,
          isSupport: true,
          isUnclaimed: true,
          orderNumber: _order,
        ),
      );
      expect(unclaimed.ticketState, InboxTicketState.unclaimed);
      expect(unclaimed.orderNumber, _order);
      expect(
        map(
          ConversationListEntry(
            conversationId: '2',
            title: 'A',
            preview: '',
            date: now,
            isSupport: true,
            assigneeId: 'me',
          ),
        ).ticketState,
        InboxTicketState.mine,
      );
      final other = map(
        ConversationListEntry(
          conversationId: '3',
          title: 'A',
          preview: '',
          date: now,
          isSupport: true,
          assigneeId: 'agent',
          assigneeName: 'Kodjo A.',
        ),
      );
      expect(other.ticketState, InboxTicketState.assigned);
      expect(other.assigneeName, 'Kodjo A.');
      expect(
        map(
          ConversationListEntry(
            conversationId: '4',
            title: 'A',
            preview: '',
            date: now,
          ),
        ).ticketState,
        InboxTicketState.none,
      );
    });
  });

  group('conversation header', () {
    Future<void> pumpHeader(WidgetTester tester, String? orderNumber) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appPlatformProvider.overrideWithValue(AppPlatform.ios),
            supportQueueProvider.overrideWith(
              () => _StubQueue([
                ConversationListEntry(
                  conversationId: 'c1',
                  title: _longName,
                  preview: 'Bonjour',
                  date: DateTime(2026, 11, 14),
                  isSupport: true,
                  ticketId: 't1',
                  orderNumber: orderNumber,
                ),
              ]),
            ),
            threadProvider('c1').overrideWith(_EmptyThread.new),
            currentUserIdProvider.overrideWithValue('me'),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('fr'),
            home: ConversationDetailScreen(
              conversationId: 'c1',
              contactName: _longName,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
    }

    testWidgets('shows the order number after an ellipsized, 16 pt name', (
      tester,
    ) async {
      await pumpHeader(tester, _order);

      final nameFinder = find.byKey(ConversationTitle.nameKey);
      final orderFinder = find.byKey(ConversationTitle.orderKey);
      expect(nameFinder, findsOneWidget);
      _expectOrderVisible(tester);

      final name = tester.widget<Text>(nameFinder);
      final order = tester.widget<Text>(orderFinder);
      expect(name.style!.fontSize, 16, reason: 'reduced from 17 pt');
      expect(order.style!.fontSize, lessThan(16));
      expect(order.style!.color!.a, lessThan(1));
      expect(_paragraph(tester, nameFinder).didExceedMaxLines, isTrue);
      expect(tester.getRect(orderFinder).right, lessThanOrEqualTo(390));
      expect(tester.takeException(), isNull);
    });

    testWidgets('without a linked order the header shows the name only', (
      tester,
    ) async {
      await pumpHeader(tester, null);
      expect(find.byKey(ConversationTitle.nameKey), findsOneWidget);
      expect(find.byKey(ConversationTitle.orderKey), findsNothing);
    });
  });
}
