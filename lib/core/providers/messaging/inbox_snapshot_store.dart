import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../domain/entity/auth/user_role.dart';
import '../../../domain/entity/messaging/conversation_list_entry.dart';
import '../../abstract/local_storage_interface.dart';
import '../../services/local_storage/shared_preferences_storage.dart';

part 'inbox_snapshot_store.g.dart';

/// Last inbox successfully loaded, per account.
///
/// The inbox needs two API calls, and `GET /messaging/conversations` is
/// limited to 100 calls per user per 15 minutes. When that budget is spent
/// (or the network is down) a cold start used to show an empty list behind
/// an error banner for minutes. The snapshot is shown immediately on launch
/// and kept on screen until fresh data arrives.
abstract interface class InboxSnapshotStore {
  Future<List<ConversationListEntry>> load(String userId);
  Future<void> save(String userId, List<ConversationListEntry> entries);
}

class PreferencesInboxSnapshotStore implements InboxSnapshotStore {
  PreferencesInboxSnapshotStore(this._storage);

  final LocalStorageInterface _storage;

  /// The inbox shows the most recent conversations first; older rows come
  /// back with the network refresh.
  static const int maxEntries = 200;

  static String keyFor(String userId) => 'inbox_snapshot_$userId';

  @override
  Future<List<ConversationListEntry>> load(String userId) async {
    try {
      final raw = await _storage.getString(keyFor(userId));
      if (raw.isEmpty) return const [];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return [
        for (final item in decoded)
          if (item is Map) ?_decode(Map<String, dynamic>.from(item)),
      ];
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<void> save(String userId, List<ConversationListEntry> entries) async {
    try {
      await _storage.setString(
        keyFor(userId),
        jsonEncode([for (final e in entries.take(maxEntries)) encode(e)]),
      );
    } catch (_) {
      // Best effort: the snapshot only speeds up the next launch.
    }
  }

  static Map<String, Object?> encode(ConversationListEntry e) => {
    'id': e.conversationId,
    'title': e.title,
    'preview': e.preview,
    'date': e.date.toUtc().toIso8601String(),
    'avatarUrl': e.avatarUrl,
    'peerRole': e.peerRole?.wireName,
    'peerId': e.peerId,
    'unread': e.unreadCount,
    'ticketId': e.ticketId,
    'assigneeId': e.assigneeId,
    'assigneeName': e.assigneeName,
    'unclaimed': e.isUnclaimed,
    'support': e.isSupport,
    'orderNumber': e.orderNumber,
  };

  static ConversationListEntry? _decode(Map<String, dynamic> m) {
    final id = m['id'];
    final date = DateTime.tryParse('${m['date']}');
    if (id is! String || id.isEmpty || date == null) return null;
    final role = m['peerRole'];
    return ConversationListEntry(
      conversationId: id,
      title: m['title'] is String ? m['title'] as String : '',
      preview: m['preview'] is String ? m['preview'] as String : '',
      date: date.toLocal(),
      avatarUrl: m['avatarUrl'] as String?,
      peerRole: role is String
          ? UserRole.values.where((r) => r.wireName == role).firstOrNull
          : null,
      peerId: m['peerId'] as String?,
      unreadCount: m['unread'] is int ? m['unread'] as int : 0,
      ticketId: m['ticketId'] as String?,
      assigneeId: m['assigneeId'] as String?,
      assigneeName: m['assigneeName'] as String?,
      isUnclaimed: m['unclaimed'] == true,
      isSupport: m['support'] == true,
      orderNumber: m['orderNumber'] is String
          ? m['orderNumber'] as String
          : null,
    );
  }
}

/// Keeps snapshots for the lifetime of the process only (tests).
class InMemoryInboxSnapshotStore implements InboxSnapshotStore {
  final _byUser = <String, List<ConversationListEntry>>{};

  @override
  Future<List<ConversationListEntry>> load(String userId) async => [
    ...?_byUser[userId],
  ];

  @override
  Future<void> save(String userId, List<ConversationListEntry> entries) async {
    _byUser[userId] = [...entries];
  }
}

@Riverpod(keepAlive: true)
InboxSnapshotStore inboxSnapshotStore(Ref ref) =>
    PreferencesInboxSnapshotStore(SharedPreferencesStorage());
