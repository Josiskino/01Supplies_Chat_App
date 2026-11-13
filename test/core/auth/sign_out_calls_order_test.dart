import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:supplies_chat_app/core/abstract/failure.dart';
import 'package:supplies_chat_app/core/auth/auth_gate.dart';
import 'package:supplies_chat_app/core/calls/calls_sign_out.dart';
import 'package:supplies_chat_app/core/providers/auth/auth_provider.dart';
import 'package:supplies_chat_app/core/providers/auth/auth_status_provider.dart';
import 'package:supplies_chat_app/core/providers/realtime/push_provider.dart';
import 'package:supplies_chat_app/domain/entity/auth/user_entity.dart';
import 'package:supplies_chat_app/domain/repository/auth/auth_repository.dart';
import 'package:supplies_chat_app/domain/usecases/auth/auth_usecases.dart';

import '../../helpers/test_environment.dart';

class RecordingAuthRepository implements AuthRepository {
  RecordingAuthRepository(this.log);
  final List<String> log;
  @override
  Future<Either<Failure, AuthSessionEntity?>> restoreSession() async =>
      const Right(null);
  @override
  Future<Either<Failure, AuthSessionEntity>> signIn(SignInParams params) =>
      throw UnimplementedError();
  @override
  Future<Either<Failure, Unit>> signOut() async {
    log.add('main-session-cleared');
    return const Right(unit);
  }
}

class RecordingCallsSignOut implements CallsSignOut {
  RecordingCallsSignOut(this.log, {this.fails = false});
  final List<String> log;
  final bool fails;
  @override
  Future<void> run() async {
    log.add('calls-cleanup-started');
    await Future<void>.delayed(const Duration(milliseconds: 10));
    if (fails) throw StateError('calls service down');
    log.add('calls-cleanup-done');
  }
}

ProviderContainer containerFor(List<String> log, {bool fails = false}) {
  final repository = RecordingAuthRepository(log);
  return ProviderContainer(
    overrides: [
      signOutUseCaseProvider.overrideWithValue(SignOutUseCase(repository)),
      restoreSessionUseCaseProvider.overrideWithValue(
        RestoreSessionUseCase(repository),
      ),
      pushNotificationsProvider.overrideWith(
        (ref) => throw StateError('no push in unit tests'),
      ),
      callsSignOutProvider.overrideWithValue(
        RecordingCallsSignOut(log, fails: fails),
      ),
    ],
  );
}

void main() {
  setUpAll(setUpTestEnvironment);

  test('calls cleanup completes before the main session is cleared', () async {
    final log = <String>[];
    final container = containerFor(log);
    addTearDown(container.dispose);
    container.read(authStatusProvider);
    await container.read(authStatusProvider.notifier).signOut();
    expect(log, [
      'calls-cleanup-started',
      'calls-cleanup-done',
      'main-session-cleared',
    ]);
    expect(container.read(authStatusProvider), AuthGateStatus.unauthenticated);
  });

  test('a failing calls cleanup never blocks sign-out', () async {
    final log = <String>[];
    final container = containerFor(log, fails: true);
    addTearDown(container.dispose);
    container.read(authStatusProvider);
    await container.read(authStatusProvider.notifier).signOut();
    expect(log, ['calls-cleanup-started', 'main-session-cleared']);
  });
}
