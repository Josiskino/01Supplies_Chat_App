import 'package:flutter_test/flutter_test.dart';
import 'package:supplies_chat_app/core/abstract/api_client_interface.dart';
import 'package:supplies_chat_app/core/abstract/failure.dart';
import 'package:supplies_chat_app/core/utils/api_types.dart';
import 'package:supplies_chat_app/data/datasources/remote/media_remote_datasource.dart';
import 'package:supplies_chat_app/data/repository/media_repository_impl.dart';
import 'package:supplies_chat_app/domain/repository/media/media_repository.dart';

/// Records the multipart upload instead of sending it.
class UploadClient extends ApiClientInterface {
  String? path;
  String? filePath;
  String? fileKey;
  HttpMethod? method;
  Map<String, dynamic>? additionalData;
  void Function(int sent, int total)? progress;
  Map<String, dynamic> envelope = {
    'statusCode': 201,
    'success': true,
    'data': {
      'id': '65f1c2aa0000000000000001',
      'url': 'https://storage.test/private/messages/a.pdf?sig=1',
      'mimeType': 'application/pdf',
      'size': 52428800,
      'originalName': 'a.pdf',
    },
  };
  int status = 201;

  @override
  Future<ApiResult<T>> uploadSingleFile<T>({
    String? baseUrl,
    required String path,
    required String filePath,
    required JsonParser<T> fromJson,
    String fileKey = 'file',
    Map<String, dynamic>? additionalData,
    Map<String, String>? headers,
    HttpMethod method = HttpMethod.post,
    void Function(int sent, int total)? onSendProgress,
  }) async {
    this.path = path;
    this.filePath = filePath;
    this.fileKey = fileKey;
    this.method = method;
    this.additionalData = additionalData;
    progress = onSendProgress;
    onSendProgress?.call(50, 100);
    if (status >= 400) {
      return ApiError(message: 'File too large', statusCode: status);
    }
    return ApiSuccess(data: fromJson(envelope), statusCode: status);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('documents upload to POST media/upload as private message '
      'attachments', () async {
    final client = UploadClient();
    final sent = <(int, int)>[];
    final result = await MediaRepositoryImpl(MediaRemoteDataSource(client))
        .upload(
          UploadMediaParams(
            '/tmp/a.pdf',
            onProgress: (s, t) => sent.add((s, t)),
          ),
        );
    expect(client.path, 'media/upload');
    expect(client.method, HttpMethod.post);
    expect(client.fileKey, 'file');
    expect(client.filePath, '/tmp/a.pdf');
    expect(client.additionalData, {'purpose': 'message_attachment'});
    expect(sent, [(50, 100)], reason: 'upload progress reaches the caller');
    final media = result.getRight().toNullable()!;
    expect(media.id, '65f1c2aa0000000000000001');
    expect(media.size, 52428800);
    expect(media.mimeType, 'application/pdf');
  });

  test('an unwrapped upload response is still parsed', () async {
    final client = UploadClient()
      ..envelope = {'_id': 'm2', 'secureUrl': 'https://storage.test/b.csv'};
    final result = await MediaRepositoryImpl(
      MediaRemoteDataSource(client),
    ).upload(const UploadMediaParams('/tmp/b.csv'));
    expect(result.getRight().toNullable()!.id, 'm2');
    expect(result.getRight().toNullable()!.url, 'https://storage.test/b.csv');
  });

  test('a server refusal (413) is a failure, never an empty media', () async {
    final client = UploadClient()..status = 413;
    final result = await MediaRepositoryImpl(
      MediaRemoteDataSource(client),
    ).upload(const UploadMediaParams('/tmp/big.pdf'));
    expect(result.isLeft(), isTrue);
    expect(result.getLeft().toNullable(), isA<Failure>());
  });
}
