import 'package:flutter_test/flutter_test.dart';
import 'package:supplies_chat_app/core/utils/log_redaction.dart';

void main() {
  test(
    'FCM device registration and revoke tokens are redacted in nested payloads',
    () {
      final original = {
        'platform': 'android',
        'devices': [
          {'fcmToken': 'private-registration-token'},
          {
            'nested': {'fcm_token': 'private-revocation-token'},
          },
        ],
      };
      final redacted = LogRedaction.redact(original).toString();
      expect(redacted, isNot(contains('private-registration-token')));
      expect(redacted, isNot(contains('private-revocation-token')));
      expect(redacted, contains('android'));
      expect(redacted, contains('masqué'));
      expect(original.toString(), contains('private-registration-token'));
    },
  );
  test('push token spelling variants are case insensitive and normalized', () {
    final redacted = LogRedaction.redact({
      'FCM_TOKEN': 'private-fcm',
      'deviceToken': 'private-device',
      'push_token': 'private-push',
      'authorization': 'private-auth',
    }).toString();
    expect(redacted, isNot(contains('private-')));
  });
  test('depth cutoff never returns an unredacted private subtree', () {
    Object? payload = {'fcmToken': 'private-deep-token'};
    for (var i = 0; i < 8; i++) {
      payload = {'nested': payload};
    }
    expect(
      LogRedaction.redact(payload).toString(),
      isNot(contains('private-deep-token')),
    );
  });
}
