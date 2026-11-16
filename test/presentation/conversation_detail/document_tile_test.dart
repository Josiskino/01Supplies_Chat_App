import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supplies_chat_app/core/l10n/generated/app_localizations.dart';
import 'package:supplies_chat_app/presentation/pages/conversation_detail/widgets/chat_bubble.dart';
import 'package:supplies_chat_app/presentation/pages/conversation_detail/widgets/document_tile.dart';
import 'package:supplies_chat_app/presentation/pages/conversation_detail/widgets/photo_stack.dart';
import 'package:supplies_chat_app/presentation/shared/models/conversation_view_data.dart';

const _pdf = ChatDocumentData(
  name: 'facture-1042.pdf',
  source: 'https://cdn.example.com/abc.pdf?sig=1',
  mediaId: 'm1',
  sizeBytes: 1468006,
  mimeType: 'application/pdf',
);

Widget _host(Widget child, {Locale locale = const Locale('fr')}) => MaterialApp(
  locale: locale,
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('shows name, readable size and PDF badge', (tester) async {
    await tester.pumpWidget(
      _host(const DocumentTile(document: _pdf, foreground: Colors.black)),
    );
    expect(find.text('facture-1042.pdf'), findsOneWidget);
    expect(find.text('1,4 Mo · PDF'), findsOneWidget);
    expect(find.text('PDF'), findsOneWidget);
  });

  testWidgets('tap downloads with visible progress then opens', (tester) async {
    final done = Completer<bool>();
    ValueChanged<double>? report;
    ChatDocumentData? opened;
    await tester.pumpWidget(
      _host(
        DocumentTile(
          document: _pdf,
          foreground: Colors.black,
          onOpen: (document, onProgress) {
            opened = document;
            report = onProgress;
            return done.future;
          },
        ),
      ),
    );

    await tester.tap(find.text('facture-1042.pdf'));
    await tester.pump();
    expect(opened, same(_pdf));
    report!(0.42);
    await tester.pump();
    expect(find.text('Téléchargement… 42 %'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    done.complete(true);
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('1,4 Mo · PDF'), findsOneWidget);
  });

  testWidgets('a failed download offers a retry', (tester) async {
    var attempts = 0;
    await tester.pumpWidget(
      _host(
        DocumentTile(
          document: _pdf,
          foreground: Colors.black,
          onOpen: (_, _) async {
            attempts++;
            return false;
          },
        ),
        locale: const Locale('en'),
      ),
    );
    await tester.tap(find.text('facture-1042.pdf'));
    await tester.pumpAndSettle();
    expect(find.text('Retry'), findsOneWidget);
    await tester.tap(find.text('facture-1042.pdf'));
    await tester.pumpAndSettle();
    expect(attempts, 2);
  });

  testWidgets('an unavailable document cannot be opened', (tester) async {
    var attempts = 0;
    await tester.pumpWidget(
      _host(
        DocumentTile(
          document: const ChatDocumentData(
            name: 'gone.pdf',
            source: '',
            unavailable: true,
          ),
          foreground: Colors.black,
          onOpen: (_, _) async {
            attempts++;
            return true;
          },
        ),
      ),
    );
    expect(find.text('Fichier indisponible'), findsOneWidget);
    await tester.tap(find.text('gone.pdf'));
    await tester.pumpAndSettle();
    expect(attempts, 0);
  });

  testWidgets('an outgoing document shows its upload progress', (tester) async {
    final progress = ValueNotifier<double>(0.3);
    addTearDown(progress.dispose);
    await tester.pumpWidget(
      _host(
        DocumentTile(
          document: _pdf,
          foreground: Colors.black,
          isUploading: true,
          uploadProgress: progress,
        ),
        locale: const Locale('en'),
      ),
    );
    expect(find.text('Uploading… 30%'), findsOneWidget);
    progress.value = 0.8;
    await tester.pump();
    expect(find.text('Uploading… 80%'), findsOneWidget);
  });

  testWidgets('desktop offers to save a copy', (tester) async {
    var saved = 0;
    await tester.pumpWidget(
      _host(
        DocumentTile(
          document: _pdf,
          foreground: Colors.black,
          onSave: (_, _) async {
            saved++;
            return true;
          },
        ),
      ),
    );
    await tester.tap(find.byTooltip('Enregistrer une copie…'));
    await tester.pumpAndSettle();
    expect(saved, 1);
  });

  testWidgets('a document message renders a tile inside the bubble', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const ChatBubble(
          message: ChatMessageData(
            id: 'm1',
            text: '',
            timeLabel: '10:00',
            isMine: false,
            documents: [_pdf],
          ),
          isFirstOfGroup: true,
          isLastOfGroup: true,
        ),
      ),
    );
    expect(find.byType(DocumentTile), findsOneWidget);
    expect(find.byType(PhotoStack), findsNothing);
    expect(find.text('10:00'), findsOneWidget);
  });
}
