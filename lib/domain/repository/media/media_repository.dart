import 'package:fpdart/fpdart.dart';

import '../../../core/abstract/failure.dart';
import '../../entity/media/media_upload_entity.dart';

abstract interface class MediaRepository {
  Future<Either<Failure, MediaUploadEntity>> upload(UploadMediaParams params);

  /// Fetch metadata and a fresh signed URL under the current session.
  Future<Either<Failure, MediaUploadEntity>> getById(String mediaId);
}

class UploadMediaParams {
  const UploadMediaParams(this.filePath, {this.onProgress});
  final String filePath;

  /// Bytes sent so far and total bytes, reported while the file uploads.
  final void Function(int sent, int total)? onProgress;
}
