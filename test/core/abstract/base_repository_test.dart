import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:supplies_chat_app/core/abstract/base_repository.dart';
import 'package:supplies_chat_app/core/abstract/failure.dart';
import 'package:supplies_chat_app/core/utils/api_types.dart';

/// Repository nu, juste pour exposer les méthodes protégées de [BaseRepository].
class _TestRepository extends BaseRepository {}

void main() {
  late _TestRepository repository;

  setUp(() => repository = _TestRepository());

  group('execute — mapping code HTTP → Failure', () {
    test('succès : renvoie la donnée à droite', () async {
      final result = await repository.execute<String>(
        () async => const ApiSuccess(data: 'ok', statusCode: 200),
      );

      expect(result.isRight(), isTrue);
      expect(result.getRight().toNullable(), 'ok');
    });

    test('401 → AuthFailure', () async {
      final result = await repository.execute<String>(
        () async => const ApiError(message: 'Session expirée', statusCode: 401),
      );

      final failure = result.getLeft().toNullable();
      expect(failure, isA<AuthFailure>());
      expect(failure!.message, 'Session expirée');
    });

    test('403 → ForbiddenFailure', () async {
      final result = await repository.execute<String>(
        () async => const ApiError(message: 'Interdit', statusCode: 403),
      );

      expect(result.getLeft().toNullable(), isA<ForbiddenFailure>());
    });

    test('404 → NotFoundFailure', () async {
      final result = await repository.execute<String>(
        () async => const ApiError(message: 'Introuvable', statusCode: 404),
      );

      expect(result.getLeft().toNullable(), isA<NotFoundFailure>());
    });

    test('tout autre code → BusinessFailure', () async {
      for (final status in [400, 409, 422, 500, 503]) {
        final result = await repository.execute<String>(
          () async => ApiError(message: 'Erreur', statusCode: status),
        );

        expect(
          result.getLeft().toNullable(),
          isA<BusinessFailure>(),
          reason: 'statusCode=$status',
        );
      }
    });

    test('statusCode absent → BusinessFailure', () async {
      final result = await repository.execute<String>(
        () async => const ApiError(message: 'Hors ligne'),
      );

      expect(result.getLeft().toNullable(), isA<BusinessFailure>());
    });
  });

  group('execute — exceptions', () {
    test('TimeoutException → NetworkFailure', () async {
      final result = await repository.execute<String>(
        () async => throw TimeoutException('trop long'),
      );

      expect(result.getLeft().toNullable(), isA<NetworkFailure>());
    });

    test('exception quelconque → UnexpectedFailure, jamais de throw', () async {
      final result = await repository.execute<String>(
        () async => throw StateError('bug'),
      );

      expect(result.getLeft().toNullable(), isA<UnexpectedFailure>());
    });
  });

  group('conversion model → entity', () {
    test('convertModelToEntity applique le mapper', () {
      final result = repository.convertModelToEntity<int, String>(
        42,
        (m) => 'valeur $m',
      );

      expect(result.getRight().toNullable(), 'valeur 42');
    });

    test('convertModelToEntity capture l\'échec du mapper', () {
      final result = repository.convertModelToEntity<int, String>(
        42,
        (_) => throw const FormatException('champ manquant'),
      );

      expect(result.getLeft().toNullable(), isA<UnexpectedFailure>());
    });

    test('convertModelsToEntities ignore les models invalides', () {
      // Un enregistrement corrompu ne doit pas vider la liste entière côté UI.
      final result = repository.convertModelsToEntities<int, String>([
        1,
        2,
        3,
      ], (m) => m == 2 ? throw const FormatException('ko') : 'v$m');

      expect(result.getRight().toNullable(), ['v1', 'v3']);
    });

    test('convertModelsToEntitiesStrict échoue au premier model invalide', () {
      final result = repository.convertModelsToEntitiesStrict<int, String>([
        1,
        2,
        3,
      ], (m) => m == 2 ? Left(BusinessFailure('ko')) : Right('v$m'));

      expect(result.isLeft(), isTrue);
    });
  });
}
