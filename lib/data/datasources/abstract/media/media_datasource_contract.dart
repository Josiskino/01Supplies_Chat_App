import '../../../../core/utils/api_types.dart';
import '../../../models/media/media_upload_model.dart';

/// Dépôt d'un fichier destiné à un message.
abstract interface class MediaDataSourceContract {
  Future<ApiResult<MediaUploadModel>> upload(
    String filePath, {
    void Function(int sent, int total)? onProgress,
  });
  Future<ApiResult<MediaUploadModel>> getById(String mediaId);
}
