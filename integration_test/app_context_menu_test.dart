import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supplies_chat_app/app.dart';
import 'package:supplies_chat_app/flavors.dart';

/// Appui long dans l'**application complète** : `AdaptiveApp.router` + GoRouter.
///
/// C'est le seul niveau où `CupertinoContextMenu` pousse sa route sur le Navigator
/// racine de GoRouter, comme en production. Les tests précédents montaient un
/// `CupertinoApp` nu et ne pouvaient donc pas révéler un conflit de navigation.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    FlavorConfig.flavor = Flavor.development;
    await dotenv.load(fileName: '.env.development');
    // Session ouverte : sans jeton, le routeur reste sur l'écran de connexion et
    // la liste n'est jamais atteinte.
    SharedPreferences.setMockInitialValues({'token': 'test-token'});
  });

  testWidgets('appui long sur une conversation dans l\'app réelle', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));

    // Le splash tient l'affichage avant de laisser le routeur trancher.
    await tester.pumpAndSettle(const Duration(seconds: 3));

    final target = find.text('Kofi Adjei');
    expect(
      target,
      findsWidgets,
      reason: 'la liste de conversations doit être atteinte',
    );

    await tester.longPress(target.first);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
