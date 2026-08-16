import 'package:dio/dio.dart';

import 'api_error_messages.dart';
import 'api_types.dart';
import 'app_logger.dart';

/// Transforme une `Response` Dio en [ApiResult].
///
/// Gère les trois formes de réponse du backend 01Supplies : corps direct,
/// enveloppe `{data: …}` (via [dataKey]), et structure imbriquée (via
/// [listPath]).
class ApiResponseHandler {
  static ApiResult<T> handleResponse<T>(
    Response response,
    JsonParser<T> fromJson, {
    String? dataKey,
    List<MetadataConfig> metadataConfigs = const [],
    JsonParser<dynamic>? itemFromJson,
    List<String>? listPath,
  }) {
    try {
      final statusCode = response.statusCode ?? 500;
      final responseData = response.data;

      if (_isErrorStatusCode(statusCode)) {
        // Message métier, jamais la chaîne serveur brute.
        return ApiError(
          message: ApiErrorMessages.resolve(statusCode: statusCode),
          statusCode: statusCode,
          rawData: responseData is Map<String, dynamic> ? responseData : null,
        );
      }

      if (responseData is! Map<String, dynamic>) {
        return const ApiError(message: 'Invalid response format');
      }

      try {
        var dataToParse = dataKey != null
            ? responseData[dataKey]
            : responseData;

        // Navigation dans une structure imbriquée.
        if (listPath != null && listPath.isNotEmpty) {
          for (final key in listPath) {
            if (dataToParse is Map<String, dynamic>) {
              dataToParse = dataToParse[key];
            } else if (dataToParse is List) {
              final index = int.tryParse(key);
              if (index != null && index < dataToParse.length) {
                dataToParse = dataToParse[index];
              } else {
                dataToParse = null;
                break;
              }
            } else {
              dataToParse = null;
              break;
            }
          }
        }

        // `itemFromJson` fourni : on mappe une liste ou un item isolé.
        if (itemFromJson != null) {
          if (dataToParse is List) {
            final mappedList = dataToParse
                .map((item) => itemFromJson(item as Map<String, dynamic>))
                .toList();
            final metadata = _parseMetadata(responseData, metadataConfigs);
            // `fromJson` sert de convertisseur de type final.
            final data = fromJson({'data': mappedList});
            return ApiSuccess<T>(
              data: data,
              statusCode: statusCode,
              metadata: metadata,
            );
          } else if (dataToParse is Map<String, dynamic>) {
            final mappedItem = itemFromJson(dataToParse);
            final metadata = _parseMetadata(responseData, metadataConfigs);
            return ApiSuccess<T>(
              data: mappedItem as T,
              statusCode: statusCode,
              metadata: metadata,
            );
          } else if (dataToParse == null) {
            // Chemin introuvable : `fromJson` décide (null, liste vide…).
            final data = fromJson({'data': null});
            final metadata = _parseMetadata(responseData, metadataConfigs);
            return ApiSuccess<T>(
              data: data,
              statusCode: statusCode,
              metadata: metadata,
            );
          }
        }

        // Une liste est enveloppée pour rester compatible avec `JsonParser`.
        final Map<String, dynamic> jsonToParse;
        if (dataToParse is Map<String, dynamic>) {
          jsonToParse = dataToParse;
        } else {
          jsonToParse = {'data': dataToParse};
        }

        final data = fromJson(jsonToParse);
        final metadata = _parseMetadata(responseData, metadataConfigs);

        return ApiSuccess(
          data: data,
          statusCode: statusCode,
          metadata: metadata,
        );
      } catch (e, stackTrace) {
        AppLogger().error(
          'Error parsing response data',
          feature: 'API',
          data: {'body': response.data},
          error: e,
          stackTrace: stackTrace,
        );
        return ApiError(
          message: 'Error parsing response data: $e',
          error: e,
          rawData: responseData,
        );
      }
    } catch (e, stackTrace) {
      AppLogger().error(
        'Unexpected error processing response',
        feature: 'API',
        error: e,
        stackTrace: stackTrace,
      );
      return ApiError(
        message: 'Unexpected error processing response',
        error: e,
      );
    }
  }

  static Map<String, dynamic> _parseMetadata(
    Map<String, dynamic> responseData,
    List<MetadataConfig> configs,
  ) {
    final metadata = <String, dynamic>{};
    for (final config in configs) {
      if (responseData.containsKey(config.key)) {
        final value = responseData[config.key];
        if (config.parser != null && value is Map<String, dynamic>) {
          metadata[config.key] = config.parser!(value);
        } else {
          metadata[config.key] = value;
        }
      }
    }
    return metadata;
  }

  static bool _isErrorStatusCode(int statusCode) =>
      statusCode < 200 || statusCode >= 300;
}
