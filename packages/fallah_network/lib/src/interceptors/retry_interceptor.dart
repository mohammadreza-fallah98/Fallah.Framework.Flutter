import 'package:dio/dio.dart';

/// Retries GET requests that failed with a connectivity error/timeout, using
/// exponential backoff. Other methods and HTTP error responses are never
/// retried.
class RetryInterceptor extends Interceptor {
  RetryInterceptor({
    required this.dio,
    this.maxRetries = 2,
    this.baseDelay = const Duration(milliseconds: 300),
    this.delay = Future<void>.delayed,
  });

  static const _attemptKey = '_retryAttempt';

  final Dio dio;
  final int maxRetries;
  final Duration baseDelay;

  /// Injectable for tests.
  final Future<void> Function(Duration) delay;

  static const _retryable = {
    DioExceptionType.connectionTimeout,
    DioExceptionType.sendTimeout,
    DioExceptionType.receiveTimeout,
    DioExceptionType.connectionError,
  };

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final request = err.requestOptions;
    final attempt = (request.extra[_attemptKey] as int?) ?? 0;

    if (request.method != 'GET' ||
        !_retryable.contains(err.type) ||
        attempt >= maxRetries) {
      return handler.next(err);
    }

    await delay(baseDelay * (1 << attempt));
    try {
      final response = await dio.fetch<dynamic>(
        request.copyWith(extra: {...request.extra, _attemptKey: attempt + 1}),
      );
      handler.resolve(response);
    } on DioException catch (e) {
      handler.next(e);
    }
  }
}
