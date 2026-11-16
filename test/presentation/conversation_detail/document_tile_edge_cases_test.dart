import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart' show XFile;
import 'package:supplies_chat_app/config/theme/theme.dart';
import 'package:supplies_chat_app/core/l10n/generated/app_localizations.dart';
import 'package:supplies_chat_app/core/platform/app_platform.dart';
import 'package:supplies_chat_app/core/platform/platform_ui_provider.dart';
import 'package:supplies_chat_app/presentation/pages/conversation_detail/widgets/chat_bubble.dart';
import 'package:supplies_chat_app/presentation/pages/conversation_detail/widgets/document_tile.dart';
import 'package:supplies_chat_app/presentation/pages/conversation_detail/widgets/message_composer.dart';
import 'package:supplies_chat_app/presentation/pages/conversation_detail/widgets/photo_stack.dart';
import 'package:supplies_chat_app/presentation/shared/models/conversation_view_data.dart';

import '../../helpers/test_environment.dart';

const _mib = 1024 * 1024;
const _longName =
    'Bon de commande fournisseur — Établissements Kodjo Mensah et Fils — '
    'Lomé Grand Marché — novembre 2026 — version définitive signée.pdf';

ChatDocumentData _doc({
  String name = 'facture.pdf',
  int? size = 1468006,
  String? mime = 'application/pdf',
  bool unavailable = false,
}) => ChatDocumentData(
  name: name,
  source: 'https://storage.test/a.pdf?sig=1',
  mediaId: 'm1',
  sizeBytes: size,
  mimeType: mime,
  unavailable: unavailable,
);

Widget _host(
  Widget child, {
  Locale locale = const Locale('fr'),
  Brightness brightness = Brightness.light,
  double textScale = 1,
  TextDirection? direction,
  double width = 280,
}) => MaterialApp(
  locale: locale,
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: Builder(
    builder: (context) {
      Widget body = MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: Scaffold(
          body: Center(
            child: SizedBox(width: width, child: child),
          ),
        ),
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
);

void main() {
  setUpAll(setUpTestEnvironment);

  group('sizes', () {
    for (final (size, fr, en) in [
      (0, 'PDF', 'PDF'),
      (null, 'PDF', 'PDF'),
      (512, '512 o · PDF', '512 B · PDF'),
      ((49.9 * _mib).round(), '49,9 Mo · PDF', '49.9 MB · PDF'),
      (50 * _mib, '50 Mo · PDF', '50 MB · PDF'),
      (50 * _mib + 1, '50 Mo · PDF', '50 MB · PDF'),
    ]) {
      testWidgets('$size bytes', (tester) async {
        await tester.pumpWidget(
          _host(
            DocumentTile(
              document: _doc(size: size),
              foreground: Colors.black,
            ),
          ),
        );
        // Without a size, the details line is the badge alone.
        final count = size == null || size == 0 ? 2 : 1;
        expect(find.text(fr), findsNWidgets(count));
        await tester.pumpWidget(
          _host(
            DocumentTile(
              document: _doc(size: size),
              foreground: Colors.black,
            ),
            locale: const Locale('en'),
          ),
        );
        expect(find.text(en), findsNWidgets(count));
      });
    }
  });

  group('layout', () {
    for (final brightness in Brightness.values) {
      for (final direction in TextDirection.values) {
        for (final width in [200.0, 320.0, 560.0]) {
          testWidgets('${brightness.name} ${direction.name} $width px x1.3: '
              'a very long name ellipsizes without overflow', (tester) async {
            await tester.pumpWidget(
              _host(
                DocumentTile(
                  document: _doc(name: _longName),
                  foreground: brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                  onOpen: (_, _) async => true,
                  onSave: (_, _) async => true,
                ),
                brightness: brightness,
                direction: direction,
                width: width,
                textScale: 1.3,
              ),
            );
            expect(tester.takeException(), isNull);
            expect(find.text(_longName), findsOneWidget);
            final tile = tester.getRect(find.byType(DocumentTile));
            expect(tile.width, lessThanOrEqualTo(width));
          });
        }
      }
    }
  });

  group('badges', () {
    testWidgets('uppercase extension, missing extension and unknown MIME', (
      tester,
    ) async {
      for (final (name, mime, badge) in [
        ('RAPPORT.DOCX', null, 'DOCX'),
        ('tableau.Xlsx', null, 'XLSX'),
        ('scan', 'application/pdf', 'PDF'),
        ('export', null, 'FILE'),
        ('devis.pdf', 'application/octet-stream', 'PDF'),
      ]) {
        await tester.pumpWidget(
          _host(
            DocumentTile(
              document: _doc(name: name, mime: mime, size: null),
              foreground: Colors.black,
            ),
          ),
        );
        expect(find.text(badge), findsWidgets, reason: name);
      }
    });
  });

  group('states', () {
    testWidgets('unavailable: no tap, no save, explicit label (en)', (
      tester,
    ) async {
      var calls = 0;
      await tester.pumpWidget(
        _host(
          DocumentTile(
            document: _doc(unavailable: true),
            foreground: Colors.black,
            onOpen: (_, _) async {
              calls++;
              return true;
            },
            onSave: (_, _) async {
              calls++;
              return true;
            },
          ),
          locale: const Locale('en'),
        ),
      );
      expect(find.text('File unavailable'), findsOneWidget);
      expect(find.byTooltip('Save a copy…'), findsNothing);
      await tester.tap(find.byType(DocumentTile));
      await tester.pump();
      expect(calls, 0);
    });

    testWidgets('uploading: no save button and taps are ignored', (
      tester,
    ) async {
      var calls = 0;
      final progress = ValueNotifier<double>(0);
      addTearDown(progress.dispose);
      await tester.pumpWidget(
        _host(
          DocumentTile(
            document: _doc(),
            foreground: Colors.black,
            isUploading: true,
            uploadProgress: progress,
            onOpen: (_, _) async {
              calls++;
              return true;
            },
            onSave: (_, _) async => true,
          ),
        ),
      );
      expect(find.text('Envoi… 0 %'), findsOneWidget);
      expect(
        tester
            .widget<CircularProgressIndicator>(
              find.byType(CircularProgressIndicator),
            )
            .value,
        isNull,
        reason: 'indeterminate until the first byte',
      );
      expect(find.byTooltip('Enregistrer une copie…'), findsNothing);
      progress.value = 1;
      await tester.pump();
      expect(find.text('Envoi… 100 %'), findsOneWidget);
      await tester.tap(find.byType(DocumentTile));
      await tester.pump();
      expect(calls, 0);
    });

    testWidgets('a second tap while downloading does not start a second '
        'download', (tester) async {
      final done = Completer<bool>();
      var calls = 0;
      await tester.pumpWidget(
        _host(
          DocumentTile(
            document: _doc(),
            foreground: Colors.black,
            onOpen: (_, _) {
              calls++;
              return done.future;
            },
          ),
        ),
      );
      await tester.tap(find.byType(DocumentTile));
      await tester.pump();
      await tester.tap(find.byType(DocumentTile));
      await tester.pump();
      expect(calls, 1);
      done.complete(true);
      await tester.pumpAndSettle();
    });

    testWidgets('a throwing action becomes a retry, and a retry succeeds', (
      tester,
    ) async {
      var attempts = 0;
      await tester.pumpWidget(
        _host(
          DocumentTile(
            document: _doc(),
            foreground: Colors.black,
            onOpen: (_, _) async {
              attempts++;
              if (attempts == 1) throw StateError('boom');
              return true;
            },
          ),
          locale: const Locale('en'),
        ),
      );
      await tester.tap(find.byType(DocumentTile));
      await tester.pumpAndSettle();
      expect(find.text('Retry'), findsOneWidget);
      await tester.tap(find.byType(DocumentTile));
      await tester.pumpAndSettle();
      expect(attempts, 2);
      expect(find.text('Retry'), findsNothing);
      expect(find.text('1.4 MB · PDF'), findsOneWidget);
    });

    testWidgets('disposing mid-download does not throw', (tester) async {
      final done = Completer<bool>();
      ValueChanged<double>? report;
      await tester.pumpWidget(
        _host(
          DocumentTile(
            document: _doc(),
            foreground: Colors.black,
            onOpen: (_, onProgress) {
              report = onProgress;
              return done.future;
            },
          ),
        ),
      );
      await tester.tap(find.byType(DocumentTile));
      await tester.pump();
      await tester.pumpWidget(_host(const SizedBox()));
      report!(0.5);
      done.complete(false);
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('bubble', () {
    testWidgets('a caption is shown with the document, photos stay apart', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          ChatBubble(
            message: ChatMessageData(
              id: 'm',
              text: 'Voici le devis signé',
              timeLabel: '10:00',
              isMine: true,
              documents: [
                _doc(),
                _doc(name: 'annexe.xlsx', mime: null),
              ],
            ),
            isFirstOfGroup: true,
            isLastOfGroup: true,
          ),
          width: 390,
        ),
      );
      expect(find.byType(DocumentTile), findsNWidgets(2));
      expect(
        find.textContaining('Voici le devis signé', findRichText: true),
        findsOneWidget,
      );
      expect(find.byType(PhotoStack), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('composer', () {
    Future<void> openSheet(
      WidgetTester tester,
      AppPlatform platform, {
      ValueChanged<XFile>? onPickDocument,
    }) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [appPlatformProvider.overrideWithValue(platform)],
          child: MaterialApp(
            locale: const Locale('fr'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: Scaffold(
              body: Align(
                alignment: Alignment.bottomCenter,
                child: MessageComposer(
                  onSend: (_) async => true,
                  onPickImages: (_) {},
                  onPickDocument: onPickDocument,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byTooltip('Ajouter une pièce jointe'));
      await tester.pumpAndSettle();
    }

    testWidgets('android offers Document after the photo sources', (
      tester,
    ) async {
      await openSheet(tester, AppPlatform.android, onPickDocument: (_) {});
      expect(find.text('Photothèque'), findsOneWidget);
      expect(find.text('Document'), findsOneWidget);
    });

    testWidgets('desktop offers images and a document', (tester) async {
      await openSheet(tester, AppPlatform.macos, onPickDocument: (_) {});
      expect(find.text('Choisir des images'), findsOneWidget);
      expect(find.text('Choisir un document'), findsOneWidget);
    });

    testWidgets('no document entry when sending documents is not wired', (
      tester,
    ) async {
      await openSheet(tester, AppPlatform.android);
      expect(find.text('Photothèque'), findsOneWidget);
      expect(find.text('Document'), findsNothing);
    });
  });
}
