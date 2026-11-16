import 'dart:async';
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'push_message.dart';
import 'push_read_receipts.dart';

abstract interface class PushLocalNotifications {
  Future<void> initialize();
  Future<void> show(PushMessage message);
  Future<void> cancelAll();
  Future<void> cancelMessages(Iterable<String> messageIds);
  Stream<PushMessage> get openedMessages;
  Future<PushMessage?> getInitialMessage();
  Future<void> dispose();
}

class NativePushLocalNotifications implements PushLocalNotifications {
  final _plugin = FlutterLocalNotificationsPlugin();
  Future<void>? _initializing;
  bool _disposed = false;

  /// Taps are published on one stream per isolate, not per instance.
  ///
  /// `FlutterLocalNotificationsPlugin` is a process-wide singleton and every
  /// `initialize` call replaces its single tap callback. On iOS the Firebase
  /// background handler runs in the main isolate and builds its own instance
  /// to display a data-only push: its `initialize` used to steal the callback,
  /// so taps were published on a stream nobody listened to and the
  /// conversation never opened. Android runs that handler in a separate
  /// isolate, which is why it kept working there. A shared stream makes the
  /// last `initialize` irrelevant.
  static final _sharedOpened = StreamController<PushMessage>.broadcast();

  static void _handleResponse(NotificationResponse response) {
    final message = decodePayload(response.payload);
    if (message != null) _sharedOpened.add(message);
  }

  @override
  Stream<PushMessage> get openedMessages =>
      _sharedOpened.stream.where((_) => !_disposed);
  @override
  Future<void> initialize() => _initializing ??= _initialize();
  Future<void> _initialize() async {
    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_chat'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: _handleResponse,
    );
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    for (final channel in const [
      AndroidNotificationChannel(
        '01supplies_default',
        'Notifications',
        importance: Importance.high,
      ),
      AndroidNotificationChannel(
        '01chat_messages',
        'Messages',
        importance: Importance.high,
      ),
    ]) {
      await android?.createNotificationChannel(channel);
    }
  }

  static PushMessage? decodePayload(String? payload) {
    if (payload == null) {
      return null;
    }
    try {
      final data = jsonDecode(payload);
      return data is Map ? PushMessage(Map<String, dynamic>.from(data)) : null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<PushMessage?> getInitialMessage() async {
    await initialize();
    final details = await _plugin.getNotificationAppLaunchDetails();
    return details?.didNotificationLaunchApp == true
        ? decodePayload(details?.notificationResponse?.payload)
        : null;
  }

  @override
  Future<void> show(PushMessage message) async {
    await initialize();
    final key =
        message.dedupeId ??
        '${message.data['type']}:${message.data['conversationId']}:${message.data['createdAt']}';
    final identifier = pushNotificationIdentifier(key);
    await _plugin.show(
      identifier,
      message.title,
      message.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          '01chat_messages',
          'Messages',
          channelDescription: 'Messages 01 Chat',
          importance: Importance.high,
          priority: Priority.high,
          icon: 'ic_stat_chat',
        ),
        iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
      ),
      payload: jsonEncode(message.data),
    );
  }

  @override
  Future<void> cancelAll() async {
    await initialize();
    await _plugin.cancelAll();
  }

  @override
  Future<void> cancelMessages(Iterable<String> messageIds) async {
    await initialize();
    for (final id in messageIds.toSet()) {
      if (id.isNotEmpty) await _plugin.cancel(pushNotificationIdentifier(id));
    }
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
  }
}
