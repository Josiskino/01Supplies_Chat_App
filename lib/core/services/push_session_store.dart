import 'package:shared_preferences/shared_preferences.dart';

const pushAccountPreferenceKey = 'chat_push_account';

abstract interface class PushSessionStore {
  Future<String?> readAccount();
  Future<void> writeAccount(String? account);
}

class SharedPreferencesPushSessionStore implements PushSessionStore {
  @override
  Future<String?> readAccount() async {
    final preferences = await SharedPreferences.getInstance();
    // Background isolates have their own cache. Never trust a cached login.
    await preferences.reload();
    return preferences.getString(pushAccountPreferenceKey);
  }

  @override
  Future<void> writeAccount(String? account) async {
    final preferences = await SharedPreferences.getInstance();
    if (account == null) {
      await preferences.remove(pushAccountPreferenceKey);
    } else {
      await preferences.setString(pushAccountPreferenceKey, account);
    }
  }
}
