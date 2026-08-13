import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../abstract/api_client_interface.dart';
import '../../constants/api_constant.dart';
import '../../services/api_client.dart';

part 'api_provider.g.dart';

@riverpod
Dio dio(Ref ref) {
  return Dio(
    BaseOptions(
      baseUrl: ApiConstant.baseUrlWithPrefix,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );
}

/// Racine de l'injection de dépendances de la couche data : toutes les data
/// sources se construisent à partir de ce provider.
@riverpod
ApiClientInterface apiClient(Ref ref) {
  final dio = ref.watch(dioProvider);
  return DioClient(dio: dio);
}
