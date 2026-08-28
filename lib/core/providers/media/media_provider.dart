import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/datasources/abstract/media/media_datasource_contract.dart';
import '../../../data/datasources/remote/media_remote_datasource.dart';
import '../../../data/repository/media_repository_impl.dart';
import '../../../domain/repository/media/media_repository.dart';
import '../../../domain/usecases/media/media_usecases.dart';
import '../request/api_provider.dart';

part 'media_provider.g.dart';

// ── Infrastructure ──────────────────────────────────────────────────────────

@riverpod
MediaDataSourceContract mediaDataSource(Ref ref) =>
    MediaRemoteDataSource(ref.watch(apiClientProvider));

@riverpod
MediaRepository mediaRepository(Ref ref) =>
    MediaRepositoryImpl(ref.watch(mediaDataSourceProvider));

// ── Use cases ───────────────────────────────────────────────────────────────

@riverpod
UploadMediaUseCase uploadMediaUseCase(Ref ref) =>
    UploadMediaUseCase(ref.watch(mediaRepositoryProvider));
