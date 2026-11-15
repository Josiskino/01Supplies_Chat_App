import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/apple_type.dart';
import '../../../../core/utils/document_attachment_policy.dart';
import '../../../../core/utils/localization_helper.dart';
import '../../../shared/models/conversation_view_data.dart';

/// Downloads (reporting progress) then opens a document.
///
/// Returns `false` when the document could not be opened; the caller has
/// already told the user why.
typedef DocumentAction =
    Future<bool> Function(
      ChatDocumentData document,
      ValueChanged<double> onProgress,
    );

/// A document attached to a message: type badge, name, size, and a tap that
/// downloads and opens it.
///
/// Lives inside the message bubble, like WhatsApp and Messages: a document
/// has no visual content of its own, and a bare card floating outside the
/// bubble would lose the sender's side and colour.
class DocumentTile extends StatefulWidget {
  const DocumentTile({
    super.key,
    required this.document,
    required this.foreground,
    this.uploadProgress,
    this.isUploading = false,
    this.onOpen,
    this.onSave,
  });

  final ChatDocumentData document;

  /// Text colour of the surrounding bubble.
  final Color foreground;

  /// Upload progress of an outgoing document (0 to 1).
  final ValueListenable<double>? uploadProgress;
  final bool isUploading;

  final DocumentAction? onOpen;

  /// Desktop only: saves a copy where the user chooses.
  final DocumentAction? onSave;

  /// Badge colour per family: the colours people associate with each format.
  static Color badgeColor(String badge) => switch (badge) {
    'PDF' => const Color(0xFFE5484D),
    'DOC' || 'DOCX' => const Color(0xFF2B6CD9),
    'XLS' || 'XLSX' || 'CSV' => const Color(0xFF1F9D55),
    'PPT' || 'PPTX' => const Color(0xFFE5732E),
    _ => const Color(0xFF7A7A85),
  };

  @override
  State<DocumentTile> createState() => _DocumentTileState();
}

class _DocumentTileState extends State<DocumentTile> {
  /// Download progress while a download runs, `null` otherwise.
  double? _download;
  bool _failed = false;

  bool get _busy => _download != null || widget.isUploading;

  Future<void> _run(DocumentAction? action) async {
    if (action == null || _busy || widget.document.unavailable) return;
    setState(() {
      _download = 0;
      _failed = false;
    });
    var ok = false;
    try {
      ok = await action(widget.document, (value) {
        if (mounted) setState(() => _download = value);
      });
    } catch (_) {
      ok = false;
    }
    if (!mounted) return;
    setState(() {
      _download = null;
      _failed = !ok;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationHelper.of(context);
    final theme = Theme.of(context);
    final document = widget.document;
    final badge = DocumentAttachmentPolicy.badgeOf(
      document.name,
      mimeType: document.mimeType,
    );
    final accent = DocumentTile.badgeColor(badge);
    final subtle = widget.foreground.withValues(alpha: 0.65);

    String details(double? upload) {
      if (document.unavailable) return l10n.chatDocumentUnavailable;
      if (widget.isUploading) {
        return l10n.chatDocumentUploading(((upload ?? 0) * 100).round());
      }
      if (_download != null) {
        return l10n.chatDocumentDownloading((_download! * 100).round());
      }
      final size = document.sizeBytes;
      return [
        if (size != null && size > 0)
          DocumentAttachmentPolicy.readableSize(
            size,
            localeName: l10n.localeName,
            units: (
              b: l10n.chatFileSizeBytes,
              kb: l10n.chatFileSizeKb,
              mb: l10n.chatFileSizeMb,
            ),
          ),
        badge,
      ].join(' · ');
    }

    Widget leading(double? upload) {
      final progress = widget.isUploading ? upload : _download;
      return SizedBox(
        width: 40,
        height: 44,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                color: widget.foreground.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            if (_busy)
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  // Indeterminate until the first byte: a ring frozen at zero
                  // reads as a stalled transfer.
                  value: progress == null || progress <= 0 ? null : progress,
                  color: widget.foreground,
                  backgroundColor: widget.foreground.withValues(alpha: 0.2),
                ),
              )
            else
              Icon(
                document.unavailable
                    ? CupertinoIcons.eye_slash
                    : _failed
                    ? CupertinoIcons.arrow_clockwise
                    : CupertinoIcons.doc_text_fill,
                size: 22,
                color: widget.foreground.withValues(alpha: 0.85),
              ),
            if (!_busy)
              Positioned(
                bottom: 3,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 3,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      height: 1.1,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    Widget body(double? upload) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        leading(upload),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                document.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium
                    ?.merge(AppleType.subheadline)
                    .copyWith(
                      color: widget.foreground,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                _failed ? l10n.chatDocumentRetry : details(upload),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall
                    ?.merge(AppleType.caption1)
                    .copyWith(color: subtle),
              ),
            ],
          ),
        ),
        if (widget.onSave != null &&
            !document.unavailable &&
            !widget.isUploading) ...[
          const SizedBox(width: 4),
          IconButton(
            tooltip: l10n.chatDocumentSave,
            visualDensity: VisualDensity.compact,
            onPressed: _busy ? null : () => _run(widget.onSave),
            icon: Icon(
              CupertinoIcons.arrow_down_to_line,
              size: 18,
              color: widget.foreground.withValues(alpha: 0.8),
            ),
          ),
        ],
      ],
    );

    final progress = widget.uploadProgress;
    return Semantics(
      button: !document.unavailable,
      label: document.name,
      hint: document.unavailable ? null : l10n.chatDocumentOpenAction,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: document.unavailable || widget.isUploading
            ? null
            : () => _run(widget.onOpen),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: progress == null
              ? body(null)
              : ValueListenableBuilder<double>(
                  valueListenable: progress,
                  builder: (context, value, _) => body(value),
                ),
        ),
      ),
    );
  }
}
