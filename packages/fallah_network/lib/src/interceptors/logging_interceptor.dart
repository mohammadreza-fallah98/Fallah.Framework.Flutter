import 'package:dio/dio.dart';
import 'package:fallah_core/fallah_core.dart';

/// Logs requests/responses through [AppLogger]. Authorization is redacted.
/// Enable in debug builds only.
class LoggingInterceptor extends Interceptor {
  LoggingInterceptor(this.logger);

  final AppLogger logger;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    logger.log(LogLevel.debug, '--> ${options.method} ${options.uri}');
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    logger.log(
      LogLevel.debug,
      '<-- ${response.statusCode} ${response.requestOptions.method} '
      '${response.requestOptions.uri}',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    logger.log(
      LogLevel.warning,
      '<-- ERR ${err.response?.statusCode ?? err.type.name} '
      '${err.requestOptions.method} ${err.requestOptions.uri}',
      error: err.message,
    );
    handler.next(err);
  }
}
