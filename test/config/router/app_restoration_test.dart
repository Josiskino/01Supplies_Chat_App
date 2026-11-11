import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supplies_chat_app/config/router/app_router.dart';
import 'package:supplies_chat_app/core/auth/auth_gate.dart';
import 'package:supplies_chat_app/core/l10n/generated/app_localizations.dart';
import 'package:supplies_chat_app/core/platform/app_platform.dart';
import 'package:supplies_chat_app/core/platform/platform_ui_provider.dart';
import 'package:supplies_chat_app/core/providers/auth/auth_status_provider.dart';
import 'package:supplies_chat_app/core/providers/directory/directory_provider.dart';
import 'package:supplies_chat_app/core/providers/messaging/support_provider.dart';
import 'package:supplies_chat_app/core/providers/navigation/main_tab_provider.dart';
import 'package:supplies_chat_app/core/providers/splash_completed_provider.dart';
import 'package:supplies_chat_app/domain/entity/auth/user_entity.dart';
import 'package:supplies_chat_app/domain/entity/messaging/conversation_list_entry.dart';
import 'package:supplies_chat_app/presentation/main/main_page.dart';
import 'package:supplies_chat_app/presentation/pages/settings/settings_screen.dart';
import 'package:supplies_chat_app/presentation/pages/conversation_detail/widgets/message_composer.dart';
import '../../helpers/test_environment.dart';

class _Session extends AuthStatusNotifier {
  @override
  AuthGateStatus build() => AuthGateStatus.initial;
  void ready() => state = AuthGateStatus.authenticated;
}

class _Splash extends SplashCompletedNotifier {
  @override
  bool build() => true;
}

class _Queue extends SupportQueue {
  @override
  Future<List<ConversationListEntry>> build() async => [];
}

class _Contacts extends Contacts {
  @override
  Future<List<UserEntity>> build() async => [];
}

class _Harness extends StatefulWidget {
  const _Harness();
  static late ProviderContainer container;
  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  late final ProviderContainer container;
  @override
  void initState() {
    super.initState();
    container = ProviderContainer(
      overrides: [
        authStatusProvider.overrideWith(_Session.new),
        splashCompletedProvider.overrideWith(_Splash.new),
        supportQueueProvider.overrideWith(_Queue.new),
        contactsProvider.overrideWith(_Contacts.new),
        appPlatformProvider.overrideWithValue(AppPlatform.android),
      ],
    );
    _Harness.container = container;
  }

  @override
  void dispose() {
    container.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(
      restorationScopeId: '01chat-app',
      routerConfig: container.read(appRouterProvider),
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

void main() {
  setUpAll(setUpTestEnvironment);
  testWidgets(
    'actual router restores pushed stack and tab through initial authentication',
    (tester) async {
      await tester.pumpWidget(const _Harness());
      final container = _Harness.container;
      final router = container.read(appRouterProvider);
      router.go('/main');
      (container.read(authStatusProvider.notifier) as _Session).ready();
      await tester.pumpAndSettle();
      container.read(mainTabProvider.notifier).select(2);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Ada');
      router.push('/settings');
      await tester.pumpAndSettle();
      expect(router.canPop(), isTrue);
      await tester.restartAndRestore();
      final restored = _Harness.container;
      final restoredRouter = restored.read(appRouterProvider);
      expect(restoredRouter.canPop(), isTrue);
      expect(find.byType(SettingsScreen), findsNothing);
      (restored.read(authStatusProvider.notifier) as _Session).ready();
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);
      restoredRouter.pop();
      await tester.pumpAndSettle();
      expect(find.byType(MainPage), findsOneWidget);
      expect(restored.read(mainTabProvider), 2);
      expect(
        tester.widget<TextField>(find.byType(TextField).first).controller?.text,
        'Ada',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('unsent composer draft restores without sending', (tester) async {
    var sends = 0;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          restorationScopeId: 'draft-test',
          home: Scaffold(
            body: MessageComposer(
              restorationId: 'account-a-conversation-c',
              onSend: (_) async {
                sends++;
                return true;
              },
            ),
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), 'Unsent draft');
    await tester.pump();
    await tester.restartAndRestore();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      'Unsent draft',
    );
    expect(sends, 0);
  });
}
