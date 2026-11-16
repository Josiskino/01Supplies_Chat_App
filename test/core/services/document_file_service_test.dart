import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supplies_chat_app/core/services/document_file_service.dart';

/// Serves `%PDF` bytes, except for URLs listed in [refused].
class FakeStorage implements HttpClientAdapter {
  FakeStorage({this.refused = const {}});
  final Set<String> refused;
  final requested = <String>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requested.add(options.uri.toString());
    if (refused.contains(options.uri.toString())) {
      return ResponseBody.fromString('expired', 403);
    }
    final bytes = utf8.encode('%PDF-1.7 test');
    return ResponseBody.fromBytes(
      bytes,
      200,
      headers: {
        Headers.contentLengthHeader: ['${bytes.length}'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late Directory root;
  setUp(() async => root = await Directory.systemTemp.createTemp('docs'));
  tearDown(() async => root.delete(recursive: true));

  DocumentFileService service(FakeStorage storage) => DocumentFileService(
    isDesktop: true,
    dio: Dio()..httpClientAdapter = storage,
    cacheRoot: () async => root,
  );

  test('downloads under the original name and reports progress', () async {
    final storage = FakeStorage();
    final progress = <double>[];
    final file = await service(storage).obtain(
      source: 'https://cdn.test/abc.pdf?sig=1',
      fileName: 'facture.pdf',
      mediaId: 'm1',
      onProgress: progress.add,
    );
    expect(file.path, endsWith('${Platform.pathSeparator}facture.pdf'));
    expect(await file.readAsString(), startsWith('%PDF'));
    expect(progress.last, 1);
  });

  test('a second open reuses the cached copy', () async {
    final storage = FakeStorage();
    final docs = service(storage);
    await docs.obtain(source: 'https://cdn.test/a.pdf', fileName: 'a.pdf');
    await docs.obtain(
      source: 'https://cdn.test/a.pdf?sig=2',
      fileName: 'a.pdf',
    );
    expect(storage.requested, hasLength(1));
  });

  test('an expired signed link is renewed once through the media id', () async {
    final storage = FakeStorage(refused: {'https://cdn.test/a.pdf?sig=old'});
    var renewals = 0;
    final file = await service(storage).obtain(
      source: 'https://cdn.test/a.pdf?sig=old',
      fileName: 'a.pdf',
      mediaId: 'm1',
      renewUrl: () async {
        renewals++;
        return 'https://cdn.test/a.pdf?sig=new';
      },
    );
    expect(renewals, 1);
    expect(await file.exists(), isTrue);
  });

  test('an expired link without renewal fails with a typed error', () async {
    final storage = FakeStorage(refused: {'https://cdn.test/a.pdf'});
    await expectLater(
      service(storage).obtain(
        source: 'https://cdn.test/a.pdf',
        fileName: 'a.pdf',
        renewUrl: () async => null,
      ),
      throwsA(
        isA<DocumentFileException>().having(
          (e) => e.kind,
          'kind',
          DocumentFailureKind.expired,
        ),
      ),
    );
  });

  test('a local outgoing file is returned without any download', () async {
    final local = File('${root.path}/out.pdf')..writeAsStringSync('%PDF');
    final storage = FakeStorage();
    final file = await service(
      storage,
    ).obtain(source: local.path, fileName: 'out.pdf');
    expect(file.path, local.path);
    expect(storage.requested, isEmpty);
  });
}
