import 'package:flutter_test/flutter_test.dart';
import 'package:supplies_chat_app/core/abstract/api_client_interface.dart';
import 'package:supplies_chat_app/core/utils/api_types.dart';
import 'package:supplies_chat_app/data/datasources/remote/message_remote_datasource.dart';

class RecordingClient extends ApiClientInterface {
  String? path;
  HttpMethod? method;
  Object? body;
  Map<String, dynamic>? query;
  @override
  Future<ApiResult<T>> request<T>({
    String? baseUrl,
    required String path,
    required HttpMethod method,
    required JsonParser<T> fromJson,
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    String? dataKey,
    List<MetadataConfig> metadataConfigs = const [],
    JsonParser<dynamic>? itemFromJson,
    List<String>? listPath,
  }) async {
    this.path = path;
    this.method = method;
    body = data;
    query = queryParameters;
    return ApiSuccess(data: fromJson({'data': <Object>[]}), statusCode: 200);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('history forwards before cursor while keeping page at one', () async {
    final client = RecordingClient();
    await MessageRemoteDataSource(
      client,
    ).fetchMessages(conversationId: 'c1', before: '2026-11-10T10:00:00Z');
    expect(client.query, containsPair('before', '2026-11-10T10:00:00Z'));
    expect(client.query!['page'], 1);
  });
  test('delivery acknowledges only messages actually received', () async {
    final client = RecordingClient();
    await MessageRemoteDataSource(
      client,
    ).markDelivered('c1', messageIds: ['m1']);
    expect(client.path, endsWith('/c1/delivered'));
    expect(client.method, HttpMethod.post);
    expect(client.body, {
      'messageIds': ['m1'],
    });
  });
  test('reaction persists through the documented toggle endpoint', () async {
    final client = RecordingClient();
    await MessageRemoteDataSource(client).react('m1', '👍');
    expect(client.path, endsWith('/m1/reactions'));
    expect(client.body, {'emoji': '👍'});
  });
}
