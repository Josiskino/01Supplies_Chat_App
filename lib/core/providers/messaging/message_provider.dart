import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/datasources/abstract/messaging/message_datasource_contract.dart';
import '../../../data/datasources/remote/message_remote_datasource.dart';
import '../../../data/repository/message_repository_impl.dart';
import '../../../domain/entity/messaging/message_entity.dart';
import '../../../domain/repository/messaging/message_repository.dart';
import '../../../domain/usecases/messaging/message_usecases.dart';
import '../../abstract/failure.dart';
import '../../services/audio_recording_service.dart';
import '../auth/auth_provider.dart';
import '../../../domain/repository/media/media_repository.dart';
import '../media/media_provider.dart';
import '../realtime/realtime_provider.dart';
import '../realtime/push_provider.dart';
import 'support_provider.dart';
import '../request/api_provider.dart';

part 'message_provider.g.dart';

// ── Infrastructure ──────────────────────────────────────────────────────────

@riverpod
MessageDataSourceContract messageDataSource(Ref ref) =>
    MessageRemoteDataSource(ref.watch(apiClientProvider));

@riverpod
MessageRepository messageRepository(Ref ref) =>
    MessageRepositoryImpl(ref.watch(messageDataSourceProvider));

// ── Use cases ───────────────────────────────────────────────────────────────

@riverpod
FetchMessagesUseCase fetchMessagesUseCase(Ref ref) =>
    FetchMessagesUseCase(ref.watch(messageRepositoryProvider));

@riverpod
SendMessageUseCase sendMessageUseCase(Ref ref) =>
    SendMessageUseCase(ref.watch(messageRepositoryProvider));

@riverpod
MarkReadUseCase markReadUseCase(Ref ref) =>
    MarkReadUseCase(ref.watch(messageRepositoryProvider));

// ── Notifier ────────────────────────────────────────────────────────────────

/// Ce qu'un fil peut être.
///
/// « Non participant » est un **état**, pas un échec. Le représenter par une
/// exception le faisait retenter indéfiniment par Riverpod, avec son backoff
/// exponentiel : le fil repassait en chargement toutes les quelques secondes et
/// l'écran restait bloqué sur son indicateur, sans jamais afficher le motif.
sealed class ThreadState {
  const ThreadState();
}

/// Le fil est accessible.
class ThreadMessages extends ThreadState {
  const ThreadMessages(this.messages, {this.syncError});
  final String? syncError;
  final List<MessageEntity> messages;
}

/// Le dossier n'a pas été pris en charge : l'API refuse la lecture.
class ThreadLocked extends ThreadState {
  const ThreadLocked();
}

/// Le fil d'une conversation.
///
/// ## L'accès n'est pas acquis
///
/// Un admin qui n'a pas pris le dossier n'est **pas participant** : l'API
/// répond « Not a participant in this conversation ». C'est l'état normal d'un
/// ticket qui attend dans la file, et l'écran doit proposer de s'en saisir.
class OutgoingAttachment {
  OutgoingAttachment({
    required this.id,
    required this.paths,
    required this.type,
    required this.content,
    this.replyTo,
  });
  final String id;
  final List<String> paths;
  final MessageType type;
  final String content;
  final String? replyTo;
  final Map<String, String> mediaIds = {};
}

@riverpod
class Thread extends _$Thread {
  final Map<String, OutgoingAttachment> _outgoing = {};
  bool _sending = false;
  bool _refreshing = false;
  Completer<void>? _refreshDone;
  final Set<String> _deleted = {};
  final Set<String> _historyIds = {};
  void Function()? _releaseRetries;
  bool _refreshAgain = false;
  bool _reading = false;
  String? _readFingerprint;
  String? _owner;
  int _generation = 0;
  bool hasMore = true;
  bool loadingOlder = false;

  bool _current(String? owner, int generation) =>
      ref.mounted &&
      _generation == generation &&
      ref.read(currentUserIdProvider) == owner;

  List<MessageEntity> get _messages => switch (state.value) {
    ThreadMessages(:final messages) => messages,
    _ => const <MessageEntity>[],
  };

  @override
  Future<ThreadState> build(String conversationId) async {
    final owner = ref.watch(currentUserIdProvider);
    final generation = ++_generation;
    _owner = owner;
    for (final operation in _outgoing.values) {
      if (operation.type == MessageType.audio) {
        for (final path in operation.paths) {
          unawaited(deleteTemporaryVoiceRecording(path));
        }
      }
    }
    _outgoing.clear();
    _deleted.clear();
    _historyIds.clear();
    _releaseRetries?.call();
    _releaseRetries = null;
    _readFingerprint = null;
    hasMore = true;
    final repository = ref.read(messageRepositoryProvider);
    final result = await repository.fetchMessages(
      FetchMessagesParams(conversationId: conversationId),
    );
    if (!_current(owner, generation)) return const ThreadMessages([]);
    if (result.isLeft()) {
      final failure = result.getLeft().toNullable()!;
      if (failure is ForbiddenFailure) return const ThreadLocked();
      throw Exception(failure.message);
    }
    final messages = result.getRight().toNullable()!;
    hasMore = messages.length >= 50;
    _historyIds.addAll(messages.map((m) => m.id));
    final events = ref.read(messageEventsProvider);
    unawaited(events.watchConversation(conversationId));
    ref.onDispose(() => unawaited(events.unwatchConversation(conversationId)));
    final sub = events.threadChanges.listen((id) {
      if (id == conversationId && _current(owner, generation)) {
        unawaited(refresh());
      }
    });
    ref.onDispose(sub.cancel);
    final receipts = events.conversationEvents.listen((event) {
      if (event.conversationId != conversationId ||
          !_current(owner, generation)) {
        return;
      }
      final delivery = switch (event.eventName) {
        'message.read' => MessageDelivery.read,
        'message.delivered' => MessageDelivery.delivered,
        _ => null,
      };
      if (event.eventName == 'message.updated' ||
          event.eventName == 'message.reaction') {
        final id = (event.data['messageId'] ?? event.data['id'])?.toString();
        if (id != null) unawaited(_refreshMessage(id));
        return;
      }
      if (event.eventName == 'message.deleted') {
        final id = (event.data['messageId'] ?? event.data['id'])?.toString();
        if (id != null) {
          _deleted.add(id);
          state = AsyncData(ThreadMessages(_merge(_messages, const [])));
        }
        return;
      }
      if (delivery == null || event.data['userId'] == owner) return;
      final raw = event.data['messageIds'];
      final ids = raw is List ? raw.whereType<String>().toSet() : <String>{};
      if (ids.isEmpty) return;
      state = AsyncData(
        ThreadMessages(
          _messages
              .map(
                (m) =>
                    m.senderId == owner &&
                        ids.contains(m.id) &&
                        delivery.index > m.delivery.index
                    ? m.copyWith(delivery: delivery)
                    : m,
              )
              .toList(),
        ),
      );
    });
    ref.onDispose(receipts.cancel);
    return ThreadMessages(_merge(const [], messages));
  }

  List<MessageEntity> _merge(
    List<MessageEntity> current,
    List<MessageEntity> incoming,
  ) {
    final byId = {
      for (final message in current)
        if (!_deleted.contains(message.id)) message.id: message,
    };
    for (final message in incoming) {
      if (_deleted.contains(message.id)) {
        continue;
      }
      final old = byId[message.id];
      byId[message.id] =
          old != null && old.delivery.index > message.delivery.index
          ? message.copyWith(delivery: old.delivery)
          : message;
    }
    final merged = byId.values.toList()
      ..sort((a, b) {
        final date = a.sentAt.compareTo(b.sentAt);
        return date == 0 ? a.id.compareTo(b.id) : date;
      });
    return merged;
  }

  Future<bool> _ensureParticipation(String? owner, int generation) async {
    if (owner == null) return false;
    final snapshot = ref.read(supportQueueProvider);
    final queue = snapshot.isLoading
        ? await ref.read(supportQueueProvider.future)
        : snapshot.value ?? await ref.read(supportQueueProvider.future);
    if (!_current(owner, generation)) return false;
    var entry = queue
        ?.where((e) => e.conversationId == conversationId)
        .firstOrNull;
    if (entry == null) {
      // A direct conversation may have just been created from the directory.
      // Reconcile its authoritative type instead of guessing from absence.
      await ref.read(supportQueueProvider.notifier).refresh();
      if (!_current(owner, generation)) return false;
      entry = ref
          .read(supportQueueProvider)
          .value
          ?.where((e) => e.conversationId == conversationId)
          .firstOrNull;
    }
    if (entry == null) return false;
    if (entry.isSupport && entry.ticketId == null) return false;
    if (entry.ticketId == null || entry.assigneeId == owner) return true;
    final claimed = await ref
        .read(supportQueueProvider.notifier)
        .join(ticketId: entry.ticketId!, agentId: owner);
    // A failed send must never trigger an automatic ownership-stealing retry.
    return claimed && _current(owner, generation);
  }

  Future<bool> send(
    String content, {
    String? replyTo,
    MessageType type = MessageType.text,
    List<String> attachmentMediaIds = const [],
  }) async {
    if (_sending || (content.trim().isEmpty && attachmentMediaIds.isEmpty)) {
      return false;
    }
    final owner = _owner;
    final generation = _generation;
    final lease = ref.keepAlive();
    _sending = true;
    try {
      if (!await _ensureParticipation(owner, generation)) return false;
      return await _transmit(
        content.trim(),
        replyTo: replyTo,
        type: type,
        attachmentMediaIds: attachmentMediaIds,
        owner: owner,
        generation: generation,
      );
    } catch (_) {
      return false;
    } finally {
      _sending = false;
      lease.close();
    }
  }

  Future<bool> _transmit(
    String content, {
    String? replyTo,
    required MessageType type,
    required List<String> attachmentMediaIds,
    required String? owner,
    required int generation,
  }) async {
    final result = await ref
        .read(sendMessageUseCaseProvider)
        .call(
          SendMessageParams(
            conversationId: conversationId,
            content: content,
            replyTo: replyTo,
            type: type,
            attachmentMediaIds: attachmentMediaIds,
          ),
        );
    if (!_current(owner, generation)) return false;
    if (result.isLeft()) {
      ref.invalidate(supportQueueProvider);
      return false;
    }
    final message = result.getRight().toNullable()!;
    state = AsyncData(ThreadMessages(_merge(_messages, [message])));
    ref.read(supportQueueProvider.notifier).recordActivity(message);
    ref.invalidate(supportQueueProvider);
    return true;
  }

  Future<void> markRead() async {
    if (_reading || _messages.isEmpty) return;
    ref
        .read(supportQueueProvider.notifier)
        .markConversationRead(conversationId);
    final owner = _owner;
    final generation = _generation;
    final incoming = _messages.where(
      (m) => m.senderId != owner && !m.isPending && !m.isFailed,
    );
    final fingerprint = incoming.map((m) => m.id).join('|');
    if (fingerprint.isEmpty || fingerprint == _readFingerprint) return;
    _reading = true;
    try {
      await ref
          .read(pushNotificationsProvider)
          .markMessagesRead(incoming.map((m) => m.id));
      if (!_current(owner, generation)) return;
      // Reading a support thread is allowed before claiming; acknowledgements are not.
      final entry = ref
          .read(supportQueueProvider)
          .value
          ?.where((e) => e.conversationId == conversationId)
          .firstOrNull;
      if (entry?.ticketId != null && entry?.assigneeId != owner) return;
      final ids = incoming.map((m) => m.id).toList();
      for (var start = 0; start < ids.length; start += 100) {
        final end = start + 100 < ids.length ? start + 100 : ids.length;
        final result = await ref
            .read(markReadUseCaseProvider)
            .call(
              MarkReadParams(
                conversationId,
                messageIds: ids.sublist(start, end),
              ),
            );
        if (!_current(owner, generation) || result.isLeft()) return;
      }
      if (_current(owner, generation)) {
        _readFingerprint = fingerprint;
        ref.invalidate(supportQueueProvider);
      }
    } finally {
      _reading = false;
    }
  }

  Future<bool> sendAttachments({
    required List<String> filePaths,
    required MessageType type,
    String content = '',
    String? replyTo,
  }) async {
    if (filePaths.isEmpty || filePaths.length > 10) return false;
    final operation = OutgoingAttachment(
      id: 'pending-${DateTime.now().microsecondsSinceEpoch}',
      paths: List.unmodifiable(filePaths),
      type: type,
      content: content,
      replyTo: replyTo,
    );
    _outgoing[operation.id] = operation;
    if (_sending) {
      final failed = MessageEntity(
        id: operation.id,
        conversationId: conversationId,
        senderId: _owner ?? '',
        sender: ref.read(currentUserProvider),
        content: content,
        type: type,
        delivery: MessageDelivery.sent,
        sentAt: DateTime.now(),
        attachments: operation.paths,
        replyToId: replyTo,
        isFailed: true,
      );
      state = AsyncData(ThreadMessages(_merge(_messages, [failed])));
      _releaseRetries ??= ref.keepAlive().close;
      return false;
    }
    return _sendAttachment(operation);
  }

  Future<void> discardAttachment(String id) async {
    if (_sending) return;
    final operation = _outgoing.remove(id);
    if (operation == null) return;
    if (_outgoing.isEmpty) {
      _releaseRetries?.call();
      _releaseRetries = null;
    }
    state = AsyncData(
      ThreadMessages(_messages.where((m) => m.id != id).toList()),
    );
    if (operation.type == MessageType.audio) {
      for (final path in operation.paths) {
        await deleteTemporaryVoiceRecording(path);
      }
    }
  }

  Future<bool> retryAttachment(String id) async {
    final operation = _outgoing[id];
    return operation != null && !_sending ? _sendAttachment(operation) : false;
  }

  Future<bool> _sendAttachment(OutgoingAttachment operation) async {
    final owner = _owner;
    final generation = _generation;
    final lease = ref.keepAlive();
    _sending = true;
    final pending = MessageEntity(
      id: operation.id,
      conversationId: conversationId,
      senderId: owner ?? '',
      sender: ref.read(currentUserProvider),
      content: operation.content,
      type: operation.type,
      delivery: MessageDelivery.sent,
      sentAt: DateTime.now(),
      attachments: operation.paths,
      replyToId: operation.replyTo,
      isPending: true,
    );
    state = AsyncData(ThreadMessages(_merge(_messages, [pending])));
    bool sent = false;
    try {
      if (!await _ensureParticipation(owner, generation)) return false;
      for (final path in operation.paths) {
        if (operation.mediaIds.containsKey(path)) continue;
        final upload = await ref
            .read(uploadMediaUseCaseProvider)
            .call(UploadMediaParams(path));
        if (!_current(owner, generation)) return false;
        final media = upload.getRight().toNullable();
        if (media == null || media.id.isEmpty) return false;
        operation.mediaIds[path] = media.id;
      }
      sent = await _transmit(
        operation.content,
        replyTo: operation.replyTo,
        type: operation.type,
        attachmentMediaIds: operation.paths
            .map((p) => operation.mediaIds[p]!)
            .toList(),
        owner: owner,
        generation: generation,
      );
      return sent;
    } catch (_) {
      return false;
    } finally {
      if (_current(owner, generation)) {
        final retained = _messages.where((m) => m.id != operation.id).toList();
        if (sent) {
          _outgoing.remove(operation.id);
          for (final path in operation.paths) {
            if (operation.type == MessageType.audio) {
              unawaited(deleteTemporaryVoiceRecording(path));
            }
          }
        } else {
          retained.add(pending.copyWith(isPending: false, isFailed: true));
        }
        state = AsyncData(ThreadMessages(_merge(const [], retained)));
      }
      if (_outgoing.isEmpty) {
        _releaseRetries?.call();
        _releaseRetries = null;
      } else if (_current(owner, generation)) {
        _releaseRetries ??= ref.keepAlive().close;
      }
      _sending = false;
      lease.close();
    }
  }

  Future<String?> refreshVoiceSource(String messageId) async {
    final owner = _owner;
    final generation = _generation;
    final message = _messages.where((m) => m.id == messageId).firstOrNull;
    final mediaId = message?.attachmentMediaIds.firstOrNull;
    if (mediaId != null) {
      final result = await ref.read(mediaRepositoryProvider).getById(mediaId);
      if (!_current(owner, generation)) return null;
      return result.getRight().toNullable()?.url;
    }
    await _refreshMessage(messageId);
    if (!_current(owner, generation)) return null;
    return _messages
        .where((m) => m.id == messageId)
        .firstOrNull
        ?.attachments
        .firstOrNull;
  }

  Future<bool> react(String messageId, String emoji) => _mutate(
    (repository) => repository.react(messageId, emoji),
    targetId: messageId,
  );

  Future<bool> edit(String messageId, String content) => _mutate(
    (repository) => repository.edit(messageId, content),
    targetId: messageId,
  );

  Future<bool> delete(String messageId) async {
    final owner = _owner;
    final generation = _generation;
    final result = await ref.read(messageRepositoryProvider).delete(messageId);
    if (!_current(owner, generation) || result.isLeft()) return false;
    _deleted.add(messageId);
    state = AsyncData(ThreadMessages(_merge(_messages, const [])));
    ref.invalidate(supportQueueProvider);
    return true;
  }

  Future<bool> _mutate(
    Future<dynamic> Function(MessageRepository) action, {
    String? targetId,
  }) async {
    final owner = _owner;
    final generation = _generation;
    try {
      final result = await action(ref.read(messageRepositoryProvider));
      if (!_current(owner, generation) || !result.isRight()) return false;
      if (targetId != null) {
        await _refreshMessage(targetId);
      } else {
        await refresh();
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _refreshMessage(String id) async {
    final message = _messages.where((m) => m.id == id).firstOrNull;
    if (message == null) return;
    final owner = _owner;
    final generation = _generation;
    final result = await ref
        .read(fetchMessagesUseCaseProvider)
        .call(
          FetchMessagesParams(
            conversationId: conversationId,
            limit: 100,
            before: message.sentAt
                .toUtc()
                .add(const Duration(milliseconds: 1))
                .toIso8601String(),
          ),
        );
    if (!_current(owner, generation)) return;
    result.match((_) {}, (page) {
      final target = page.where((m) => m.id == id).toList();
      if (target.isNotEmpty) {
        state = AsyncData(ThreadMessages(_merge(_messages, target)));
      }
    });
  }

  Future<void> loadOlder() async {
    if (loadingOlder || !hasMore || _messages.isEmpty) return;
    final owner = _owner;
    final generation = _generation;
    loadingOlder = true;
    try {
      final oldest = _messages
          .where((m) => !m.isPending && !m.isFailed)
          .firstOrNull;
      if (oldest == null) return;
      final result = await ref
          .read(fetchMessagesUseCaseProvider)
          .call(
            FetchMessagesParams(
              conversationId: conversationId,
              before: oldest.sentAt.toUtc().toIso8601String(),
            ),
          );
      if (!_current(owner, generation)) return;
      result.match((_) {}, (messages) {
        hasMore = messages.length >= 50;
        state = AsyncData(ThreadMessages(_merge(_messages, messages)));
      });
    } finally {
      loadingOlder = false;
    }
  }

  Future<void> refresh() async {
    if (_refreshing) {
      _refreshAgain = true;
      await _refreshDone?.future;
      return;
    }
    final owner = _owner;
    final generation = _generation;
    _refreshing = true;
    final completion = Completer<void>();
    _refreshDone = completion;
    try {
      do {
        _refreshAgain = false;
        final known = Set<String>.of(_historyIds);
        var collected = <MessageEntity>[];
        String? cursor;
        var failed = false;
        while (true) {
          final result = await ref
              .read(fetchMessagesUseCaseProvider)
              .call(
                FetchMessagesParams(
                  conversationId: conversationId,
                  before: cursor,
                ),
              );
          if (!_current(owner, generation)) return;
          if (result.isLeft()) {
            failed = true;
            break;
          }
          final page = result.getRight().toNullable()!;
          collected = _merge(collected, page);
          if (page.length < 50 ||
              known.isEmpty ||
              page.any((m) => known.contains(m.id))) {
            break;
          }
          final oldest = page.first.sentAt.toUtc();
          if (cursor != null && !oldest.isBefore(DateTime.parse(cursor))) {
            failed = true;
            break;
          }
          cursor = oldest.toIso8601String();
        }
        if (failed) {
          state = AsyncData(
            ThreadMessages(
              _messages,
              syncError: 'Actualisation impossible. Réessayez.',
            ),
          );
        } else {
          _historyIds.addAll(collected.map((m) => m.id));
          state = AsyncData(ThreadMessages(_merge(_messages, collected)));
        }
      } while (_refreshAgain && _current(owner, generation));
    } finally {
      _refreshing = false;
      completion.complete();
      if (identical(_refreshDone, completion)) _refreshDone = null;
    }
  }
}

/// Identifiant du compte connecté, pour distinguer ses propres bulles.
@riverpod
String? currentUserId(Ref ref) => ref.watch(currentUserProvider)?.id;
