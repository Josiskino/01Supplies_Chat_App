import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../abstract/failure.dart';

import '../../../data/datasources/abstract/messaging/support_datasource_contract.dart';
import '../../../data/datasources/remote/support_remote_datasource.dart';
import '../../../data/repository/support_repository_impl.dart';
import '../../../domain/entity/messaging/conversation_list_entry.dart';
import '../../../domain/entity/messaging/message_entity.dart';
import '../../../domain/entity/messaging/conversation_entity.dart';
import '../../../domain/entity/messaging/support_ticket_entity.dart';
import '../../utils/demo_data.dart';
import '../auth/auth_provider.dart';
import '../../../domain/repository/messaging/support_repository.dart';
import '../../../domain/usecases/messaging/support_usecases.dart';
import '../request/api_provider.dart';
import 'message_provider.dart';
import '../../../domain/repository/messaging/message_repository.dart';

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
  final _confirmedPreviews = <String>{};
  String? _activityOwner;
  String? _loadedOwner;
  final _unreadFloors = <String, int>{};
  final _receivedIds = <String>{};
  final _confirmedExchanges = <String>{};
  final _queueUnreadCache = <String, ({DateTime revision, int count})>{};
  final _localReadThrough = <String, DateTime>{};
  final _historyChecks = <String, ({DateTime revision, bool hasExchange})>{};
  final _unreadScans = <String, ({DateTime revision, int page, int count})>{};
  final _systemHistoryPages = <String, ({DateTime revision, int page})>{};
  Timer? _historyContinuation;
  DateTime _historyWindow = DateTime.fromMillisecondsSinceEpoch(0);
  int _historyReads = 0;
  DateTime? _historyRetryAt;

  void _historyFailed(Failure failure) {
    final seconds = failure is RateLimitFailure
        ? failure.retryAfterSeconds
        : 30;
    _historyRetryAt = DateTime.now().add(
      Duration(seconds: seconds.clamp(1, 3600)),
    );
    _scheduleHistoryContinuation();
  }

  void _scheduleHistoryContinuation() {
    final now = DateTime.now();
    var resumeAt = _historyWindow.add(const Duration(seconds: 30));
    if (_historyRetryAt != null && _historyRetryAt!.isAfter(resumeAt)) {
      resumeAt = _historyRetryAt!;
    }
    final delay = resumeAt.isAfter(now)
        ? resumeAt.difference(now)
        : const Duration(seconds: 30);
    final owner = _activityOwner;
    _historyContinuation?.cancel();
    _historyContinuation = Timer(delay, () {
      _historyContinuation = null;
      if (!ref.mounted ||
          _activityOwner != owner ||
          ref.read(currentUserProvider)?.id != owner) {
        return;
      }
      // The elapsed timer opens the next bounded window. Retain completed
      // counts and page cursors so a refresh continues rather than restarts.
      _historyWindow = DateTime.now();
      _historyReads = 0;
      _historyRetryAt = null;
      ref.invalidateSelf();
    });
  }

  bool _takeHistoryRead() {
    final now = DateTime.now();
    if (_historyRetryAt?.isAfter(now) == true) {
      _scheduleHistoryContinuation();
      return false;
    }
    if (now.difference(_historyWindow) >= const Duration(seconds: 30)) {
      _historyWindow = now;
      _historyReads = 0;
      _historyRetryAt = null;
    }
    if (_historyReads >= 4) {
      _scheduleHistoryContinuation();
      return false;
    }
    _historyReads++;
    return true;
  }

  @override
  Future<List<ConversationListEntry>> build() async {
    _historyContinuation?.cancel();
    _historyContinuation = null;
    ref.onDispose(() => _historyContinuation?.cancel());
    // Account changes rebuild this snapshot and discard all activity retained
    // for the previous session. Profile refreshes for the same account do not.
    final me = ref.watch(currentUserProvider)?.id;
    if (_activityOwner != me) {
      _activityOwner = me;
      _loadedOwner = null;
      _latestActivity.clear();
      _confirmedPreviews.clear();
      _unreadFloors.clear();
      _receivedIds.clear();
      _confirmedExchanges.clear();
      _queueUnreadCache.clear();
      _localReadThrough.clear();
      _historyChecks.clear();
      _unreadScans.clear();
      _systemHistoryPages.clear();
      _historyReads = 0;
      _historyRetryAt = null;
      _historyWindow = DateTime.fromMillisecondsSinceEpoch(0);
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
    final visibleIds = <String>{};
    var checkedSystemHistory = false;
    for (final c in [
      ...conversationList,
      for (final ticket in tickets)
        if (!byId.containsKey(ticket.conversationId))
          ConversationEntity(
            id: ticket.conversationId,
            updatedAt: ticket.updatedAt,
            lastMessage: ticket.lastMessage,
            lastMessageType: ticket.lastMessageType,
            lastMessageAt: ticket.lastMessageAt,
          ),
    ]) {
      if (hasExchange(c.lastMessage, c.lastMessageType)) {
        _confirmedExchanges.add(c.id);
        visibleIds.add(c.id);
      } else if (_confirmedExchanges.contains(c.id)) {
        visibleIds.add(c.id);
      } else if (c.lastMessageType == 'system') {
        final cached = _historyChecks[c.id];
        if (cached != null && cached.revision == c.sortDate) {
          if (cached.hasExchange) visibleIds.add(c.id);
          continue;
        }
        if (checkedSystemHistory) {
          visibleIds.add(c.id);
          _scheduleHistoryContinuation();
          continue;
        }
        checkedSystemHistory = true;
        // Reassignment is a system message; inspect history before hiding a
        // genuine exchange whose latest entry happens to be administrative.
        final cursor = _systemHistoryPages[c.id];
        for (
          var page = cursor?.revision == c.sortDate ? cursor!.page : 1;
          ;
          page++
        ) {
          if (!_takeHistoryRead()) {
            visibleIds.add(c.id);
            break;
          }
          final result = await ref
              .read(messageRepositoryProvider)
              .fetchMessages(
                FetchMessagesParams(
                  conversationId: c.id,
                  page: page,
                  limit: 100,
                ),
              );
          if (!ref.mounted || ref.read(currentUserProvider)?.id != me) {
            return const [];
          }
          if (result.isLeft()) {
            _historyFailed(result.getLeft().toNullable()!);
            visibleIds.add(c.id); // A failed read must not erase an inbox row.
            break;
          }
          final messages = result.getRight().toNullable()!;
          if (messages.any((m) => m.type != MessageType.system)) {
            _confirmedExchanges.add(c.id);
            _historyChecks[c.id] = (revision: c.sortDate, hasExchange: true);
            _systemHistoryPages.remove(c.id);
            visibleIds.add(c.id);
            break;
          }
          if (messages.length < 100) {
            _historyChecks[c.id] = (revision: c.sortDate, hasExchange: false);
            _systemHistoryPages.remove(c.id);
            break;
          }
          _systemHistoryPages[c.id] = (revision: c.sortDate, page: page + 1);
        }
      }
    }

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
        if (visibleIds.contains(t.conversationId) ||
            hasExchange(enrich(t).lastMessage, enrich(t).lastMessageType))
          ConversationListEntry.fromTicket(
            enrich(t),
            me: me,
            lastSender:
                byId[t.conversationId]?.sortDate == enrich(t).displayDate
                ? byId[t.conversationId]?.lastSender
                : null,
          ),
    ];

    // Les conversations **sans dossier** — celles ouvertes depuis le
    // répertoire. Partir des seuls tickets les laissait invisibles, alors même
    // qu'on venait de les créer.
    final withTicket = {for (final t in tickets) t.conversationId};
    entries.addAll([
      for (final c in byId.values)
        if (!withTicket.contains(c.id) && visibleIds.contains(c.id))
          ConversationListEntry.fromConversation(c, me: me),
    ]);

    // The API returns zero for viewers who are not active participants. In a
    // shared support queue, use authorized message history for those rows.
    entries.sort((a, b) => b.date.compareTo(a.date));
    for (var index = 0; index < entries.length; index++) {
      final entry = entries[index];
      final ticket = uniqueTickets[entry.conversationId];
      if (ticket == null || ticket.participantIds.contains(me)) continue;
      final cached = _queueUnreadCache[entry.conversationId];
      int? count;
      if (cached != null && cached.revision == entry.date) {
        count = cached.count;
      } else {
        final messageRepository = ref.read(messageRepositoryProvider);
        final previous = _unreadScans[entry.conversationId];
        final scan = previous?.revision == entry.date
            ? previous!
            : (revision: entry.date, page: 1, count: 0);
        _unreadScans[entry.conversationId] = scan;
        var unread = scan.count;
        var readThrough = _localReadThrough[entry.conversationId];
        for (var page = scan.page; ; page++) {
          if (!_takeHistoryRead()) break;
          final result = await messageRepository.fetchMessages(
            FetchMessagesParams(
              conversationId: entry.conversationId,
              page: page,
              limit: 100,
            ),
          );
          if (!ref.mounted || ref.read(currentUserProvider)?.id != me) {
            return const [];
          }
          if (result.isLeft()) {
            _historyFailed(result.getLeft().toNullable()!);
            break;
          }
          final messages = result.getRight().toNullable()!;
          final latestReadThrough = _localReadThrough[entry.conversationId];
          if (latestReadThrough != readThrough) {
            unread = 0;
            readThrough = latestReadThrough;
          }
          unread += messages
              .where(
                (message) =>
                    message.senderId == ticket.author?.id &&
                    message.type != MessageType.system &&
                    message.delivery != MessageDelivery.read &&
                    (readThrough == null ||
                        message.sentAt.isAfter(readThrough)),
              )
              .length;
          if (messages.length < 100) {
            count = unread;
            _queueUnreadCache[entry.conversationId] = (
              revision: entry.date,
              count: unread,
            );
            _unreadScans.remove(entry.conversationId);
            break;
          }
          _unreadScans[entry.conversationId] = (
            revision: entry.date,
            page: page + 1,
            count: unread,
          );
        }
      }
      if (count != null) entries[index] = _withUnread(entry, count);
    }

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
  static bool hasExchange(String? content, String? type) =>
      type != 'system' &&
      ((content?.trim().isNotEmpty ?? false) ||
          const ['audio', 'image', 'file'].contains(type));

  void markConversationRead(String id) {
    _unreadFloors.remove(id);
    _unreadScans.remove(id);
    _localReadThrough[id] = DateTime.now();
    final cached = _queueUnreadCache[id];
    if (cached != null) {
      _queueUnreadCache[id] = (revision: cached.revision, count: 0);
    }
    final entries = state.value;
    if (entries == null) return;
    final entry = entries
        .where((entry) => entry.conversationId == id)
        .firstOrNull;
    if (entry != null) {
      _queueUnreadCache[id] = (revision: entry.date, count: 0);
    }
    state = AsyncData([
      for (final entry in entries)
        if (entry.conversationId == id) _withUnread(entry, 0) else entry,
    ]);
  }

  void recordActivity(MessageEntity message, {bool received = false}) {
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
    if (received &&
        message.senderId != owner &&
        message.type != MessageType.system &&
        _receivedIds.add(message.id)) {
      final current =
          _unreadFloors[message.conversationId] ?? entry.unreadCount;
      _unreadFloors[message.conversationId] = current + 1;
    }
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
    _confirmedPreviews.add(message.conversationId);
    _latestActivity[message.conversationId] = (
      date: message.sentAt,
      preview: ConversationListEntry.formatPreview(
        preview,
        me: owner,
        sender: message.sender,
        senderId: message.senderId,
      ),
    );
    state = AsyncData(DemoData.maskEntries(_mergeActivity(entries)));
  }

  List<ConversationListEntry> _mergeActivity(
    List<ConversationListEntry> snapshot,
  ) {
    final entries = <ConversationListEntry>[];
    for (final entry in snapshot) {
      var known = _latestActivity[entry.conversationId];
      // A REST snapshot may lag behind a confirmed send even when its
      // timestamp has the same server precision. Keep the observed message
      // until the server reports a strictly newer one.
      if (known == null ||
          entry.date.isAfter(known.date) ||
          (entry.date.isAtSameMomentAs(known.date) &&
              !_confirmedPreviews.contains(entry.conversationId))) {
        _confirmedPreviews.remove(entry.conversationId);
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
          unreadCount:
              (_unreadFloors[entry.conversationId] ?? 0) > entry.unreadCount
              ? _unreadFloors[entry.conversationId]!
              : entry.unreadCount,
          ticketId: entry.ticketId,
          isSupport: entry.isSupport,
          peerRole: entry.peerRole,
          peerId: entry.peerId,
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

  static ConversationListEntry _withUnread(
    ConversationListEntry entry,
    int count,
  ) => ConversationListEntry(
    conversationId: entry.conversationId,
    title: entry.title,
    preview: entry.preview,
    date: entry.date,
    avatarUrl: entry.avatarUrl,
    unreadCount: count,
    ticketId: entry.ticketId,
    isSupport: entry.isSupport,
    peerRole: entry.peerRole,
    peerId: entry.peerId,
    assigneeId: entry.assigneeId,
    assigneeName: entry.assigneeName,
    isUnclaimed: entry.isUnclaimed,
  );

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
