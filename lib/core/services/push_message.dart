import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Plain payload shared by Firebase, local notifications and deterministic tests.
class PushMessage {
  PushMessage(
    Map<String, dynamic> payload, {
    this.id,
    this.notificationTitle,
    this.notificationBody,
  }) : data = normalize(payload);
  final Map<String, dynamic> data;
  final String? id;
  final String? notificationTitle;
  final String? notificationBody;
  factory PushMessage.fromRemote(RemoteMessage message) => PushMessage(
    message.data,
    id: message.messageId,
    notificationTitle: message.notification?.title,
    notificationBody: message.notification?.body,
  );
  static Map<String, dynamic> normalize(Map<String, dynamic> payload) {
    final result = Map<String, dynamic>.from(payload);
    Object? nested = result.remove('data');
    if (nested is String) {
      try {
        nested = jsonDecode(nested);
      } catch (_) {
        nested = null;
      }
    }
    if (nested is Map) {
      result.addAll(Map<String, dynamic>.from(nested));
    }
    return result;
  }

  String? get recipientId =>
      (data['_01chatAccountId'] ?? data['recipientId'] ?? data['accountId'])
          ?.toString();
  String? get dedupeId =>
      data['messageId']?.toString() ?? data['notificationId']?.toString() ?? id;
  String get title =>
      notificationTitle ?? data['title']?.toString() ?? '01 Chat';
  String get body =>
      notificationBody ??
      data['content']?.toString() ??
      data['preview']?.toString() ??
      data['body']?.toString() ??
      'Vous avez reçu un nouveau message.';
  PushMessage forSession(String account) => PushMessage(
    {...data, '_01chatAccountId': account},
    id: id,
    notificationTitle: notificationTitle,
    notificationBody: notificationBody,
  );
}
