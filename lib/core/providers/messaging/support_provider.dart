import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/datasources/abstract/messaging/support_datasource_contract.dart';
import '../../../data/datasources/remote/support_remote_datasource.dart';
import '../../../data/repository/support_repository_impl.dart';
import '../../../domain/entity/messaging/conversation_list_entry.dart';
import '../../../domain/entity/messaging/support_ticket_entity.dart';
import '../auth/auth_provider.dart';
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
FetchConversationsUseCase fetchConversationsUseCase(Ref ref) =>
    FetchConversationsUseCase(ref.watch(supportRepositoryProvider));

@riverpod
OpenDirectConversationUseCase openDirectConversationUseCase(Ref ref) =>
    OpenDirectConversationUseCase(ref.watch(supportRepositoryProvider));

@riverpod
JoinTicketUseCase joinTicketUseCase(Ref ref) =>
    JoinTicketUseCase(ref.watch(supportRepositoryProvider));

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
  Future<List<ConversationListEntry>> build() async {
    final queue = await ref
        .read(fetchQueueUseCaseProvider)
        .call(const FetchQueueParams());

    final tickets = queue.match(
      (failure) => throw Exception(failure.message),
      (value) => value,
    );

    // Deux sources, deux rôles. La file dit **quelles demandes existent** ; les
    // conversations disent **ce qui s'y est dit depuis**. Le ticket porte une
    // `description` figée à son ouverture : s'en contenter afficherait
    // éternellement le premier message, et une heure qui ne bouge jamais.
    final conversations = await ref
        .read(fetchConversationsUseCaseProvider)
        .call(const FetchConversationsParams());

    final byId = {
      for (final c in conversations.getOrElse((_) => const [])) c.id: c,
    };

    final me = ref.read(currentUserProvider)?.id;

    /// Complète un dossier avec ce que sa conversation sait de plus récent.
    SupportTicketEntity enrich(SupportTicketEntity ticket) {
      final c = byId[ticket.conversationId];
      if (c == null) return ticket;
      return ticket.withConversation(
        lastMessage: c.lastMessage,
        lastMessageType: c.lastMessageType,
        lastMessageAt: c.lastMessageAt,
        unreadCount: c.unreadCount,
      );
    }

    final entries = <ConversationListEntry>[
      for (final t in tickets) ConversationListEntry.fromTicket(enrich(t)),
    ];

    // Les conversations **sans dossier** — celles ouvertes depuis le
    // répertoire. Partir des seuls tickets les laissait invisibles, alors même
    // qu'on venait de les créer.
    final withTicket = {for (final t in tickets) t.conversationId};
    entries.addAll([
      for (final c in byId.values)
        if (!withTicket.contains(c.id))
          ConversationListEntry.fromConversation(c, me: me),
    ]);

    // Le plus récemment actif en tête, sur la date réelle du dernier échange.
    entries.sort((a, b) => b.date.compareTo(a.date));
    return entries;
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  /// Rejoint un ticket, puis recharge la file pour refléter la participation.
  ///
  /// Plusieurs agents peuvent suivre la même demande : rejoindre n'évince
  /// personne, contrairement à ce que « prendre en charge » laissait croire.
  Future<bool> join({required String ticketId, required String agentId}) async {
    final result = await ref
        .read(joinTicketUseCaseProvider)
        .call(JoinTicketParams(ticketId: ticketId, agentId: agentId));
    if (result.isRight()) await refresh();
    return result.isRight();
  }
}
