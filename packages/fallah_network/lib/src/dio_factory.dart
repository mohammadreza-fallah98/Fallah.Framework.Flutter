import 'package:dio/dio.dart';
import 'package:fallah_core/fallah_core.dart';

import 'interceptors/auth_interceptor.dart';
import 'interceptors/correlation_interceptor.dart';
import 'interceptors/language_interceptor.dart';
import 'interceptors/logging_interceptor.dart';
import 'interceptors/retry_interceptor.dart';
import 'network_config.dart';
import 'token_store.dart';

/// Builds the app-wide [Dio]. Interceptor order:
/// correlation -> language -> auth -> retry -> logging.
Dio createDio({
  required NetworkConfig config,
  required String Function() languageCode,
  TokenStore? tokenStore,
  TokenRefresher? refresh,
  Future<void> Function()? onSessionExpired,
  AppLogger? logger,
  HttpClientAdapter? adapter,
}) {
  assert(
    (tokenStore == null) == (refresh == null),
    'tokenStore and refresh must be provided together',
  );

  final dio = Dio(
    BaseOptions(
      baseUrl: config.baseUrl,
      connectTimeout: config.connectTimeout,
      receiveTimeout: config.receiveTimeout,
      sendTimeout: config.sendTimeout,
      contentType: Headers.jsonContentType,
    ),
  );
  if (adapter != null) dio.httpClientAdapter = adapter;

  dio.interceptors.addAll([
    CorrelationInterceptor(),
    LanguageInterceptor(languageCode),
    if (tokenStore != null && refresh != null)
      AuthInterceptor(
        dio: dio,
        tokenStore: tokenStore,
        refresh: refresh,
        onSessionExpired: onSessionExpired,
      ),
    if (config.maxRetries > 0)
      RetryInterceptor(dio: dio, maxRetries: config.maxRetries),
    if (config.enableLogging && logger != null) LoggingInterceptor(logger),
  ]);
  return dio;
}
