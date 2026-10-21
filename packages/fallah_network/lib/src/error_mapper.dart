import 'package:dio/dio.dart';
import 'package:fallah_core/fallah_core.dart';

import 'api_response.dart';

/// Converts anything thrown by the network layer into a [Failure].
abstract final class ErrorMapper {
  static Failure map(Object error) {
    if (error is Failure) return error;
    if (error is DioException) return _fromDio(error);
    return UnknownFailure('$error', error);
  }

  /// For HTTP 200 responses whose envelope says `isSuccess: false`.
  static Failure fromEnvelope(List<Object> errorMessages) {
    final errors = _fieldErrors(errorMessages);
    return ServerFailure(
      errors.isEmpty ? 'Request failed' : errors.first.message,
      statusCode: 200,
      code: errors.isEmpty ? null : errors.first.code,
    );
  }

  static Failure _fromDio(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return NetworkFailure('Request timed out', code: 'timeout', cause: e);
      case DioExceptionType.connectionError:
        return NetworkFailure('No connection', code: 'offline', cause: e);
      case DioExceptionType.badCertificate:
        return NetworkFailure('Bad certificate', code: 'certificate', cause: e);
      case DioExceptionType.cancel:
        return NetworkFailure('Request cancelled', code: 'cancelled', cause: e);
      case DioExceptionType.badResponse:
        return _fromResponse(e);
      case DioExceptionType.unknown:
        return UnknownFailure(e.message ?? 'Unknown error', e);
    }
  }

  static Failure _fromResponse(DioException e) {
    final response = e.response!;
    final status = response.statusCode ?? 0;
    final body = response.data;
    final errors = _fieldErrors(
      body is Map<String, dynamic>
          ? parseErrorMessages(body['errorMessages'])
          : const [],
    );
    final message =
        errors.isNotEmpty ? errors.first.message : _fallback(status);
    final code = errors.isNotEmpty ? errors.first.code : null;

    return switch (status) {
      400 || 422 => ValidationFailure(
          message,
          errors: errors,
          code: code,
          cause: e,
        ),
      401 => UnauthorizedFailure(message, e),
      403 => ForbiddenFailure(message, e),
      404 => NotFoundFailure(message, e),
      409 => ConflictFailure(message, code: code, cause: e),
      429 =>
        RateLimitFailure(message, retryAfter: _retryAfter(response), cause: e),
      _ => ServerFailure(message, statusCode: status, code: code, cause: e),
    };
  }

  static List<FieldError> _fieldErrors(List<Object> raw) => [
        for (final e in raw)
          if (e is String)
            FieldError(message: e)
          else if (e is Map<String, dynamic>)
            FieldError(
              field: e['field'] as String?,
              message: (e['message'] ?? e['error'] ?? '').toString(),
              code: e['code']?.toString(),
            ),
      ];

  static Duration? _retryAfter(Response<dynamic> response) {
    final seconds = int.tryParse(response.headers.value('retry-after') ?? '');
    return seconds == null ? null : Duration(seconds: seconds);
  }

  static String _fallback(int status) => switch (status) {
        >= 500 => 'Server error',
        _ => 'Request failed ($status)',
      };
}
