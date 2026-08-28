import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supplies_chat_app/core/l10n/generated/app_localizations.dart';
import 'package:supplies_chat_app/core/platform/app_platform.dart';
import 'package:supplies_chat_app/core/platform/platform_ui_provider.dart';
import 'package:supplies_chat_app/presentation/pages/settings/settings_screen.dart';
import 'package:supplies_chat_app/presentation/pages/settings/widgets/settings_group.dart';

import '../../helpers/test_environment.dart';

/// Couvre l'écran de réglages.
void main() {
  setUpAll(() {
    setUpTestEnvironment();
  });

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(402, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appPlatformProvider.overrideWithValue(AppPlatform.ios)],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('fr'),
          home: SettingsScreen(),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('les réglages sont réunis en groupes', (tester) async {
    await pump(tester);
    // Le regroupement porte le sens à la place des titres de section.
    expect(find.byType(SettingsGroup), findsAtLeastNWidgets(3));
  });

  testWidgets('thème et langue montrent leur valeur courante', (tester) async {
    await pump(tester);

    // Une ligne de réglage doit dire où l'on en est sans avoir à l'ouvrir.
    expect(find.text('Thème'), findsOneWidget);
    expect(find.text('Système'), findsOneWidget);
    expect(find.text('Langue'), findsOneWidget);
    expect(find.text('Français'), findsOneWidget);
  });

  testWidgets('la déconnexion est signalée comme destructive', (tester) async {
    await pump(tester);

    final row = tester.widget<SettingsRow>(
      find.ancestor(
        of: find.text('Se déconnecter'),
        matching: find.byType(SettingsRow),
      ),
    );
    expect(row.isDestructive, isTrue);
  });

  testWidgets('l’environnement reste affiché en clair', (tester) async {
    await pump(tester);
    // Sans ce repère, rien ne distingue une app de recette de la production.
    expect(find.textContaining('01 Chat Dev'), findsOneWidget);
  });
}
