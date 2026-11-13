import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../abstract/local_storage_interface.dart';
import '../../services/local_storage/shared_preferences_storage.dart';

part 'read_watermark_store.g.dart';

/// Per-account "read through" timestamps, one per conversation.
///
/// ## Why it exists
///
/// An agent who reads a support thread without claiming it is not a
/// participant: the API refuses his read acknowledgement (`POST
/// /conversations/{id}/read` answers 403). Until the backend stores a shared
/// read state for support conversations, the only record of that read is on
/// this device. Keeping it in memory made every read vanish on restart, and
/// the badges came back as if the messages had just arrived.
///
/// The timestamps are server times (the `sentAt` of the newest message seen),
/// never the device clock, so a skewed clock cannot hide a later message.
abstract interface class ReadWatermarkStore {
  Future<Map<String, DateTime>> load(String userId);
  Future<void> save(String userId, Map<String, DateTime> watermarks);
}

/// [ReadWatermarkStore] on the app's key/value storage.
class PreferencesReadWatermarkStore implements ReadWatermarkStore {
  PreferencesReadWatermarkStore(this._storage);

  final LocalStorageInterface _storage;

  /// Bounds the stored map: only the most recent reads matter for badges.
  static const int maxEntries = 500;

  static String keyFor(String userId) => 'read_watermarks_$userId';

  @override
  Future<Map<String, DateTime>> load(String userId) async {
    try {
      final raw = await _storage.getString(keyFor(userId));
      if (raw.isEmpty) return {};
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      return {
        for (final entry in decoded.entries)
          if (entry.value is String &&
              DateTime.tryParse(entry.value as String) != null)
            entry.key.toString(): DateTime.parse(entry.value as String),
      };
    } catch (_) {
      // Unreadable storage only costs the local read state; never the inbox.
      return {};
    }
  }

  @override
  Future<void> save(String userId, Map<String, DateTime> watermarks) async {
    final newest = watermarks.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final kept = newest.take(maxEntries);
    try {
      await _storage.setString(
        keyFor(userId),
        jsonEncode({
          for (final entry in kept)
            entry.key: entry.value.toUtc().toIso8601String(),
        }),
      );
    } catch (_) {
      // Best effort: the in-memory state still covers the current session.
    }
  }
}

/// Keeps watermarks for the lifetime of the process only (tests).
class InMemoryReadWatermarkStore implements ReadWatermarkStore {
  final _byUser = <String, Map<String, DateTime>>{};

  @override
  Future<Map<String, DateTime>> load(String userId) async => {
    ...?_byUser[userId],
  };

  @override
  Future<void> save(String userId, Map<String, DateTime> watermarks) async {
    _byUser[userId] = {...watermarks};
  }
}

@Riverpod(keepAlive: true)
ReadWatermarkStore readWatermarkStore(Ref ref) =>
    PreferencesReadWatermarkStore(SharedPreferencesStorage());
