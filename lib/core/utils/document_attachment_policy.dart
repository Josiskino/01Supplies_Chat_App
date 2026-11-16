/// Outcome of the pre-upload check of a document.
enum DocumentCheck { accepted, empty, tooLarge, unsupportedType }

/// What the media service accepts for a chat document.
///
/// Mirrors `services/media-service/src/middleware/upload.middleware.ts`
/// (`ALLOWED_DOCUMENT_TYPES`) and `MAX_DOCUMENT_SIZE` (50 MiB by default) on
/// the backend. Checking before the upload spares a long transfer that the
/// server would reject at the end.
abstract final class DocumentAttachmentPolicy {
  static const int maxBytes = 50 * 1024 * 1024;

  /// Extension -> MIME type accepted by the media service.
  static const Map<String, String> mimeTypes = {
    'pdf': 'application/pdf',
    'doc': 'application/msword',
    'docx':
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'xls': 'application/vnd.ms-excel',
    'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'ppt': 'application/vnd.ms-powerpoint',
    'pptx':
        'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    'txt': 'text/plain',
    'csv': 'text/csv',
  };

  /// Apple uniform type identifiers, required by the iOS document picker.
  static const List<String> uniformTypeIdentifiers = [
    'com.adobe.pdf',
    'com.microsoft.word.doc',
    'org.openxmlformats.wordprocessingml.document',
    'com.microsoft.excel.xls',
    'org.openxmlformats.spreadsheetml.sheet',
    'com.microsoft.powerpoint.ppt',
    'org.openxmlformats.presentationml.presentation',
    'public.plain-text',
    'public.comma-separated-values-text',
  ];

  static List<String> get extensions => mimeTypes.keys.toList();

  static String extensionOf(String name) {
    final last = name.split(RegExp(r'[/\\]')).last;
    final dot = last.lastIndexOf('.');
    return dot <= 0 ? '' : last.substring(dot + 1).toLowerCase();
  }

  static DocumentCheck check({required String name, required int sizeBytes}) {
    if (!mimeTypes.containsKey(extensionOf(name))) {
      return DocumentCheck.unsupportedType;
    }
    if (sizeBytes <= 0) return DocumentCheck.empty;
    if (sizeBytes > maxBytes) return DocumentCheck.tooLarge;
    return DocumentCheck.accepted;
  }

  /// Short uppercase badge shown on the document tile (`PDF`, `DOCX`).
  static String badgeOf(String name, {String? mimeType}) {
    final ext = extensionOf(name);
    if (ext.isNotEmpty && ext.length <= 4) return ext.toUpperCase();
    final fromMime = mimeTypes.entries
        .where((e) => e.value == mimeType)
        .map((e) => e.key)
        .firstOrNull;
    return (fromMime ?? 'FILE').toUpperCase();
  }

  /// Human-readable size with a locale-aware decimal separator.
  ///
  /// [units] are the localized byte, kilobyte and megabyte suffixes.
  static String readableSize(
    int bytes, {
    required String localeName,
    required ({String b, String kb, String mb}) units,
  }) {
    final comma = localeName.startsWith('fr');
    String fixed(double value) {
      final text = value.toStringAsFixed(1);
      final trimmed = text.endsWith('.0')
          ? text.substring(0, text.length - 2)
          : text;
      return comma ? trimmed.replaceAll('.', ',') : trimmed;
    }

    final space = comma ? ' ' : ' ';
    if (bytes < 1024) return '$bytes$space${units.b}';
    // Compared after rounding: 1 048 000 bytes must read "1 MB", not "1024 KB".
    final kilobytes = (bytes / 1024).round();
    if (kilobytes < 1024) return '$kilobytes$space${units.kb}';
    return '${fixed(bytes / (1024 * 1024))}$space${units.mb}';
  }
}
