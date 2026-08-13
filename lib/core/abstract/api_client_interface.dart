import '../utils/api_types.dart';

enum HttpMethod {
  get,
  post,
  put,
  delete,
  patch;

  String get value => name.toUpperCase();
}

/// Contrat du client HTTP.
///
/// Les data sources dépendent de cette interface, jamais de `Dio` directement :
/// c'est ce qui permet de les tester avec un faux client.
abstract class ApiClientInterface {
  Future<ApiResult<T>> request<T>({
    String? baseUrl,
    required String path,
    required HttpMethod method,
    required JsonParser<T> fromJson,
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    String? dataKey,
    List<MetadataConfig> metadataConfigs = const [],
    JsonParser<dynamic>? itemFromJson,
    List<String>? listPath,
  });

  Future<ApiResult<T>> uploadSingleFile<T>({
    String? baseUrl,
    required String path,
    required String filePath,
    required JsonParser<T> fromJson,
    String fileKey = 'file',
    Map<String, dynamic>? additionalData,
    Map<String, String>? headers,
    HttpMethod method = HttpMethod.post,
  });

  Future<ApiResult<T>> uploadFilesWithDifferentKeys<T>({
    String? baseUrl,
    required String path,
    required Map<String, String> filePathsWithKeys,
    required JsonParser<T> fromJson,
    Map<String, dynamic>? additionalData,
    Map<String, String>? headers,
    HttpMethod method = HttpMethod.post,
  });

  void setAuthToken(String token);
}
