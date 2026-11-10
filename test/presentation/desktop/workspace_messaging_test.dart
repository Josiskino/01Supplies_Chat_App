import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supplies_chat_app/core/l10n/generated/app_localizations.dart';
import 'package:supplies_chat_app/core/platform/app_platform.dart';
import 'package:supplies_chat_app/core/platform/platform_ui_provider.dart';
import 'package:supplies_chat_app/core/providers/messaging/message_provider.dart';
import 'package:supplies_chat_app/core/providers/messaging/pinned_provider.dart';
import 'package:supplies_chat_app/core/providers/messaging/support_provider.dart';
import 'package:supplies_chat_app/core/providers/realtime/realtime_provider.dart';
import 'package:supplies_chat_app/domain/entity/messaging/conversation_list_entry.dart';
import 'package:supplies_chat_app/presentation/desktop/desktop_workspace_shell.dart';
import 'package:supplies_chat_app/presentation/desktop/widgets/conversation_list_panel.dart';
import 'package:supplies_chat_app/presentation/pages/conversation_detail/conversation_detail_screen.dart';
import '../../helpers/test_environment.dart';

class StubQueue extends SupportQueue {
  final List<ConversationListEntry> entries;
  StubQueue(this.entries);
  @override
  Future<List<ConversationListEntry>> build() async => entries;
}

class StubPins extends PinnedConversations {
  @override
  Set<String> build() => {'old'};
}

class StubThread extends Thread {
  @override
  Future<ThreadState> build(String conversationId) async =>
      const ThreadMessages([]);
  @override
  Future<void> markRead() async {}
}

void main() {
  setUpAll(setUpTestEnvironment);
  final entries = [
    ConversationListEntry(
      conversationId: 'new',
      title: 'Real Customer',
      preview: 'Latest request',
      date: DateTime(2026, 2),
      ticketId: 'ticket',
      isSupport: true,
    ),
    ConversationListEntry(
      conversationId: 'old',
      title: 'Real Driver',
      preview: 'Direct exchange',
      date: DateTime(2026, 1),
    ),
  ];
  Future<void> pump(
    WidgetTester tester,
    List<ConversationListEntry> entries,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appPlatformProvider.overrideWithValue(AppPlatform.windows),
          supportQueueProvider.overrideWith(() => StubQueue(entries)),
          pinnedConversationsProvider.overrideWith(StubPins.new),
          for (final entry in entries) ...[
            threadProvider(entry.conversationId).overrideWith(StubThread.new),
            typingUsersProvider(
              entry.conversationId,
            ).overrideWith((ref) => Stream.value({})),
            conversationPresenceProvider(
              entry.conversationId,
            ).overrideWith((ref) => Stream.value({})),
          ],
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('fr'),
          home: Scaffold(body: DesktopWorkspaceShell()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets(
    'desktop uses real queue, pins, shared thread and truthful profile',
    (tester) async {
      await pump(tester, entries);
      final list = tester.widget<ConversationListPanel>(
        find.byType(ConversationListPanel),
      );
      expect(list.conversations.map((c) => c.id), ['old', 'new']);
      expect(find.byType(ConversationDetailScreen), findsNothing);
      await tester.tap(find.text('Real Customer').first);
      await tester.pump();
      await tester.pump();
      expect(
        tester
            .widget<ConversationDetailScreen>(
              find.byType(ConversationDetailScreen),
            )
            .conversationId,
        'new',
      );
      expect(find.textContaining('@exemple.com'), findsNothing);
      expect(find.text('+228 90 11 20 31'), findsNothing);
    },
  );
  testWidgets('empty inbox never renders fixture conversations or messages', (
    tester,
  ) async {
    await pump(tester, []);
    expect(find.text('Awa Traoré'), findsNothing);
    expect(find.byType(ConversationDetailScreen), findsNothing);
    expect(find.text('Aucune conversation'), findsOneWidget);
  });
}
