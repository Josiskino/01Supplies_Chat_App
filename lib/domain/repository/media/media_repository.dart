import 'package:fpdart/fpdart.dart';

import '../../../core/abstract/failure.dart';
import '../../entity/media/media_upload_entity.dart';

abstract interface class MediaRepository {
  Future<Either<Failure, MediaUploadEntity>> upload(UploadMediaParams params);
}

class UploadMediaParams {
  const UploadMediaParams(this.filePath);
  final String filePath;
}
