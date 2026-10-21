import 'package:dio/dio.dart';

/// Access/refresh token pair.
class AuthTokens {
  const AuthTokens({required this.accessToken, required this.refreshToken});

  final String accessToken;
  final String refreshToken;
}

/// Where tokens live. The app/`fallah_auth` implements this on top of
/// `flutter_secure_storage`; tests can use an in-memory fake.
abstract interface class TokenStore {
  Future<AuthTokens?> read();
  Future<void> save(AuthTokens tokens);
  Future<void> clear();
}

/// Exchanges a refresh token for a new pair (e.g. `POST /users/refresh-token`).
///
/// Use the supplied [plainClient] (no auth interceptor) for the call, otherwise
/// the request would wait on the interceptor queue it is blocking.
typedef TokenRefresher = Future<AuthTokens> Function(
  Dio plainClient,
  String refreshToken,
);
