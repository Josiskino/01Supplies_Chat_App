import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_selector/file_selector.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utils/app_logger.dart';

/// Why a document could not be downloaded, opened or saved.
enum DocumentFailureKind {
  /// Network error or server refusal while downloading.
  download,

  /// The signed link expired and no fresh one could be obtained.
  expired,

  /// No installed application can display this file type.
  noViewer,

  /// The file could not be written locally.
  storage,
}

class DocumentFileException implements Exception {
  const DocumentFileException(this.kind, [this.cause]);
  final DocumentFailureKind kind;
  final Object? cause;

  @override
  String toString() => 'DocumentFileException($kind, $cause)';
}

/// Downloads chat documents and hands them to the operating system.
///
/// Attachment URLs are short-lived signed links to private storage. Handing
/// them to a browser worked poorly: the link could already be expired, and
/// mobile browsers download a PDF instead of showing it. The file is
/// therefore downloaded into the app's temporary directory (no extra storage
/// permission or sandbox entitlement needed), then:
/// - mobile: opened with the system viewer (`open_filex`, FileProvider on
///   Android, document interaction controller on iOS);
/// - desktop: opened with the default application through a `file:` URL, and
///   optionally copied where the user chooses with a native save dialog
///   (covered by the existing `files.user-selected.read-write` entitlement on
///   macOS).
class DocumentFileService {
  DocumentFileService({
    required this.isDesktop,
    Dio? dio,
    Future<Directory> Function()? cacheRoot,
  }) : _dio = dio ?? Dio(),
       _cacheRoot = cacheRoot ?? getTemporaryDirectory;

  final bool isDesktop;

  /// A bare client: signed URLs carry their own authorization, and sending
  /// the API bearer token to the storage host would leak it.
  final Dio _dio;
  final Future<Directory> Function() _cacheRoot;
  final _logger = AppLogger();

  /// Whether [source] is a local file (an outgoing upload) rather than a URL.
  static bool isLocal(String source) {
    final uri = Uri.tryParse(source);
    return uri == null || !(uri.scheme == 'http' || uri.scheme == 'https');
  }

  /// File name safe on every supported file system.
  static String safeFileName(String name) {
    final cleaned = name
        .replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1F]'), '_')
        .trim();
    if (cleaned.isEmpty || cleaned == '.' || cleaned == '..') return 'document';
    return cleaned.length > 120
        ? cleaned.substring(cleaned.length - 120)
        : cleaned;
  }

  /// Stable cache folder for a document: its media id, else its URL path
  /// (the signature query string changes on every renewal).
  static String cacheKeyOf({required String url, String? mediaId}) {
    if (mediaId != null && mediaId.isNotEmpty) return safeFileName(mediaId);
    final path = Uri.tryParse(url)?.path ?? url;
    return path.hashCode.toUnsigned(32).toRadixString(16);
  }

  /// Returns a local copy of the document, downloading it if needed.
  ///
  /// [renewUrl] provides a fresh signed URL when the first attempt is refused
  /// (expired link); it is called at most once.
  Future<File> obtain({
    required String source,
    required String fileName,
    String? mediaId,
    int? expectedSize,
    Future<String?> Function()? renewUrl,
    void Function(double progress)? onProgress,
    CancelToken? cancelToken,
  }) async {
    if (isLocal(source)) {
      final local = File(
        source.startsWith('file:') ? Uri.parse(source).toFilePath() : source,
      );
      if (await local.exists()) return local;
      throw const DocumentFileException(DocumentFailureKind.storage);
    }

    final Directory folder;
    try {
      final root = await _cacheRoot();
      folder = Directory(
        '${root.path}${Platform.pathSeparator}chat_documents'
        '${Platform.pathSeparator}${cacheKeyOf(url: source, mediaId: mediaId)}',
      );
      await folder.create(recursive: true);
    } catch (e) {
      throw DocumentFileException(DocumentFailureKind.storage, e);
    }
    final target = File(
      '${folder.path}${Platform.pathSeparator}${safeFileName(fileName)}',
    );
    if (await target.exists()) {
      final length = await target.length();
      if (length > 0 &&
          (expectedSize == null ||
              expectedSize <= 0 ||
              length == expectedSize)) {
        onProgress?.call(1);
        return target;
      }
    }

    final partial = File('${target.path}.part');
    Future<void> fetch(String url) => _dio.download(
      url,
      partial.path,
      cancelToken: cancelToken,
      deleteOnError: true,
      onReceiveProgress: (received, total) {
        final size = total > 0 ? total : (expectedSize ?? 0);
        if (size > 0) onProgress?.call((received / size).clamp(0, 1));
      },
    );

    try {
      try {
        await fetch(source);
      } on DioException catch (e) {
        if (CancelToken.isCancel(e)) rethrow;
        final status = e.response?.statusCode;
        final refused =
            status == 401 || status == 403 || status == 404 || status == 410;
        if (!refused || renewUrl == null) rethrow;
        final fresh = await renewUrl();
        if (fresh == null || fresh.isEmpty) {
          throw DocumentFileException(DocumentFailureKind.expired, e);
        }
        await fetch(fresh);
      }
      if (await target.exists()) await target.delete();
      await partial.rename(target.path);
      return target;
    } on DocumentFileException {
      rethrow;
    } on DioException catch (e) {
      _logger.warning(
        'Document download failed',
        feature: 'Documents',
        data: {'status': e.response?.statusCode, 'type': e.type.name},
      );
      throw DocumentFileException(DocumentFailureKind.download, e);
    } on FileSystemException catch (e) {
      throw DocumentFileException(DocumentFailureKind.storage, e);
    }
  }

  /// Opens [file] with the platform's default application.
  Future<void> open(File file, {String? mimeType}) async {
    if (isDesktop) {
      final opened = await launchUrl(Uri.file(file.path));
      if (!opened) {
        throw const DocumentFileException(DocumentFailureKind.noViewer);
      }
      return;
    }
    final result = await OpenFilex.open(file.path, type: mimeType);
    switch (result.type) {
      case ResultType.done:
        return;
      case ResultType.noAppToOpen:
      case ResultType.fileNotFound:
        throw DocumentFileException(
          DocumentFailureKind.noViewer,
          result.message,
        );
      case ResultType.permissionDenied:
      case ResultType.error:
        throw DocumentFileException(
          DocumentFailureKind.storage,
          result.message,
        );
    }
  }

  /// Desktop only: asks where to save a copy of [file].
  ///
  /// Returns the chosen path, or `null` when the user cancels.
  Future<String?> saveCopy(File file, {required String suggestedName}) async {
    final location = await getSaveLocation(
      suggestedName: safeFileName(suggestedName),
    );
    if (location == null) return null;
    try {
      await file.copy(location.path);
      return location.path;
    } on FileSystemException catch (e) {
      throw DocumentFileException(DocumentFailureKind.storage, e);
    }
  }
}
