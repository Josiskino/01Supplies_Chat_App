import 'package:flutter_test/flutter_test.dart';
import 'package:supplies_chat_app/data/models/messaging/message_model.dart';
import 'package:supplies_chat_app/domain/entity/messaging/message_attachment_entity.dart';
import 'package:supplies_chat_app/presentation/shared/models/conversation_view_data.dart';

/// Payload shape returned by `formatMessageResponse` on origin/develop for a
/// PDF sent through `attachmentMediaIds`.
Map<String, dynamic> pdfMessage({String content = 'facture-1042.pdf'}) => {
  'id': 'm1',
  'conversationId': 'c1',
  'senderId': 'u2',
  'content': content,
  'type': 'file',
  'status': 'sent',
  'createdAt': '2026-11-14T10:00:00.000Z',
  'attachments': [
    {
      'url': 'https://cdn.example.com/private/messages/abc.pdf?sig=1',
      'name': 'facture-1042.pdf',
      'size': 1468006,
      'type': 'application/pdf',
    },
  ],
  'attachmentMediaIds': ['65f1c2aa0000000000000001'],
  'attachmentMedia': [
    {
      'id': '65f1c2aa0000000000000001',
      'url': 'https://cdn.example.com/private/messages/abc.pdf?sig=1',
      'originalName': 'facture-1042.pdf',
      'size': 1468006,
      'mimeType': 'application/pdf',
      'fileType': 'document',
      'visibility': 'private',
    },
  ],
};

void main() {
  test('a PDF attachment keeps its name, size, MIME type and media id', () {
    final entity = MessageModel.fromJson(pdfMessage()).toEntity();

    expect(entity.attachmentDetails, hasLength(1));
    final file = entity.attachmentDetails.single;
    expect(file.name, 'facture-1042.pdf');
    expect(file.size, 1468006);
    expect(file.mimeType, 'application/pdf');
    expect(file.mediaId, '65f1c2aa0000000000000001');
    expect(file.kind, AttachmentKind.document);
  });

  test('a received PDF becomes a document tile, never a photo', () {
    final view = ChatMessageData.fromMessage(
      MessageModel.fromJson(pdfMessage()).toEntity(),
      currentUserId: 'u1',
    );

    // Regression: the PDF URL used to be handed to the photo stack, which
    // showed a broken thumbnail and opened the image viewer on tap.
    expect(view.attachments, isEmpty);
    expect(view.documents, hasLength(1));
    expect(view.documents.single.name, 'facture-1042.pdf');
    expect(view.documents.single.sizeBytes, 1468006);
    expect(view.documents.single.mediaId, '65f1c2aa0000000000000001');
    // The file name sent as content is not repeated as a caption.
    expect(view.text, isEmpty);
  });

  test('a caption next to a document stays visible', () {
    final view = ChatMessageData.fromMessage(
      MessageModel.fromJson(
        pdfMessage(content: 'Voici la facture demandée'),
      ).toEntity(),
      currentUserId: 'u1',
    );
    expect(view.text, 'Voici la facture demandée');
    expect(view.documents, hasLength(1));
  });

  test('legacy attachments without media still classify by MIME type', () {
    final json = pdfMessage()
      ..remove('attachmentMedia')
      ..remove('attachmentMediaIds');
    final view = ChatMessageData.fromMessage(
      MessageModel.fromJson(json).toEntity(),
      currentUserId: 'u1',
    );
    expect(view.documents.single.name, 'facture-1042.pdf');
    expect(view.documents.single.mediaId, isNull);
  });

  test('images stay in the photo stack, documents alongside them', () {
    final json = {
      ...pdfMessage(),
      'type': 'image',
      'attachmentMedia': [
        {
          'id': 'img',
          'url': 'https://cdn.example.com/a.jpg?sig=1',
          'mimeType': 'image/jpeg',
          'fileType': 'image',
        },
      ],
      'attachments': ['https://cdn.example.com/a.jpg?sig=1'],
    };
    final view = ChatMessageData.fromMessage(
      MessageModel.fromJson(json).toEntity(),
      currentUserId: 'u1',
    );
    expect(view.attachments, ['https://cdn.example.com/a.jpg?sig=1']);
    expect(view.documents, isEmpty);
  });

  test('bare image URLs from older payloads still render as photos', () {
    final json = {
      ...pdfMessage(),
      'type': 'image',
      'attachmentMedia': null,
      'attachments': ['https://cdn.example.com/photo'],
    };
    final view = ChatMessageData.fromMessage(
      MessageModel.fromJson(json).toEntity(),
      currentUserId: 'u1',
    );
    expect(view.attachments, ['https://cdn.example.com/photo']);
    expect(view.documents, isEmpty);
  });

  test('a removed document is shown as unavailable', () {
    final json = {
      ...pdfMessage(),
      'attachments': <Object>[],
      'attachmentMedia': [
        {
          'id': 'gone',
          'unavailable': true,
          'reason': 'removed',
          'fileType': 'document',
          'mimeType': 'application/pdf',
        },
      ],
    };
    final view = ChatMessageData.fromMessage(
      MessageModel.fromJson(json).toEntity(),
      currentUserId: 'u1',
    );
    expect(view.documents.single.unavailable, isTrue);
  });

  test('voice notes are not mistaken for documents', () {
    final json = {
      ...pdfMessage(),
      'type': 'audio',
      'attachmentMedia': [
        {
          'id': 'v',
          'url': 'https://cdn.example.com/v.m4a',
          'mimeType': 'audio/mp4',
          'fileType': 'audio',
        },
      ],
      'attachments': <Object>[],
    };
    final view = ChatMessageData.fromMessage(
      MessageModel.fromJson(json).toEntity(),
      currentUserId: 'u1',
    );
    expect(view.isVoice, isTrue);
    expect(view.documents, isEmpty);
  });
}
