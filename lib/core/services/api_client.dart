import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../abstract/api_client_interface.dart';
import '../constants/api_constant.dart';
import '../utils/api_error_messages.dart';
import '../utils/api_response_handler.dart';
import '../utils/api_types.dart';
import '../utils/app_logger.dart';
import '../utils/log_redaction.dart';
import '../utils/preferences.dart';

class DioClient implements ApiClientInterface {
  final Dio _dio;

  DioClient({required Dio dio}) : _dio = dio {
    _dio.interceptors.add(_AuthInterceptor());
  }

  @override
  void setAuthToken(String token) {
    // Le token est géré par [_AuthInterceptor], qui le relit depuis le stockage
    // local à chaque requête. Cette méthode reste pour satisfaire l'interface.
  }

  Options _defaultOptions([
    String? contentType,
    Map<String, String>? customHeaders,
  ]) {
    final headers = <String, String>{
      'Content-Type': contentType ?? 'application/json',
      'Accept': 'application/json',
    };

    final apiKey = ApiConstant.xApiKey;
    if (apiKey.isNotEmpty) {
      headers['x-api-key'] = apiKey;
    }

    if (customHeaders != null) {
      headers.addAll(customHeaders);
    }

    return Options(headers: headers);
  }

  /// Assemble base et chemin sans double slash, et laisse passer une URL déjà
  /// absolue.
  String _combineUrl(String base, String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    final normalizedBase = base.endsWith('/') ? base : '$base/';
    final normalizedPath = path.startsWith('/') ? path.substring(1) : path;
    return normalizedBase + normalizedPath;
  }

  @override
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
  }) async {
    final effectiveBaseUrl = baseUrl ?? _dio.options.baseUrl;
    final fullUrl = effectiveBaseUrl.isNotEmpty
        ? _combineUrl(effectiveBaseUrl, path)
        : path;

    final logger = AppLogger();
    final requestOptions = _defaultOptions(null, headers);

    logger.api(
      method.value,
      path,
      'Request started',
      data: {
        'url': fullUrl,
        'queryParameters': queryParameters,
        'body': LogRedaction.redact(data),
      },
    );

    try {
      final stopwatch = Stopwatch()..start();

      final response = await _dio.request(
        fullUrl,
        data: data,
        queryParameters: queryParameters,
        options: requestOptions..method = method.value,
      );
      stopwatch.stop();

      logger.api(
        method.value,
        path,
        'Request completed successfully',
        statusCode: response.statusCode,
        data: {'duration': '${stopwatch.elapsedMilliseconds}ms'},
      );

      final result = ApiResponseHandler.handleResponse(
        response,
        fromJson,
        dataKey: dataKey,
        metadataConfigs: metadataConfigs,
        itemFromJson: itemFromJson,
        listPath: listPath,
      );

      if (result case ApiError(
        message: final message,
        statusCode: final statusCode,
        error: final error,
      )) {
        logger.error(
          'API Response: Error',
          feature: 'API',
          data: {'path': path, 'message': message, 'statusCode': statusCode},
          error: error,
        );
      }

      return result;
    } on DioException catch (e) {
      String errorMessage = e.message ?? 'Request failed';
      Map<String, dynamic>? errorData;

      if (e.response?.data != null) {
        errorData = e.response?.data is Map<String, dynamic>
            ? e.response?.data as Map<String, dynamic>
            : null;

        if (errorData != null) {
          // `errorMessages[0].message` porte le message de validation le plus
          // précis : certains contrôles métier remontent en 500 alors qu'il
          // s'agit en réalité d'une erreur de saisie.
          final errList = errorData['errorMessages'];
          final firstErrMsg =
              (errList is List && errList.isNotEmpty && errList.first is Map)
              ? (errList.first as Map)['message']?.toString()
              : null;
          errorMessage =
              (firstErrMsg != null && firstErrMsg.isNotEmpty
                  ? firstErrMsg
                  : null) ??
              errorData['error'] as String? ??
              errorData['message'] as String? ??
              errorData['errors']?.toString() ??
              errorMessage;
        } else if (e.response?.data is String) {
          errorMessage = e.response?.data as String;
        }
      }

      // Le message serveur brut reste dans les journaux.
      logger.error(
        'API Request failed',
        feature: 'API',
        data: {
          'method': method.value,
          'path': path,
          'url': fullUrl,
          'statusCode': e.response?.statusCode,
          'serverMessage': errorMessage,
          'serverResponse': errorData,
          'requestBody': LogRedaction.redact(data),
        },
        error: e,
      );

      // Ce qui remonte à l'UI est un message métier.
      return ApiError(
        message: ApiErrorMessages.resolve(
          statusCode: e.response?.statusCode,
          serverMessage: errorMessage,
          requestPath: e.requestOptions.path,
        ),
        statusCode: e.response?.statusCode,
        error: e,
        rawData: errorData,
      );
    } catch (e, stackTrace) {
      logger.fatal(
        'Unexpected error in API request',
        feature: 'API',
        data: {'method': method.value, 'path': path, 'url': fullUrl},
        error: e,
        stackTrace: stackTrace,
      );

      return ApiError(message: 'Unexpected error: $e', error: e);
    }
  }

  @override
  Future<ApiResult<T>> uploadSingleFile<T>({
    String? baseUrl,
    required String path,
    required String filePath,
    required JsonParser<T> fromJson,
    String fileKey = 'file',
    Map<String, dynamic>? additionalData,
    Map<String, String>? headers,
    HttpMethod method = HttpMethod.post,
  }) async {
    final file = await _createSingleFileMultipart(filePath);

    final formData = FormData();
    formData.files.add(MapEntry(fileKey, file));

    additionalData?.forEach((key, value) {
      if (value != null) {
        formData.fields.add(MapEntry(key, value.toString()));
      }
    });

    return _handleFormDataUpload(
      path: baseUrl != null ? _combineUrl(baseUrl, path) : path,
      formData: formData,
      fromJson: fromJson,
      headers: headers,
      method: method,
    );
  }

  @override
  Future<ApiResult<T>> uploadFilesWithDifferentKeys<T>({
    String? baseUrl,
    required String path,
    required Map<String, String> filePathsWithKeys,
    required JsonParser<T> fromJson,
    Map<String, dynamic>? additionalData,
    Map<String, String>? headers,
    HttpMethod method = HttpMethod.post,
  }) async {
    final formData = FormData();

    for (final entry in filePathsWithKeys.entries) {
      final file = await _createSingleFileMultipart(entry.value);
      formData.files.add(MapEntry(entry.key, file));
    }

    additionalData?.forEach((key, value) {
      if (value == null) return;
      // Listes et maps sont sérialisées en JSON : un `toString()` produirait la
      // représentation Dart, que le backend ne sait pas lire.
      if (value is List || value is Map) {
        formData.fields.add(MapEntry(key, jsonEncode(value)));
      } else {
        formData.fields.add(MapEntry(key, value.toString()));
      }
    });

    return _handleFormDataUpload(
      path: baseUrl != null ? _combineUrl(baseUrl, path) : path,
      formData: formData,
      fromJson: fromJson,
      headers: headers,
      method: method,
    );
  }

  Future<ApiResult<T>> _handleFormDataUpload<T>({
    required String path,
    required FormData formData,
    required JsonParser<T> fromJson,
    Map<String, String>? headers,
    HttpMethod method = HttpMethod.post,
  }) async {
    final logger = AppLogger();

    logger.debug(
      'Uploading form data',
      feature: 'API',
      data: {
        'path': path,
        'method': method.value,
        'fieldsCount': formData.fields.length,
        'filesCount': formData.files.length,
      },
    );

    try {
      final options = _defaultOptions('multipart/form-data', headers);

      final response = await switch (method) {
        HttpMethod.post => _dio.post(path, data: formData, options: options),
        HttpMethod.put => _dio.put(path, data: formData, options: options),
        HttpMethod.patch => _dio.patch(path, data: formData, options: options),
        _ => throw ArgumentError(
          'Method ${method.name} is not allowed for form data upload',
        ),
      };

      return ApiResponseHandler.handleResponse(response, fromJson);
    } on DioException catch (e) {
      logger.error(
        'Upload failed',
        feature: 'API',
        data: {'path': path, 'statusCode': e.response?.statusCode},
        error: e,
      );
      return ApiError<T>(
        message: ApiErrorMessages.resolve(
          statusCode: e.response?.statusCode,
          serverMessage: e.message,
          requestPath: path,
        ),
        statusCode: e.response?.statusCode,
        error: e,
        rawData: e.response?.data is Map<String, dynamic>
            ? e.response?.data as Map<String, dynamic>
            : null,
      );
    }
  }

  Future<MultipartFile> _createSingleFileMultipart(String filePath) {
    // Le séparateur Windows doit être pris en compte, sans quoi le nom de
    // fichier envoyé contient tout le chemin.
    final fileName = filePath.split(RegExp(r'[/\\]')).last;
    return MultipartFile.fromFile(filePath, filename: fileName);
  }
}

/// Hook global de notification d'échec d'authentification.
///
/// À brancher une fois au démarrage (depuis le ViewModel d'auth) pour être
/// prévenu quand le refresh token n'est plus valide et que la session doit être
/// fermée.
set onAuthInterceptorFailure(VoidCallback? cb) {
  _AuthInterceptor.onAuthFailure = cb;
}

/// Hook invoqué après un refresh réussi, avec le nouveau token d'accès.
///
/// Indispensable pour la messagerie : une connexion Socket.IO conserve le token
/// figé au handshake et se fait rejeter par le backend après un refresh si elle
/// n'est pas prévenue de se reconnecter.
set onAuthTokenRefreshed(void Function(String newToken)? cb) {
  _AuthInterceptor.onTokenRefreshed = cb;
}

/// Injecte le token d'authentification et gère son renouvellement.
class _AuthInterceptor extends QueuedInterceptor {
  static VoidCallback? onAuthFailure;
  static void Function(String newToken)? onTokenRefreshed;

  /// Completer partagé : N requêtes qui prennent un 401 simultanément attendent
  /// **un seul** refresh au lieu d'en déclencher N.
  static Completer<bool>? _refreshCompleter;

  bool _isAuthEndpoint(String path) {
    return path.contains('/auth/login') ||
        path.contains('/auth/refresh-tokens') ||
        path.contains('/auth/forgot-password') ||
        path.contains('/auth/reset-password');
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (_isAuthEndpoint(options.path)) {
      return handler.next(options);
    }

    final token = await SharedPreferencesHelper.getValue(StorageKeys.token);
    final expiryStr = await SharedPreferencesHelper.getValue(
      StorageKeys.tokenExpires,
    );

    if (token.isEmpty) {
      return handler.next(options);
    }

    var isExpired = false;
    if (expiryStr.isNotEmpty) {
      try {
        final expiry = DateTime.parse(expiryStr);
        // Marge de 30 s : évite d'émettre une requête avec un token qui expirera
        // pendant son trajet réseau.
        if (expiry.difference(DateTime.now()).inSeconds < 30) {
          isExpired = true;
        }
      } catch (_) {
        // Date illisible : on laisse partir le token tel quel, le 401 tranchera.
      }
    }

    if (isExpired) {
      final success = await _refreshToken();
      final effectiveToken = success
          ? await SharedPreferencesHelper.getValue(StorageKeys.token)
          : token;
      options.headers['Authorization'] = 'Bearer $effectiveToken';
    } else {
      options.headers['Authorization'] = 'Bearer $token';
    }

    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final status = err.response?.statusCode;
    final path = err.requestOptions.path;

    if (status == 401 && !_isAuthEndpoint(path)) {
      final success = await _refreshToken();

      if (success) {
        final newToken = await SharedPreferencesHelper.getValue(
          StorageKeys.token,
        );
        final options = err.requestOptions;
        options.headers['Authorization'] = 'Bearer $newToken';

        try {
          // Rejoué sur une instance Dio neuve : réutiliser celle du client
          // ferait repasser par cet interceptor et boucler sur un token refusé.
          final dio = Dio(
            BaseOptions(
              baseUrl: options.baseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ),
          );
          final response = await dio.request(
            options.path,
            data: options.data,
            queryParameters: options.queryParameters,
            options: Options(
              method: options.method,
              headers: options.headers,
              responseType: options.responseType,
              contentType: options.contentType,
            ),
          );
          return handler.resolve(response);
        } catch (_) {
          return handler.next(err);
        }
      } else {
        await _handleLogout();
      }
    }

    handler.next(err);
  }

  Future<bool> _refreshToken() async {
    // Un refresh est déjà en vol : on s'y raccroche pour que toutes les requêtes
    // en attente se débloquent ensemble.
    final existing = _refreshCompleter;
    if (existing != null) {
      return existing.future;
    }

    final completer = Completer<bool>();
    _refreshCompleter = completer;

    try {
      final refreshToken = await SharedPreferencesHelper.getValue(
        StorageKeys.refreshToken,
      );
      if (refreshToken.isEmpty) {
        completer.complete(false);
        return false;
      }

      final dio = Dio(
        BaseOptions(
          baseUrl: ApiConstant.baseUrlWithPrefix,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      final response = await dio.post(
        'auth/refresh-tokens',
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200) {
        final data = response.data['data'];
        final tokens = data?['tokens'];
        if (tokens != null) {
          final newAccess = tokens['access']['token'] as String;
          await SharedPreferencesHelper.setValue(StorageKeys.token, newAccess);
          await SharedPreferencesHelper.setValue(
            StorageKeys.tokenExpires,
            tokens['access']['expires'].toString(),
          );
          await SharedPreferencesHelper.setValue(
            StorageKeys.refreshToken,
            tokens['refresh']['token'] as String,
          );
          try {
            onTokenRefreshed?.call(newAccess);
          } catch (e) {
            AppLogger().error(
              'onTokenRefreshed callback threw',
              feature: 'Auth',
              error: e,
            );
          }
          completer.complete(true);
          return true;
        }
      }
      completer.complete(false);
      return false;
    } catch (e) {
      AppLogger().error('Token refresh failed', feature: 'Auth', error: e);
      completer.complete(false);
      return false;
    } finally {
      // Remis à zéro pour que la prochaine expiration ouvre un nouveau cycle.
      _refreshCompleter = null;
    }
  }

  Future<void> _handleLogout() async {
    await SharedPreferencesHelper.deleteValue(StorageKeys.token);
    await SharedPreferencesHelper.deleteValue(StorageKeys.tokenExpires);
    await SharedPreferencesHelper.deleteValue(StorageKeys.refreshToken);
    await SharedPreferencesHelper.deleteValue(StorageKeys.userProfile);
    try {
      onAuthFailure?.call();
    } catch (e) {
      AppLogger().error(
        'onAuthFailure callback threw',
        feature: 'Auth',
        error: e,
      );
    }
  }
}
