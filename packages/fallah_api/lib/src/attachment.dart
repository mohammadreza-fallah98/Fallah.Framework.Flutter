import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:fallah_core/fallah_core.dart';
import 'package:fallah_network/fallah_network.dart';

import 'audit_info.dart';
import 'crud_repository.dart';

/// Attachment metadata (`api/v1/attachments`, scope `attachment:*`).
class Attachment {
  const Attachment({
    required this.id,
    required this.url,
    required this.fileName,
    this.title,
    this.contentType = '',
    this.size = 0,
    this.tags,
    this.audit = AuditInfo.none,
  });

  factory Attachment.fromJson(Map<String, dynamic> json) => Attachment(
        id: asInt(json['id'])!,
        url: asString(json['url']) ?? '',
        fileName: asString(json['fileName']) ?? '',
        title: asString(json['title']),
        contentType: asString(json['contentType']) ?? '',
        size: asInt(json['size']) ?? 0,
        tags: asString(json['tags']),
        audit: AuditInfo.fromJson(json),
      );

  final int id;

  /// Relative storage path or absolute URL; resolve with the server's
  /// `FileStorage:Local:BaseUrl` or use [AttachmentRepository.downloadPath].
  final String url;
  final String fileName;
  final String? title;
  final String contentType;
  final int size;
  final String? tags;
  final AuditInfo audit;

  bool get isImage => contentType.startsWith('image/');

  /// Metadata edit body (files themselves are created by `upload`).
  Map<String, dynamic> toUpdateJson() => {
        'id': id,
        'title': title,
        'tags': tags,
        if (audit.rowVersion != null) 'rowVersion': audit.rowVersion,
      };
}

/// Response of `POST attachments/upload`.
class UploadedAttachment {
  const UploadedAttachment({required this.url, required this.attachmentId});

  final String url;
  final int attachmentId;
}

class AttachmentRepository extends CrudRepository<Attachment> {
  AttachmentRepository(super.dio)
      : _dio = dio,
        super(
          path: 'attachments',
          fromJson: Attachment.fromJson,
          createBody: (_) => throw UnsupportedError('Use upload()'),
          updateBody: (e) => e.toUpdateJson(),
          idOf: (e) => e.id,
        );

  final Dio _dio;

  /// Multipart upload. [onProgress] gets `0..1`.
  Future<Result<UploadedAttachment>> upload({
    required Uint8List bytes,
    required String filename,
    String? title,
    String? tags,
    void Function(double progress)? onProgress,
    CancelToken? cancelToken,
  }) =>
      apiCall(() async {
        final json = await uploadBytes(
          _dio,
          'attachments/upload',
          bytes: bytes,
          filename: filename,
          fields: {'title': title, 'tags': tags},
          onProgress: onProgress,
          cancelToken: cancelToken,
        );
        final data = ApiResponse<Map<String, dynamic>>.fromJson(
          json,
          (j) => j! as Map<String, dynamic>,
        ).requireData();
        return UploadedAttachment(
          url: asString(data['url']) ?? '',
          attachmentId: asInt(data['attachmentId']) ?? 0,
        );
      });

  /// Short-lived display URL for [id].
  Future<Result<String>> urlOf(int id) => apiCall(() async {
        final data = await client.action('GET', '$id/url');
        if (data is String) return data;
        if (data is Map<String, dynamic>) return asString(data['url']) ?? '';
        throw const UnknownFailure('Invalid url response');
      });

  /// Path (relative to the API base URL) of the server-proxied download. Open
  /// it with the app's authenticated client; it needs the bearer token.
  String downloadPath(int id) => 'attachments/$id/download';
}
