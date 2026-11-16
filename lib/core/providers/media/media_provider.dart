import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/datasources/abstract/media/media_datasource_contract.dart';
import '../../../data/datasources/remote/media_remote_datasource.dart';
import '../../../data/repository/media_repository_impl.dart';
import '../../../domain/repository/media/media_repository.dart';
import '../../../domain/usecases/media/media_usecases.dart';
import '../../services/document_file_service.dart';
import '../request/api_provider.dart';

part 'media_provider.g.dart';

// ── Infrastructure ──────────────────────────────────────────────────────────

@riverpod
MediaDataSourceContract mediaDataSource(Ref ref) =>
    MediaRemoteDataSource(ref.watch(apiClientProvider));

@riverpod
MediaRepository mediaRepository(Ref ref) =>
    MediaRepositoryImpl(ref.watch(mediaDataSourceProvider));

/// Downloads and opens chat documents.
///
/// The platform is read from `defaultTargetPlatform` (never `dart:io`), so
/// tests can exercise both the mobile and the desktop behaviour.
@Riverpod(keepAlive: true)
DocumentFileService documentFileService(Ref ref) => DocumentFileService(
  isDesktop: const {
    TargetPlatform.macOS,
    TargetPlatform.windows,
    TargetPlatform.linux,
  }.contains(defaultTargetPlatform),
);

// ── Use cases ───────────────────────────────────────────────────────────────

@riverpod
UploadMediaUseCase uploadMediaUseCase(Ref ref) =>
    UploadMediaUseCase(ref.watch(mediaRepositoryProvider));
