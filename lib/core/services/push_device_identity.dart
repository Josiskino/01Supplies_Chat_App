import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

/// An app-installation identity, independent of the rotating FCM token and
/// account. Different 01 apps must never overwrite each other's device record.
class PushDeviceIdentity {
  static const preferenceKey = 'chat_push_installation_id';
  Future<String>? _identity;

  Future<String> getDeviceId() => _identity ??= _load();

  Future<String> _load() async {
    final preferences = await SharedPreferences.getInstance();
    final existing = preferences.getString(preferenceKey);
    if (existing != null && existing.isNotEmpty) return existing;
    final random = Random.secure();
    final identifier =
        '01chat-${List.generate(24, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join()}';
    await preferences.setString(preferenceKey, identifier);
    return identifier;
  }
}
