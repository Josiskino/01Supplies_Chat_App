/// Un fichier déposé sur le serveur de médias.
class MediaUploadEntity {
  const MediaUploadEntity({
    required this.id,
    required this.url,
    this.mimeType,
    this.size,
  });

  /// Identifiant à joindre au message via `attachmentMediaIds`.
  ///
  /// C'est lui, et non l'URL, que la messagerie attend : le serveur relie ainsi
  /// le fichier au message et sait qu'il ne doit plus l'effacer.
  final String id;

  final String url;
  final String? mimeType;
  final int? size;
}
