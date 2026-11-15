/// Broad family of an attached file, which decides how the thread renders it.
enum AttachmentKind { image, video, audio, document }

/// One file attached to a message, with the metadata the server exposes.
///
/// The server describes attachments twice: `attachmentMedia` (resolved media
/// assets: `id`, `url`, `originalName`, `size`, `mimeType`, `fileType`) and
/// the legacy `attachments` array (`url`, `name`, `size`, `type`). Both carry
/// the same files; the model merges them into this single description.
class MessageAttachmentEntity {
  const MessageAttachmentEntity({
    required this.url,
    this.mediaId,
    this.name,
    this.size,
    this.mimeType,
    this.fileType,
    this.unavailable = false,
  });

  /// Signed remote URL, or a local path while the file is still uploading.
  final String url;

  /// Media identifier, used to renew an expired signed URL.
  final String? mediaId;

  /// Original file name as chosen by the sender.
  final String? name;

  /// Size in bytes, when the server knows it.
  final int? size;

  final String? mimeType;

  /// Server-side family: `image`, `video`, `document`, `audio` or `other`.
  final String? fileType;

  /// The server could not serve the file (removed or temporarily missing).
  final bool unavailable;

  static const _imageExtensions = {
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
    'heic',
    'heif',
    'bmp',
    'avif',
  };
  static const _videoExtensions = {'mp4', 'mov', 'm4v', 'webm', '3gp'};
  static const _audioExtensions = {
    'm4a',
    'aac',
    'mp3',
    'wav',
    'ogg',
    'opus',
    'amr',
    'flac',
  };

  /// Lower-case extension of the displayed name (or of the URL path).
  String get extension {
    String fromPath(String value) {
      final path = Uri.tryParse(value)?.path ?? value;
      final last = path.split(RegExp(r'[/\\]')).last;
      final dot = last.lastIndexOf('.');
      return dot <= 0 || dot == last.length - 1
          ? ''
          : last.substring(dot + 1).toLowerCase();
    }

    final fromName = name == null ? '' : fromPath(name!);
    return fromName.isNotEmpty ? fromName : fromPath(url);
  }

  /// Name to show in the thread: the original name, else the URL file name.
  String get displayName {
    final explicit = name?.trim() ?? '';
    if (explicit.isNotEmpty) return explicit;
    final path = Uri.tryParse(url)?.path ?? url;
    final last = Uri.decodeComponent(path.split(RegExp(r'[/\\]')).last);
    return last.isEmpty ? 'document' : last;
  }

  AttachmentKind get kind {
    final mime = mimeType?.toLowerCase() ?? '';
    if (mime.startsWith('image/')) return AttachmentKind.image;
    if (mime.startsWith('video/')) return AttachmentKind.video;
    if (mime.startsWith('audio/')) return AttachmentKind.audio;
    if (mime.isNotEmpty) return AttachmentKind.document;
    switch (fileType) {
      case 'image':
        return AttachmentKind.image;
      case 'video':
        return AttachmentKind.video;
      case 'audio':
        return AttachmentKind.audio;
      case 'document':
      case 'other':
        return AttachmentKind.document;
    }
    final ext = extension;
    if (_imageExtensions.contains(ext)) return AttachmentKind.image;
    if (_videoExtensions.contains(ext)) return AttachmentKind.video;
    if (_audioExtensions.contains(ext)) return AttachmentKind.audio;
    // A bare URL without a recognizable extension is most often an image
    // from an older client: keep rendering it as a photo, as before.
    return ext.isEmpty ? AttachmentKind.image : AttachmentKind.document;
  }

  bool get isImage => kind == AttachmentKind.image;
}
