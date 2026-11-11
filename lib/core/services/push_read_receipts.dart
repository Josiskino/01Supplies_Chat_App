import 'package:shared_preferences/shared_preferences.dart';

int pushNotificationIdentifier(String key) {
  var identifier = 0x811c9dc5;
  for (final unit in key.codeUnits) {
    identifier = ((identifier ^ unit) * 0x01000193) & 0x7fffffff;
  }
  return identifier;
}

String _readKey(String account) => 'chat_push_read_messages_$account';
Future<void> _writes = Future.value();

Future<bool> isReadPushMessage(String account, String? messageId) async {
  if (messageId == null || messageId.isEmpty) return false;
  final preferences = await SharedPreferences.getInstance();
  await preferences.reload();
  return preferences.getStringList(_readKey(account))?.contains(messageId) ??
      false;
}

Future<void> rememberReadPushMessages(String account, Iterable<String> ids) {
  final snapshot = ids.where((id) => id.isNotEmpty).toList();
  _writes = _writes.catchError((Object _) {}).then((_) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.reload();
    final merged = <String>{
      ...?preferences.getStringList(_readKey(account)),
      ...snapshot,
    }.toList();
    await preferences.setStringList(
      _readKey(account),
      merged.length > 1000 ? merged.sublist(merged.length - 1000) : merged,
    );
  });
  return _writes;
}
