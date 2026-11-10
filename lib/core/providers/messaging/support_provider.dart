import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/datasources/abstract/messaging/support_datasource_contract.dart';
import '../../../data/datasources/remote/support_remote_datasource.dart';
import '../../../data/repository/support_repository_impl.dart';
import '../../../domain/entity/messaging/conversation_list_entry.dart';
import '../../../domain/entity/messaging/message_entity.dart';
import '../../../domain/entity/messaging/support_ticket_entity.dart';
import '../../utils/demo_data.dart';
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
/// `/messaging/support` et non de `/support/me`, qui ne rend que les tickets
/// créés par le compte authentifié (la vue client).
@riverpod
class SupportQueue extends _$SupportQueue {
  final _latestActivity = <String, ({DateTime date, String preview})>{};
  String? _activityOwner;
  String? _loadedOwner;

  @override
  Future<List<ConversationListEntry>> build() async {
    // Account changes rebuild this snapshot and discard all activity retained
    // for the previous session. Profile refreshes for the same account do not.
    final me = ref.watch(currentUserProvider)?.id;
    if (_activityOwner != me) {
      _activityOwner = me;
      _loadedOwner = null;
      _latestActivity.clear();
    }
    final queue = await ref
        .read(fetchQueueUseCaseProvider)
        .call(const FetchQueueParams());

    final tickets = queue.match(
      (failure) => throw Exception(
        'Demandes de support indisponibles. ${failure.message}',
      ),
      (value) => value,
    );

    // Deux sources, deux rôles. La file dit **quelles demandes existent** ; les
    // conversations disent **ce qui s'y est dit depuis**. Le ticket porte une
    // `description` figée à son ouverture : s'en contenter afficherait
    // éternellement le premier message, et une heure qui ne bouge jamais.
    final conversations = await ref
        .read(fetchConversationsUseCaseProvider)
        .call(const FetchConversationsParams());

    final conversationList = conversations.match(
      (failure) =>
          throw Exception('Conversations indisponibles. ${failure.message}'),
      (value) => value,
    );
    final byId = {for (final c in conversationList) c.id: c};

    /// Complète un dossier avec ce que sa conversation sait de plus récent.
    SupportTicketEntity enrich(SupportTicketEntity ticket) {
      final c = byId[ticket.conversationId];
      if (c == null ||
          (ticket.lastMessageAt != null &&
              c.sortDate.isBefore(ticket.lastMessageAt!))) {
        return ticket;
      }
      return ticket.withConversation(
        lastMessage: c.lastMessage,
        lastMessageType: c.lastMessageType,
        lastMessageAt: c.sortDate,
        unreadCount: c.unreadCount,
      );
    }

    final uniqueTickets = {
      for (final ticket in tickets) ticket.conversationId: ticket,
    };
    final entries = <ConversationListEntry>[
      for (final t in uniqueTickets.values)
        ConversationListEntry.fromTicket(enrich(t)),
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

    if (!ref.mounted ||
        ref.read(currentUserProvider)?.id != me ||
        _activityOwner != me) {
      return const [];
    }
    _loadedOwner = me;
    return DemoData.maskEntries(_mergeActivity(entries));
  }

  /// Publish a confirmed message immediately, before reloading REST metadata.
  /// Only known inbox rows are updated: events cannot invent a route or grant
  /// access to a conversation absent from the authorized snapshot.
  void recordActivity(MessageEntity message) {
    final owner = ref.read(currentUserProvider)?.id;
    if (owner == null ||
        owner != _activityOwner ||
        owner != _loadedOwner ||
        message.isPending ||
        message.isFailed) {
      return;
    }
    final entries = state.value;
    if (entries == null) return;
    final entry = entries
        .where((e) => e.conversationId == message.conversationId)
        .firstOrNull;
    if (entry == null || message.sentAt.isBefore(entry.date)) return;
    final previous = _latestActivity[message.conversationId];
    if (previous != null && message.sentAt.isBefore(previous.date)) return;
    final content = message.content.trim();
    final preview = content.isNotEmpty
        ? content
        : switch (message.type) {
            MessageType.image => '📷 Photo',
            MessageType.audio => '🎤 Note vocale',
            MessageType.file => '📎 Fichier',
            _ => 'Aucun message',
          };
    _latestActivity[message.conversationId] = (
      date: message.sentAt,
      preview: preview,
    );
    state = AsyncData(
      DemoData.maskEntries(
        _mergeActivity(entries, preferRecordedOnEqual: true),
      ),
    );
  }

  List<ConversationListEntry> _mergeActivity(
    List<ConversationListEntry> snapshot, {
    bool preferRecordedOnEqual = false,
  }) {
    final entries = <ConversationListEntry>[];
    for (final entry in snapshot) {
      var known = _latestActivity[entry.conversationId];
      if (known == null ||
          entry.date.isAfter(known.date) ||
          (!preferRecordedOnEqual && entry.date.isAtSameMomentAs(known.date))) {
        known = (date: entry.date, preview: entry.preview);
        _latestActivity[entry.conversationId] = known;
      }
      entries.add(
        ConversationListEntry(
          conversationId: entry.conversationId,
          title: entry.title,
          preview: known.preview,
          date: known.date,
          avatarUrl: entry.avatarUrl,
          unreadCount: entry.unreadCount,
          ticketId: entry.ticketId,
          isSupport: entry.isSupport,
          assigneeId: entry.assigneeId,
          assigneeName: entry.assigneeName,
          isUnclaimed: entry.isUnclaimed,
        ),
      );
    }
    entries.sort((a, b) {
      final recent = b.date.compareTo(a.date);
      return recent != 0
          ? recent
          : a.conversationId.compareTo(b.conversationId);
    });
    return entries;
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  /// Rejoint un ticket, puis recharge la file pour refléter la participation.
  ///
  /// La prise en charge est exclusive : elle remplace l'ancien agent.
  /// L'identité est celle de la session authentifiée, jamais celle du corps.
  Future<bool> join({required String ticketId, required String agentId}) async {
    final result = await ref
        .read(joinTicketUseCaseProvider)
        .call(JoinTicketParams(ticketId: ticketId, agentId: agentId));
    if (result.isRight()) await refresh();
    return result.isRight();
  }
}
