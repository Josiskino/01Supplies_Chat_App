import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supplies_chat_app/core/utils/document_attachment_policy.dart';
import 'package:supplies_chat_app/data/models/messaging/message_model.dart';
import 'package:supplies_chat_app/domain/entity/messaging/message_attachment_entity.dart';
import 'package:supplies_chat_app/domain/entity/messaging/message_entity.dart';
import 'package:supplies_chat_app/presentation/shared/models/conversation_view_data.dart';

const _mediaId = '65f1c2aa0000000000000001';
const _signed =
    'https://storage.example.com/private/messages/abc.pdf'
    '?X-Amz-Signature=1&X-Amz-Expires=900';

Map<String, dynamic> _message({
  List<Object?>? media,
  List<Object?>? legacy,
  String type = 'file',
  String content = '',
}) => {
  'id': 'm1',
  'conversationId': 'c1',
  'senderId': 'u2',
  'content': content,
  'type': type,
  'status': 'sent',
  'createdAt': '2026-11-14T10:00:00.000Z',
  'attachments': ?legacy,
  'attachmentMedia': ?media,
};

List<MessageAttachmentEntity> _parse(Map<String, dynamic> json) =>
    MessageModel.parseAttachmentDetails(json);

ChatMessageData _view(Map<String, dynamic> json) => ChatMessageData.fromMessage(
  MessageModel.fromJson(json).toEntity(),
  currentUserId: 'u1',
);

void main() {
  group('parseAttachmentDetails (backend contract)', () {
    test('asset with expiresAt and its legacy twin merge into one file', () {
      // `formatMessageResponse` on origin/develop: `attachments` is derived
      // from the available `attachmentMedia` assets.
      final files = _parse(
        _message(
          media: [
            {
              'id': _mediaId,
              'url': _signed,
              'thumbnailUrl': null,
              'originalName': 'Contrat signé.PDF',
              'size': 52428800,
              'mimeType': 'application/pdf',
              'fileType': 'document',
              'visibility': 'private',
              'source': 'internal',
              'expiresAt': '2026-11-14T10:15:00.000Z',
            },
          ],
          legacy: [
            {
              'url': _signed,
              'name': 'Contrat signé.PDF',
              'size': 52428800,
              'type': 'application/pdf',
            },
          ],
        ),
      );
      expect(files, hasLength(1));
      final file = files.single;
      expect(file.mediaId, _mediaId);
      expect(file.name, 'Contrat signé.PDF');
      expect(file.size, 52428800);
      expect(file.extension, 'pdf');
      expect(file.kind, AttachmentKind.document);
    });

    test('a media without originalName never shows its id as the name', () {
      // Backend fallback: `name: asset.originalName ?? asset.name ?? asset.id`.
      final files = _parse(
        _message(
          media: [
            {
              'id': _mediaId,
              'url': _signed,
              'mimeType': 'application/pdf',
              'fileType': 'document',
            },
          ],
          legacy: [
            {
              'url': _signed,
              'name': _mediaId,
              'size': 0,
              'type': 'application/pdf',
            },
          ],
        ),
      );
      expect(files.single.displayName, isNot(_mediaId));
      expect(files.single.displayName, 'abc.pdf');
    });

    test('an unavailable descriptor is kept, with its MIME type', () {
      final files = _parse(
        _message(
          media: [
            {
              'id': _mediaId,
              'unavailable': true,
              'reason': 'removed',
              'fileType': 'document',
              'mimeType': 'application/pdf',
            },
          ],
          legacy: const [],
        ),
      );
      expect(files.single.unavailable, isTrue);
      expect(files.single.mediaId, _mediaId);
      expect(files.single.kind, AttachmentKind.document);
      final view = _view(
        _message(
          media: [
            {
              'id': _mediaId,
              'unavailable': true,
              'reason': 'temporarily_unavailable',
              'fileType': 'document',
              'mimeType': 'application/pdf',
            },
          ],
        ),
      );
      expect(view.documents.single.unavailable, isTrue);
      expect(view.attachments, isEmpty);
    });

    test('malformed entries are skipped without throwing', () {
      final files = _parse(
        _message(
          media: [
            null,
            'https://x.test/a.pdf',
            42,
            <String, dynamic>{},
            {'id': 'no-url'},
            {'url': '   '},
            {
              'url': 'https://x.test/b.pdf',
              'size': '2048',
              'originalName': '  ',
            },
            {'url': 'https://x.test/c.pdf', 'size': 12.7},
            {'url': 'https://x.test/d.pdf', 'size': 'big'},
          ],
          legacy: [null, 7, '', <String, dynamic>{}, true],
        ),
      );
      expect(files.map((f) => f.url), [
        'https://x.test/b.pdf',
        'https://x.test/c.pdf',
        'https://x.test/d.pdf',
      ]);
      expect(files[0].size, 2048);
      expect(files[0].name, isNull, reason: 'blank names are dropped');
      expect(files[0].displayName, 'b.pdf');
      expect(files[1].size, 12);
      expect(files[2].size, isNull);
    });

    test('non-list attachment fields are ignored', () {
      expect(
        _parse({
          'attachmentMedia': 'x',
          'attachments': {'url': 'y'},
        }),
        isEmpty,
      );
      expect(_parse({}), isEmpty);
    });

    test('a legacy string URL also listed as media is not duplicated', () {
      final files = _parse(
        _message(
          media: [
            {'id': _mediaId, 'url': _signed, 'mimeType': 'application/pdf'},
          ],
          legacy: [_signed],
        ),
      );
      expect(files, hasLength(1));
      expect(files.single.mediaId, _mediaId);
    });
  });

  group('AttachmentKind: a PDF is never a photo', () {
    AttachmentKind kind({
      String url = 'https://x.test/file',
      String? name,
      String? mime,
      String? fileType,
    }) => MessageAttachmentEntity(
      url: url,
      name: name,
      mimeType: mime,
      fileType: fileType,
    ).kind;

    test('unknown MIME type with a .pdf name', () {
      expect(
        kind(name: 'devis.pdf', mime: 'application/octet-stream'),
        AttachmentKind.document,
      );
      expect(kind(name: 'devis.pdf'), AttachmentKind.document);
    });

    test('uppercase and mixed-case extensions', () {
      for (final name in ['DEVIS.PDF', 'a.Pdf', 'b.DOCX', 'c.XlSx', 'd.CSV']) {
        expect(kind(name: name), AttachmentKind.document, reason: name);
      }
      expect(kind(name: 'IMG_1.JPG'), AttachmentKind.image);
      expect(kind(name: 'clip.MOV'), AttachmentKind.video);
    });

    test('signed URLs are classified by their path, not the query', () {
      expect(kind(url: _signed), AttachmentKind.document);
      expect(kind(url: 'https://x.test/a.jpg?sig=b.pdf'), AttachmentKind.image);
    });

    test('the MIME type wins over a misleading name', () {
      expect(
        kind(name: 'scan.jpg', mime: 'application/pdf'),
        AttachmentKind.document,
      );
      expect(kind(name: 'scan.pdf', mime: 'IMAGE/PNG'), AttachmentKind.image);
    });

    test('files without extension use fileType, else stay legacy photos', () {
      expect(kind(fileType: 'document'), AttachmentKind.document);
      expect(kind(fileType: 'other'), AttachmentKind.document);
      expect(kind(fileType: 'audio'), AttachmentKind.audio);
      expect(kind(name: 'README'), AttachmentKind.image);
      expect(kind(), AttachmentKind.image);
    });

    test('unknown extensions are documents', () {
      expect(kind(name: 'archive.zip'), AttachmentKind.document);
      expect(kind(name: 'notes.'), AttachmentKind.image);
      expect(kind(name: '.hidden'), AttachmentKind.image);
    });
  });

  group('displayName', () {
    test('decodes the URL file name', () {
      expect(
        const MessageAttachmentEntity(
          url: 'https://x.test/p/Bon%20de%20commande.pdf?sig=1',
        ).displayName,
        'Bon de commande.pdf',
      );
    });

    test('a malformed percent escape does not throw', () {
      expect(
        () => const MessageAttachmentEntity(
          url: 'https://x.test/p/100%25%ZZ.pdf',
        ).displayName,
        returnsNormally,
      );
      expect(
        const MessageAttachmentEntity(
          url: 'https://x.test/a%E0%A4%A.pdf',
        ).displayName,
        isNotEmpty,
      );
    });

    test('falls back to a generic name', () {
      expect(const MessageAttachmentEntity(url: '').displayName, 'document');
      expect(
        const MessageAttachmentEntity(url: 'https://x.test/').displayName,
        'document',
      );
    });
  });

  group('ChatMessageData', () {
    test('legacy image URLs stay photos next to a document', () {
      final view = _view(
        _message(
          type: 'image',
          legacy: ['https://cdn.test/photo-without-extension', _signed],
        ),
      );
      expect(view.attachments, ['https://cdn.test/photo-without-extension']);
      expect(view.documents.single.name, 'abc.pdf');
    });

    test('a caption different from the file name stays visible', () {
      final view = _view(
        _message(
          content: 'Voici le devis',
          media: [
            {
              'id': _mediaId,
              'url': _signed,
              'originalName': 'devis.pdf',
              'mimeType': 'application/pdf',
            },
          ],
        ),
      );
      expect(view.text, 'Voici le devis');
    });

    test('a pending outgoing document keeps its local details', () {
      final view = ChatMessageData.fromMessage(
        MessageEntity(
          id: 'local',
          conversationId: 'c1',
          senderId: 'u1',
          content: 'rapport.docx',
          type: MessageType.file,
          delivery: MessageDelivery.sent,
          sentAt: DateTime.utc(2026, 11, 14),
          isPending: true,
          attachments: const ['/tmp/out/rapport.docx'],
          attachmentDetails: const [
            MessageAttachmentEntity(
              url: '/tmp/out/rapport.docx',
              name: 'rapport.docx',
              size: 2048,
            ),
          ],
        ),
        currentUserId: 'u1',
      );
      expect(view.attachments, isEmpty);
      expect(view.documents.single.source, '/tmp/out/rapport.docx');
      expect(view.documents.single.sizeBytes, 2048);
      expect(view.text, isEmpty);
    });
  });

  group('DocumentAttachmentPolicy', () {
    const mib = 1024 * 1024;

    test('the size limit is the backend MAX_DOCUMENT_SIZE default', () {
      expect(DocumentAttachmentPolicy.maxBytes, 52428800);
    });

    test('size boundaries', () {
      DocumentCheck check(int size) =>
          DocumentAttachmentPolicy.check(name: 'a.pdf', sizeBytes: size);
      expect(check(0), DocumentCheck.empty);
      expect(check(-1), DocumentCheck.empty);
      expect(check(1), DocumentCheck.accepted);
      expect(check((49.9 * mib).round()), DocumentCheck.accepted);
      expect(check(50 * mib), DocumentCheck.accepted);
      expect(check(50 * mib + 1), DocumentCheck.tooLarge);
    });

    test('type is checked before size, case-insensitively', () {
      expect(
        DocumentAttachmentPolicy.check(name: 'A.PDF', sizeBytes: 10),
        DocumentCheck.accepted,
      );
      expect(
        DocumentAttachmentPolicy.check(name: 'README', sizeBytes: 0),
        DocumentCheck.unsupportedType,
      );
      expect(
        DocumentAttachmentPolicy.check(name: 'photo.png', sizeBytes: 10),
        DocumentCheck.unsupportedType,
      );
      expect(
        DocumentAttachmentPolicy.check(name: '.pdf', sizeBytes: 10),
        DocumentCheck.unsupportedType,
      );
      expect(
        DocumentAttachmentPolicy.check(name: 'dir.pdf/notes', sizeBytes: 10),
        DocumentCheck.unsupportedType,
      );
    });

    test('the multipart Content-Type of every allowed extension is on the '
        'media-service whitelist', () {
      // ALLOWED_DOCUMENT_TYPES in media-service upload.middleware.ts.
      const serverWhitelist = {
        'application/pdf',
        'application/msword',
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        'application/vnd.ms-excel',
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        'application/vnd.ms-powerpoint',
        'application/vnd.openxmlformats-officedocument.presentationml.presentation',
        'text/plain',
        'text/csv',
      };
      expect(
        DocumentAttachmentPolicy.mimeTypes.values.toSet(),
        serverWhitelist,
      );
      for (final ext in DocumentAttachmentPolicy.extensions) {
        for (final name in ['file.$ext', 'FILE.${ext.toUpperCase()}']) {
          // What Dio sends as the part Content-Type, i.e. what multer checks.
          expect(
            MultipartFile.lookupMediaType(name)?.mimeType,
            DocumentAttachmentPolicy.mimeTypes[ext],
            reason: name,
          );
        }
      }
    });

    group('readableSize', () {
      String fr(int b) => DocumentAttachmentPolicy.readableSize(
        b,
        localeName: 'fr',
        units: (b: 'o', kb: 'Ko', mb: 'Mo'),
      );
      String en(int b) => DocumentAttachmentPolicy.readableSize(
        b,
        localeName: 'en',
        units: (b: 'B', kb: 'KB', mb: 'MB'),
      );

      test('boundaries in both locales', () {
        expect(fr(0), '0\u00a0o');
        expect(en(1023), '1023 B');
        expect(en(1024), '1 KB');
        expect(fr((49.9 * mib).round()), '49,9\u00a0Mo');
        expect(en((49.9 * mib).round()), '49.9 MB');
        expect(en(50 * mib), '50 MB');
        expect(en(50 * mib + 1), '50 MB');
      });

      test('just under 1 MiB never reads "1024 KB"', () {
        expect(en(mib - 1), '1 MB');
        expect(en(mib - 400), '1 MB');
        expect(en(mib - 1000), '1023 KB');
      });
    });

    test('badges for files without or with a long extension', () {
      expect(
        DocumentAttachmentPolicy.badgeOf('scan', mimeType: 'application/pdf'),
        'PDF',
      );
      expect(DocumentAttachmentPolicy.badgeOf('scan'), 'FILE');
      expect(
        DocumentAttachmentPolicy.badgeOf(
          'notes.markdown',
          mimeType: 'text/plain',
        ),
        'TXT',
      );
      expect(DocumentAttachmentPolicy.badgeOf('DEVIS.Pdf'), 'PDF');
    });
  });
}
