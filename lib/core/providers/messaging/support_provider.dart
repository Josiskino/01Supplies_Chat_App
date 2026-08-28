import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/datasources/abstract/messaging/support_datasource_contract.dart';
import '../../../data/datasources/remote/support_remote_datasource.dart';
import '../../../data/repository/support_repository_impl.dart';
import '../../../domain/entity/messaging/support_ticket_entity.dart';
import '../../../domain/repository/messaging/support_repository.dart';
import '../../../domain/usecases/messaging/support_usecases.dart';
import '../request/api_provider.dart';

part 'support_provider.g.dart';

// ── Infrastructure ──────────────────────────────────────────────────────────

@riverpod
SupportDataSourceContract supportDataSource(Ref ref) =>
    SupportRemoteDataSource(ref.watch(apiClientProvider));

@riverpod
SupportRepository supportRepository(Ref ref) =>
    SupportRepositoryImpl(ref.watch(supportDataSourceProvider));

// ── Use cases ───────────────────────────────────────────────────────────────

@riverpod
FetchQueueUseCase fetchQueueUseCase(Ref ref) =>
    FetchQueueUseCase(ref.watch(supportRepositoryProvider));

@riverpod
ClaimTicketUseCase claimTicketUseCase(Ref ref) =>
    ClaimTicketUseCase(ref.watch(supportRepositoryProvider));

// ── Notifier ────────────────────────────────────────────────────────────────

/// La file d'attente commune, telle que l'onglet Conversations l'affiche.
///
/// Tous les admins voient la même liste : un client écrit, son ticket y paraît,
/// et le premier qui répond s'en saisit. C'est pourquoi elle vient de
/// `/messaging/support` et non de `/support/me`, qui ne rendrait que les
/// dossiers déjà pris — donc rien, au premier lancement.
@riverpod
class SupportQueue extends _$SupportQueue {
  @override
  Future<List<SupportTicketEntity>> build() async {
    final result = await ref
        .read(fetchQueueUseCaseProvider)
        .call(const FetchQueueParams());

    return result.match(
      (failure) => throw Exception(failure.message),
      (tickets) => tickets,
    );
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  /// Prend un ticket en charge, puis recharge la file pour refléter la reprise.
  Future<bool> claim(String ticketId) async {
    final result = await ref
        .read(claimTicketUseCaseProvider)
        .call(ClaimTicketParams(ticketId));
    if (result.isRight()) await refresh();
    return result.isRight();
  }
}
