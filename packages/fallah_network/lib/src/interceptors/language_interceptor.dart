import 'package:dio/dio.dart';

/// Sends `X-Language: en` when the app language is English; Persian (the
/// backend default) sends nothing.
class LanguageInterceptor extends Interceptor {
  LanguageInterceptor(this.languageCode);

  /// Current app language code, e.g. `fa` / `en`. Read on every request.
  final String Function() languageCode;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final code = languageCode();
    if (code != 'fa') options.headers['X-Language'] = code;
    handler.next(options);
  }
}
