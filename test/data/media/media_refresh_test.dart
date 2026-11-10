import 'package:flutter_test/flutter_test.dart';
import 'package:supplies_chat_app/core/abstract/api_client_interface.dart';
import 'package:supplies_chat_app/core/abstract/failure.dart';
import 'package:supplies_chat_app/core/utils/api_types.dart';
import 'package:supplies_chat_app/data/datasources/remote/media_remote_datasource.dart';
import 'package:supplies_chat_app/data/models/messaging/message_model.dart';
import 'package:supplies_chat_app/data/repository/media_repository_impl.dart';
import 'package:supplies_chat_app/domain/entity/messaging/message_entity.dart';

class MediaClient extends ApiClientInterface {
  String? path;
  HttpMethod? method;
  String? selectedDataKey;
  int statusCode = 200;
  @override
  Future<ApiResult<T>> request<T>({String? baseUrl, required String path,
    required HttpMethod method, required JsonParser<T> fromJson, Object? data,
    Map<String, dynamic>? queryParameters, Map<String, String>? headers,
    String? dataKey, List<MetadataConfig> metadataConfigs = const [],
    JsonParser<dynamic>? itemFromJson, List<String>? listPath}) async {
    this.path = path; this.method = method; selectedDataKey = dataKey;
    if (statusCode != 200) return ApiError(message: 'Forbidden', statusCode: statusCode);
    return ApiSuccess(data: fromJson({'id': 'media-1', 'url': 'https://example.com/fresh.m4a', 'mimeType': 'audio/mp4'}), statusCode: 200);
  }
  @override dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('explicit and populated media identifiers survive model and entity copying', () {
    final entity = MessageModel.fromJson({
      'id': 'message', 'conversationId': 'conversation', 'senderId': 'author',
      'content': '', 'type': 'audio', 'status': 'delivered',
      'createdAt': '2026-11-10T10:00:00Z', 'replyTo': 'parent',
      'attachmentMediaIds': ['media-1', 'media-1'],
      'attachmentMedia': [ {'id': 'media-1', 'url': 'https://example.com/expired.m4a'} ],
    }).toEntity();
    expect(entity.attachmentMediaIds, ['media-1']);
    final copy = entity.copyWith(delivery: MessageDelivery.read, isFailed: true);
    expect(copy.attachmentMediaIds, ['media-1']);
    expect(copy.attachments, ['https://example.com/expired.m4a']);
    expect(copy.replyToId, 'parent');
    expect(copy.senderId, 'author');
    expect(copy.type, MessageType.audio);
  });
  test('populated attachment objects provide IDs when flat identifiers are absent', () {
    final entity = MessageModel.fromJson({
      'attachments': [ {'_id': 'media-1', 'url': 'https://example.com/old.m4a'} ],
      'attachmentMedia': [ {'id': 'media-1', 'url': 'https://example.com/old.m4a'}, {'id': 'media-2', 'url': 'https://example.com/second.m4a'} ],
    }).toEntity();
    expect(entity.attachmentMediaIds, ['media-1', 'media-2']);
  });
  test('media repository fetches a newly signed URL through the media endpoint', () async {
    final client = MediaClient();
    final repository = MediaRepositoryImpl(MediaRemoteDataSource(client));
    final result = await repository.getById('media-1');
    expect(client.path, 'media/media-1');
    expect(client.method, HttpMethod.get);
    expect(client.selectedDataKey, 'data');
    expect(result.getRight().toNullable()?.url, 'https://example.com/fresh.m4a');
  });
  test('private media read preserves authorization failures', () async {
    final client = MediaClient()..statusCode = 403;
    final repository = MediaRepositoryImpl(MediaRemoteDataSource(client));
    final result = await repository.getById('media-1');
    expect(result.getLeft().toNullable(), isA<ForbiddenFailure>());
  });
}
