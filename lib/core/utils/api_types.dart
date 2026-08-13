/// Convertit un JSON en objet typé.
typedef JsonParser<T> = T Function(Map<String, dynamic>);

/// Déclare une clé de métadonnée à extraire de la réponse (pagination, totaux…)
/// en plus du corps principal.
class MetadataConfig<T> {
  final String key;
  final JsonParser<T>? parser;

  const MetadataConfig(this.key, {this.parser});
}

/// Résultat d'un appel API. Pivot de toute la couche data.
///
/// `sealed` : le `switch` sur les deux cas est exhaustif, donc l'oubli d'un
/// chemin d'erreur est une erreur de compilation, pas un bug d'exécution.
sealed class ApiResult<T> {
  const ApiResult();

  bool get isSuccess => this is ApiSuccess<T>;
  bool get isError => this is ApiError<T>;

  T? get data => switch (this) {
    ApiSuccess(data: final d) => d,
    ApiError() => null,
  };
}

class ApiSuccess<T> extends ApiResult<T> {
  @override
  final T data;
  final int statusCode;
  final Map<String, dynamic> metadata;

  const ApiSuccess({
    required this.data,
    required this.statusCode,
    this.metadata = const {},
  });

  R? getMetadata<R>(String key) => metadata[key] as R?;
}

class ApiError<T> extends ApiResult<T> {
  final String message;
  final int? statusCode;
  final Object? error;
  final Map<String, dynamic>? rawData;

  const ApiError({
    required this.message,
    this.statusCode,
    this.error,
    this.rawData,
  });
}
