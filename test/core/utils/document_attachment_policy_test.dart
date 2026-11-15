import 'package:flutter_test/flutter_test.dart';
import 'package:supplies_chat_app/core/services/document_file_service.dart';
import 'package:supplies_chat_app/core/utils/document_attachment_policy.dart';

void main() {
  const units = (b: 'o', kb: 'Ko', mb: 'Mo');

  group('size validation', () {
    test('accepts a PDF up to the 50 MiB media-service limit', () {
      expect(
        DocumentAttachmentPolicy.check(
          name: 'contrat.pdf',
          sizeBytes: DocumentAttachmentPolicy.maxBytes,
        ),
        DocumentCheck.accepted,
      );
    });

    test('rejects a document one byte over the limit', () {
      expect(
        DocumentAttachmentPolicy.check(
          name: 'scan.PDF',
          sizeBytes: DocumentAttachmentPolicy.maxBytes + 1,
        ),
        DocumentCheck.tooLarge,
      );
    });

    test('rejects empty files and formats the server refuses', () {
      expect(
        DocumentAttachmentPolicy.check(name: 'a.pdf', sizeBytes: 0),
        DocumentCheck.empty,
      );
      expect(
        DocumentAttachmentPolicy.check(name: 'setup.exe', sizeBytes: 10),
        DocumentCheck.unsupportedType,
      );
      expect(
        DocumentAttachmentPolicy.check(name: 'noextension', sizeBytes: 10),
        DocumentCheck.unsupportedType,
      );
    });

    test('accepts every Office format the backend whitelists', () {
      for (final name in [
        'a.doc',
        'a.docx',
        'a.xls',
        'a.xlsx',
        'a.ppt',
        'a.pptx',
        'a.txt',
        'a.csv',
      ]) {
        expect(
          DocumentAttachmentPolicy.check(name: name, sizeBytes: 1),
          DocumentCheck.accepted,
          reason: name,
        );
      }
    });
  });

  test('readable sizes follow the locale decimal separator', () {
    expect(
      DocumentAttachmentPolicy.readableSize(
        1468006,
        localeName: 'fr',
        units: units,
      ),
      '1,4 Mo',
    );
    expect(
      DocumentAttachmentPolicy.readableSize(
        1468006,
        localeName: 'en',
        units: (b: 'B', kb: 'KB', mb: 'MB'),
      ),
      '1.4 MB',
    );
    expect(
      DocumentAttachmentPolicy.readableSize(
        2048,
        localeName: 'fr',
        units: units,
      ),
      '2 Ko',
    );
  });

  test('badges come from the extension, then the MIME type', () {
    expect(DocumentAttachmentPolicy.badgeOf('Facture.pdf'), 'PDF');
    expect(
      DocumentAttachmentPolicy.badgeOf('document', mimeType: 'application/pdf'),
      'PDF',
    );
    expect(DocumentAttachmentPolicy.badgeOf('x'), 'FILE');
  });

  test('downloaded file names are safe on every file system', () {
    expect(
      DocumentFileService.safeFileName('../../etc/passwd'),
      '.._.._etc_passwd',
    );
    expect(DocumentFileService.safeFileName('a:b?.pdf'), 'a_b_.pdf');
    expect(DocumentFileService.safeFileName('  '), 'document');
  });

  test('the cache key ignores the changing URL signature', () {
    expect(
      DocumentFileService.cacheKeyOf(url: 'https://x.test/a.pdf?sig=1'),
      DocumentFileService.cacheKeyOf(url: 'https://x.test/a.pdf?sig=2'),
    );
    expect(
      DocumentFileService.cacheKeyOf(url: 'https://x', mediaId: 'm1'),
      'm1',
    );
  });
}
