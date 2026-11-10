import '../../../core/abstract/api_client_interface.dart';
import '../../../core/constants/api_endpoints_urls.dart';
import '../../../core/utils/api_types.dart';
import '../../models/media/media_upload_model.dart';
import '../abstract/media/media_datasource_contract.dart';

class MediaRemoteDataSource implements MediaDataSourceContract {
  const MediaRemoteDataSource(this._client);

  final ApiClientInterface _client;

  @override
  Future<ApiResult<MediaUploadModel>> getById(String mediaId) =>
      _client.request<MediaUploadModel>(
        path: 'media/${Uri.encodeComponent(mediaId)}',
        method: HttpMethod.get,
        dataKey: 'data',
        fromJson: MediaUploadModel.fromJson,
      );

  @override
  Future<ApiResult<MediaUploadModel>> upload(String filePath) {
    return _client.uploadSingleFile<MediaUploadModel>(
      path: ApiEndpoints.mediaUpload,
      filePath: filePath,
      // `purpose` décide de la durée de conservation et des droits d'accès : un
      // fichier déposé sans lui serait rangé comme média de catalogue, visible
      // là où il n'a rien à faire.
      additionalData: const {'purpose': 'message_attachment'},
      // `uploadSingleFile` n'expose pas de `dataKey` : le parseur reçoit
      // l'enveloppe `{statusCode, success, data}` entière. Sans cette
      // extraction, l'identifiant du média restait vide et le message partait
      // avec une pièce jointe fantôme, que le serveur refusait.
      fromJson: (json) => MediaUploadModel.fromJson(
        (json['data'] as Map?)?.cast<String, dynamic>() ?? json,
      ),
    );
  }
}
