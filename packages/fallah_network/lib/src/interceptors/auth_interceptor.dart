import 'package:dio/dio.dart';

import '../token_store.dart';

/// Adds `Authorization: Bearer ...` and, on HTTP 401, refreshes the token pair
/// once (requests are queued, so concurrent 401s share one refresh) and
/// replays the failed request.
///
/// Set `extra: {AuthInterceptor.skipAuthKey: true}` on requests that must not
/// carry a token (login, OTP, refresh).
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({
    required this.dio,
    required this.tokenStore,
    required this.refresh,
    this.onSessionExpired,
  });

  static const skipAuthKey = 'skipAuth';
  static const _retriedKey = '_authRetried';

  final Dio dio;
  final TokenStore tokenStore;
  final TokenRefresher refresh;

  /// Called after refresh was rejected and tokens were cleared; route to login.
  final Future<void> Function()? onSessionExpired;

  /// Client without interceptors, used for the refresh call and the replay.
  late final Dio _plain = Dio(dio.options.copyWith())
    ..httpClientAdapter = dio.httpClientAdapter;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra[skipAuthKey] != true) {
      final tokens = await tokenStore.read();
      if (tokens != null) {
        options.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final request = err.requestOptions;
    if (err.response?.statusCode != 401 ||
        request.extra[skipAuthKey] == true ||
        request.extra[_retriedKey] == true) {
      return handler.next(err);
    }

    final current = await tokenStore.read();
    if (current == null) return handler.next(err);

    var tokens = current;
    final sentWithCurrent =
        request.headers['Authorization'] == 'Bearer ${current.accessToken}';
    // If the stored token differs from the one sent, an earlier queued request
    // already refreshed it; just replay.
    if (sentWithCurrent) {
      try {
        tokens = await refresh(_plain, current.refreshToken);
        await tokenStore.save(tokens);
      } on DioException catch (e) {
        // Only an explicit rejection ends the session. Offline, timeouts and
        // 5xx are transient: keep the tokens and surface the original 401.
        final status = e.response?.statusCode;
        if (status == 400 || status == 401 || status == 403) await _expire();
        return handler.next(err);
      } on Object {
        return handler.next(err);
      }
    }

    try {
      final replay = request.copyWith(
        headers: {
          ...request.headers,
          'Authorization': 'Bearer ${tokens.accessToken}',
        },
        extra: {...request.extra, _retriedKey: true},
      );
      handler.resolve(await _plain.fetch<dynamic>(replay));
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  Future<void> _expire() async {
    await tokenStore.clear();
    await onSessionExpired?.call();
  }
}
