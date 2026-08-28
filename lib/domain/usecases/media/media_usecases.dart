import 'package:fpdart/fpdart.dart';

import '../../../core/abstract/failure.dart';
import '../../../core/abstract/usecase.dart';
import '../../entity/media/media_upload_entity.dart';
import '../../repository/media/media_repository.dart';

class UploadMediaUseCase
    implements UseCase<MediaUploadEntity, UploadMediaParams> {
  const UploadMediaUseCase(this._repository);

  final MediaRepository _repository;

  @override
  Future<Either<Failure, MediaUploadEntity>> call(UploadMediaParams params) =>
      _repository.upload(params);
}
