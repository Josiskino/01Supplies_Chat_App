import 'package:fpdart/fpdart.dart';

import '../../core/abstract/base_repository.dart';
import '../../core/abstract/failure.dart';
import '../../domain/entity/media/media_upload_entity.dart';
import '../../domain/repository/media/media_repository.dart';
import '../datasources/abstract/media/media_datasource_contract.dart';
import '../models/media/media_upload_model.dart';

class MediaRepositoryImpl extends BaseRepository implements MediaRepository {
  MediaRepositoryImpl(this._remote);

  final MediaDataSourceContract _remote;

  @override
  Future<Either<Failure, MediaUploadEntity>> getById(String mediaId) async {
    final result = await execute<MediaUploadModel>(() => _remote.getById(mediaId));
    return result.map((model) => model.toEntity());
  }

  @override
  Future<Either<Failure, MediaUploadEntity>> upload(
    UploadMediaParams params,
  ) async {
    final result = await execute<MediaUploadModel>(
      () => _remote.upload(params.filePath),
    );
    return result.map((m) => m.toEntity());
  }
}
