import '../../../domain/entity/media/media_upload_entity.dart';

class MediaUploadModel {
  const MediaUploadModel({
    required this.id,
    required this.url,
    this.mimeType,
    this.size,
  });

  final String id;
  final String url;
  final String? mimeType;
  final int? size;

  factory MediaUploadModel.fromJson(Map<String, dynamic> json) =>
      MediaUploadModel(
        id: (json['id'] ?? json['_id'] ?? '').toString(),
        url: (json['url'] ?? json['secureUrl'] ?? '').toString(),
        mimeType: json['mimeType']?.toString(),
        size: (json['size'] as num?)?.toInt(),
      );

  MediaUploadEntity toEntity() =>
      MediaUploadEntity(id: id, url: url, mimeType: mimeType, size: size);
}
