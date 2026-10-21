import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Multipart upload that works on mobile and web (bytes, not file paths).
///
/// [onProgress] receives `sent / total` in `0..1` (when the total is known).
/// Returns the decoded JSON envelope; unwrap it with `ApiResponse.fromJson`.
Future<Map<String, dynamic>> uploadBytes(
  Dio dio,
  String path, {
  required Uint8List bytes,
  required String filename,
  String fieldName = 'file',
  Map<String, Object?> fields = const {},
  void Function(double progress)? onProgress,
  CancelToken? cancelToken,
}) async {
  final form = FormData.fromMap({
    for (final e in fields.entries)
      if (e.value != null) e.key: e.value,
    fieldName: MultipartFile.fromBytes(bytes, filename: filename),
  });

  final response = await dio.post<Map<String, dynamic>>(
    path,
    data: form,
    cancelToken: cancelToken,
    onSendProgress: onProgress == null
        ? null
        : (sent, total) {
            if (total > 0) onProgress(sent / total);
          },
  );
  return response.data!;
}
