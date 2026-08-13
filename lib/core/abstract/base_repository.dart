import 'dart:async';

import 'package:fpdart/fpdart.dart';

import '../utils/api_types.dart';
import '../utils/app_logger.dart';
import 'failure.dart';

/// Classe de base de tous les repositories.
///
/// Centralise deux responsabilités : l'exécution protégée d'un appel réseau
/// (`ApiResult` → `Either<Failure, T>`) et la conversion model → entity.
abstract class BaseRepository {
  final _logger = AppLogger();

  /// Exécute [action] et traduit son résultat en `Either`.
  ///
  /// Aucune exception ne franchit cette frontière : les appelants n'ont jamais
  /// besoin d'un try/catch.
  Future<Either<Failure, T>> execute<T>(
    Future<ApiResult<T>> Function() action,
  ) async {
    _logger.debug(
      'Executing repository action',
      feature: runtimeType.toString(),
    );
    try {
      final result = await action();
      switch (result) {
        case ApiSuccess(data: final data):
          _logger.debug(
            'Repository action completed successfully',
            feature: runtimeType.toString(),
          );
          return Right(data);
        case ApiError(
          message: final message,
          statusCode: final statusCode,
          error: final error,
        ):
          _logger.error(
            'Repository action failed',
            feature: runtimeType.toString(),
            data: {'message': message, 'statusCode': statusCode},
            error: error,
          );
          return Left(_mapErrorToFailure(message, statusCode, error));
      }
    } on TimeoutException {
      _logger.error(
        'Repository action timeout',
        feature: runtimeType.toString(),
      );
      return Left(NetworkFailure('Request timeout'));
    } catch (e, stackTrace) {
      _logger.fatal(
        'Unexpected error in repository action',
        feature: runtimeType.toString(),
        error: e,
        stackTrace: stackTrace,
      );
      return Left(UnexpectedFailure(e.toString(), stackTrace));
    }
  }

  /// Convertit un model en entity via [mapper].
  Either<Failure, TEntity> convertModelToEntity<TModel, TEntity>(
    TModel model,
    TEntity Function(TModel) mapper,
  ) {
    try {
      return Right(mapper(model));
    } catch (e, stackTrace) {
      _logger.error(
        'Model to entity conversion failed',
        feature: runtimeType.toString(),
        error: e,
        stackTrace: stackTrace,
      );
      return Left(UnexpectedFailure(e.toString(), stackTrace));
    }
  }

  /// Convertit une liste, en **ignorant** les models invalides.
  ///
  /// Un enregistrement corrompu ne doit pas vider une liste entière côté UI ;
  /// il est journalisé et sauté.
  Either<Failure, List<TEntity>> convertModelsToEntities<TModel, TEntity>(
    List<TModel> models,
    TEntity Function(TModel) mapper,
  ) {
    final entities = <TEntity>[];
    for (final model in models) {
      try {
        entities.add(mapper(model));
      } catch (e, stackTrace) {
        _logger.warning(
          'Skipping invalid model during conversion',
          feature: runtimeType.toString(),
          error: e,
          stackTrace: stackTrace,
        );
      }
    }
    return Right(entities);
  }

  /// Variante stricte : échoue si **un seul** model ne se convertit pas.
  Either<Failure, List<TEntity>>
  convertModelsToEntitiesStrict<TModel, TEntity>(
    List<TModel> models,
    Either<Failure, TEntity> Function(TModel) mapper,
  ) {
    final entities = <TEntity>[];
    for (final model in models) {
      final result = mapper(model);
      if (result.isLeft()) {
        return result.map((_) => <TEntity>[]);
      }
      result.match((_) {}, entities.add);
    }
    return Right(entities);
  }

  Failure _mapErrorToFailure(String message, int? statusCode, Object? error) {
    return switch (statusCode) {
      401 => AuthFailure(message),
      403 => ForbiddenFailure(message),
      404 => NotFoundFailure(message),
      _ => BusinessFailure(
        message,
        error,
        error is Exception ? StackTrace.current : null,
      ),
    };
  }
}
