import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:supplies_chat_app/core/abstract/api_client_interface.dart';
import 'package:supplies_chat_app/core/abstract/failure.dart';
import 'package:supplies_chat_app/core/providers/media/media_provider.dart';
import 'package:supplies_chat_app/core/providers/messaging/message_provider.dart';
import 'package:supplies_chat_app/core/providers/messaging/support_provider.dart';
import 'package:supplies_chat_app/core/providers/realtime/push_provider.dart';
import 'package:supplies_chat_app/core/providers/realtime/realtime_provider.dart';
import 'package:supplies_chat_app/core/utils/api_types.dart';
import 'package:supplies_chat_app/data/datasources/remote/message_remote_datasource.dart';
import 'package:supplies_chat_app/domain/entity/media/media_upload_entity.dart';
import 'package:supplies_chat_app/domain/entity/messaging/message_attachment_entity.dart';
import 'package:supplies_chat_app/domain/entity/messaging/message_entity.dart';
import 'package:supplies_chat_app/domain/repository/media/media_repository.dart';
import 'package:supplies_chat_app/domain/repository/messaging/message_repository.dart';

import 'thread_reliability_test.dart'
    show FakeEvents, FakeMessages, FakeQueue, FakeReadNotifications;

class RecordingMessages extends FakeMessages {
  final sent = <SendMessageParams>[];
  @override
  Future<Either<Failure, MessageEntity>> sendMessage(SendMessageParams p) {
    sent.add(p);
    return super.sendMessage(p);
  }
}

class FakeMedia implements MediaRepository {
  final uploads = <String>[];
  final renewals = <String>[];
  bool failUpload = false;
  String? freshUrl = 'https://storage.test/a.pdf?sig=new';

  @override
  Future<Either<Failure, MediaUploadEntity>> upload(
    UploadMediaParams params,
  ) async {
    uploads.add(params.filePath);
    params.onProgress?.call(0, 0);
    params.onProgress?.call(25, 100);
    params.onProgress?.call(100, 100);
    if (failUpload) return Left(NetworkFailure('offline'));
    return Right(
      MediaUploadEntity(id: 'media-${uploads.length}', url: 'https://s/x'),
    );
  }

  @override
  Future<Either<Failure, MediaUploadEntity>> getById(String mediaId) async {
    renewals.add(mediaId);
    final url = freshUrl;
    return url == null
        ? Left(ForbiddenFailure('no access'))
        : Right(MediaUploadEntity(id: mediaId, url: url));
  }
}

/// Captures the JSON body of a send.
class BodyClient extends ApiClientInterface {
  Object? data;
  String? path;
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
    this.data = data;
    this.path = path;
    return const ApiError(message: 'stop', statusCode: 500);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late RecordingMessages messages;
  late FakeMedia media;
  late ProviderContainer container;

  Future<Thread> setup() async {
    messages = RecordingMessages();
    media = FakeMedia();
    final events = FakeEvents();
    container = ProviderContainer(
      overrides: [
        pushNotificationsProvider.overrideWithValue(FakeReadNotifications()),
        currentUserIdProvider.overrideWithValue('me'),
        messageRepositoryProvider.overrideWithValue(messages),
        messageEventsProvider.overrideWithValue(events),
        mediaRepositoryProvider.overrideWithValue(media),
        supportQueueProvider.overrideWith(
          () => FakeQueue(messages.calls, support: false),
        ),
      ],
    );
    final subscription = container.listen(threadProvider('c1'), (_, _) {});
    addTearDown(() {
      subscription.close();
      container.dispose();
      events.changes.close();
    });
    await container.read(supportQueueProvider.future);
    await container.read(threadProvider('c1').future);
    return container.read(threadProvider('c1').notifier);
  }

  List<MessageEntity> thread() =>
      (container.read(threadProvider('c1')).requireValue as ThreadMessages)
          .messages;

  const details = [
    MessageAttachmentEntity(
      url: '/tmp/devis.pdf',
      name: 'devis.pdf',
      size: 2048,
      mimeType: 'application/pdf',
    ),
  ];

  test(
    'a document is uploaded then sent as type file with its media id',
    () async {
      final notifier = await setup();
      final progress = <double>[];
      final sending = notifier.sendAttachments(
        filePaths: ['/tmp/devis.pdf'],
        type: MessageType.file,
        content: 'devis.pdf',
        details: details,
      );
      final pending = thread().singleWhere((m) => m.isPending);
      expect(pending.type, MessageType.file);
      expect(pending.attachmentDetails.single.name, 'devis.pdf');
      notifier
          .uploadProgress(pending.id)!
          .addListener(
            () => progress.add(notifier.uploadProgress(pending.id)!.value),
          );
      expect(await sending, isTrue);
      expect(media.uploads, ['/tmp/devis.pdf']);
      final sent = messages.sent.single;
      expect(sent.type, MessageType.file);
      expect(sent.content, 'devis.pdf');
      expect(sent.attachmentMediaIds, ['media-1']);
      expect(progress, [0.25, 1.0], reason: 'a zero total is ignored');
      expect(notifier.uploadProgress(pending.id), isNull);
    },
  );

  test('a failed upload keeps a retryable bubble, and retry re-uploads only '
      'what is missing', () async {
    final notifier = await setup();
    media.failUpload = true;
    expect(
      await notifier.sendAttachments(
        filePaths: ['/tmp/devis.pdf'],
        type: MessageType.file,
        content: 'devis.pdf',
        details: details,
      ),
      isFalse,
    );
    final failed = thread().singleWhere((m) => m.isFailed);
    expect(failed.attachmentDetails.single.size, 2048);
    expect(messages.sent, isEmpty);

    media.failUpload = false;
    expect(await notifier.retryAttachment(failed.id), isTrue);
    expect(media.uploads, hasLength(2));
    expect(messages.sent.single.attachmentMediaIds, ['media-2']);
    expect(thread().where((m) => m.isFailed), isEmpty);
  });

  test(
    'a discarded document disappears and its progress is released',
    () async {
      final notifier = await setup();
      media.failUpload = true;
      await notifier.sendAttachments(
        filePaths: ['/tmp/devis.pdf'],
        type: MessageType.file,
        details: details,
      );
      final failed = thread().singleWhere((m) => m.isFailed);
      await notifier.discardAttachment(failed.id);
      expect(thread().where((m) => m.id == failed.id), isEmpty);
      expect(notifier.uploadProgress(failed.id), isNull);
    },
  );

  test(
    'refreshAttachmentUrl asks GET /media/{id} and returns its URL',
    () async {
      final notifier = await setup();
      expect(
        await notifier.refreshAttachmentUrl('m1'),
        'https://storage.test/a.pdf?sig=new',
      );
      media.freshUrl = null;
      expect(await notifier.refreshAttachmentUrl('m1'), isNull);
      expect(media.renewals, ['m1', 'm1']);
    },
  );

  test('the send body carries type file and attachmentMediaIds', () async {
    final client = BodyClient();
    await MessageRemoteDataSource(client).sendMessage(
      conversationId: 'c1',
      content: 'devis.pdf',
      type: MessageType.file.wireName,
      attachmentMediaIds: const ['65f1c2aa0000000000000001'],
    );
    expect(client.path, 'messaging/messages');
    expect(client.data, {
      'conversationId': 'c1',
      'content': 'devis.pdf',
      'type': 'file',
      'attachmentMediaIds': ['65f1c2aa0000000000000001'],
    });
  });
}
