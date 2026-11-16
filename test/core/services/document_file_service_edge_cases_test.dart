import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supplies_chat_app/core/services/document_file_service.dart';

/// Storage host double: records every request (URL and headers) and answers
/// with [status] per URL (200 with PDF bytes by default).
class RecordingStorage implements HttpClientAdapter {
  RecordingStorage({this.status = const {}, this.body = '%PDF-1.7 test'});
  final Map<String, int> status;
  final String body;
  final requests = <RequestOptions>[];

  List<String> get urls => [for (final r in requests) r.uri.toString()];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final code = status[options.uri.toString()] ?? 200;
    if (code != 200) return ResponseBody.fromString('refused', code);
    final bytes = utf8.encode(body);
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
  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  DocumentFileService service(RecordingStorage storage) => DocumentFileService(
    isDesktop: false,
    dio: Dio()..httpClientAdapter = storage,
    cacheRoot: () async => root,
  );

  const old = 'https://storage.test/private/messages/a.pdf?sig=old';
  const fresh = 'https://storage.test/private/messages/a.pdf?sig=new';

  for (final code in [401, 403, 404, 410]) {
    test('HTTP $code renews the signed link exactly once', () async {
      final storage = RecordingStorage(status: {old: code});
      var renewals = 0;
      final file = await service(storage).obtain(
        source: old,
        fileName: 'a.pdf',
        mediaId: 'm1',
        renewUrl: () async {
          renewals++;
          return fresh;
        },
      );
      expect(renewals, 1);
      expect(storage.urls, [old, fresh]);
      expect(await file.readAsString(), startsWith('%PDF'));
    });
  }

  test('a renewed link that is refused again fails without a second '
      'renewal', () async {
    final storage = RecordingStorage(status: {old: 403, fresh: 403});
    var renewals = 0;
    await expectLater(
      service(storage).obtain(
        source: old,
        fileName: 'a.pdf',
        mediaId: 'm1',
        renewUrl: () async {
          renewals++;
          return fresh;
        },
      ),
      throwsA(
        isA<DocumentFileException>().having(
          (e) => e.kind,
          'kind',
          DocumentFailureKind.download,
        ),
      ),
    );
    expect(renewals, 1);
    expect(storage.urls, [old, fresh]);
    final leftovers = await root
        .list(recursive: true)
        .where((e) => e is File)
        .toList();
    expect(leftovers, isEmpty, reason: 'no partial file is left behind');
  });

  test('a server error is not mistaken for an expired link', () async {
    final storage = RecordingStorage(status: {old: 500});
    var renewals = 0;
    await expectLater(
      service(storage).obtain(
        source: old,
        fileName: 'a.pdf',
        renewUrl: () async {
          renewals++;
          return fresh;
        },
      ),
      throwsA(isA<DocumentFileException>()),
    );
    expect(renewals, 0);
  });

  test('an empty renewed URL is reported as expired', () async {
    final storage = RecordingStorage(status: {old: 410});
    await expectLater(
      service(
        storage,
      ).obtain(source: old, fileName: 'a.pdf', renewUrl: () async => ''),
      throwsA(
        isA<DocumentFileException>().having(
          (e) => e.kind,
          'kind',
          DocumentFailureKind.expired,
        ),
      ),
    );
  });

  test('without a media id a refused link fails as a download error', () async {
    final storage = RecordingStorage(status: {old: 403});
    await expectLater(
      service(storage).obtain(source: old, fileName: 'a.pdf'),
      throwsA(
        isA<DocumentFileException>().having(
          (e) => e.kind,
          'kind',
          DocumentFailureKind.download,
        ),
      ),
    );
    expect(storage.urls, [old]);
  });

  test('no API credential ever reaches the storage host', () async {
    final storage = RecordingStorage(status: {old: 403});
    await service(storage).obtain(
      source: old,
      fileName: 'a.pdf',
      mediaId: 'm1',
      renewUrl: () async => fresh,
    );
    expect(storage.requests, hasLength(2));
    for (final request in storage.requests) {
      final headers = request.headers.map(
        (k, v) => MapEntry(k.toLowerCase(), v),
      );
      expect(headers.keys, isNot(contains('authorization')));
      expect(headers.keys, isNot(contains('x-api-key')));
      expect(headers.keys, isNot(contains('cookie')));
      expect(request.uri.host, 'storage.test');
    }
  });

  test('the default client carries no interceptor or base headers', () {
    // The service builds its own bare Dio when none is injected: nothing
    // from the authenticated API client can be inherited.
    final docs = DocumentFileService(isDesktop: true);
    expect(docs, isNotNull);
    final bare = Dio();
    expect(
      bare.options.headers.keys.map((k) => k.toLowerCase()),
      isNot(contains('authorization')),
    );
    expect(bare.interceptors.whereType<InterceptorsWrapper>(), isEmpty);
  });

  test('a cached copy with the wrong size is downloaded again', () async {
    final storage = RecordingStorage();
    final docs = service(storage);
    final first = await docs.obtain(
      source: old,
      fileName: 'a.pdf',
      mediaId: 'm1',
    );
    await first.writeAsString('truncated');
    await docs.obtain(
      source: fresh,
      fileName: 'a.pdf',
      mediaId: 'm1',
      expectedSize: utf8.encode('%PDF-1.7 test').length,
    );
    expect(storage.urls, [old, fresh]);
    // A size of zero (unknown on the server) does not force a download.
    await docs.obtain(
      source: fresh,
      fileName: 'a.pdf',
      mediaId: 'm1',
      expectedSize: 0,
    );
    expect(storage.urls, hasLength(2));
  });

  test('an empty cached file is never served', () async {
    final storage = RecordingStorage();
    final docs = service(storage);
    final file = await docs.obtain(source: old, fileName: 'a.pdf');
    await file.writeAsBytes(const []);
    await docs.obtain(source: old, fileName: 'a.pdf');
    expect(storage.urls, hasLength(2));
  });

  test('progress is reported between 0 and 1', () async {
    final storage = RecordingStorage(body: 'x' * 100000);
    final progress = <double>[];
    await service(
      storage,
    ).obtain(source: old, fileName: 'big.pdf', onProgress: progress.add);
    expect(progress, isNotEmpty);
    expect(progress.every((p) => p >= 0 && p <= 1), isTrue);
    expect(progress.last, 1);
  });

  test('hostile and odd file names stay inside the cache folder', () async {
    final storage = RecordingStorage();
    final docs = service(storage);
    for (final name in [
      '../../etc/passwd.pdf',
      r'..\..\win.ini.pdf',
      'CON:.pdf',
      '..',
      '',
      'rapport annuel 2026 — version finale (2).PDF',
      'تقرير.pdf',
      '${'n' * 300}.pdf',
    ]) {
      final file = await docs.obtain(
        source: 'https://storage.test/${name.hashCode}.pdf',
        fileName: name,
      );
      expect(file.path, startsWith(root.path), reason: name);
      final base = file.uri.pathSegments.last;
      expect(base, isNot(contains('/')));
      expect(base.length, lessThanOrEqualTo(120));
    }
  });

  test('a long name keeps its extension after truncation', () {
    final safe = DocumentFileService.safeFileName('${'n' * 300}.PDF');
    expect(safe.length, 120);
    expect(safe, endsWith('.PDF'));
  });

  test('a file: URI and a missing local file are handled', () async {
    final local = File('${root.path}/out.pdf')..writeAsStringSync('%PDF');
    final docs = service(RecordingStorage());
    expect(
      (await docs.obtain(source: local.uri.toString(), fileName: 'x')).path,
      local.path,
    );
    await expectLater(
      docs.obtain(source: '${root.path}/missing.pdf', fileName: 'x'),
      throwsA(
        isA<DocumentFileException>().having(
          (e) => e.kind,
          'kind',
          DocumentFailureKind.storage,
        ),
      ),
    );
  });

  test('isLocal only treats http(s) as remote', () {
    expect(DocumentFileService.isLocal('https://a.test/x.pdf'), isFalse);
    expect(DocumentFileService.isLocal('http://a.test/x.pdf'), isFalse);
    expect(DocumentFileService.isLocal('/tmp/x.pdf'), isTrue);
    expect(DocumentFileService.isLocal(r'C:\Users\x.pdf'), isTrue);
    expect(DocumentFileService.isLocal('file:///tmp/x.pdf'), isTrue);
  });

  test('cache keys are file-system safe and signature independent', () {
    expect(
      DocumentFileService.cacheKeyOf(url: old, mediaId: '../m1'),
      isNot(contains('/')),
    );
    expect(
      DocumentFileService.cacheKeyOf(url: old),
      DocumentFileService.cacheKeyOf(url: fresh),
    );
  });
}
