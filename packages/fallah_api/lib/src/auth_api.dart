import 'package:dio/dio.dart';
import 'package:fallah_auth/fallah_auth.dart';
import 'package:fallah_core/fallah_core.dart';
import 'package:fallah_network/fallah_network.dart';

import 'user.dart';

/// Authentication endpoints of `api/v1/users`. Implements both sign-in
/// contracts of `fallah_auth`; use whichever the project needs.
///
/// Token responses are expected as `data: { accessToken, refreshToken }`.
class AuthApi implements PasswordAuthRepository, OtpAuthRepository {
  AuthApi(Dio dio) : _users = ResourceClient<User>(dio, 'users', User.fromJson);

  /// Requests that must not carry (or wait for) a bearer token.
  static const _anonymous = <String, Object?>{
    AuthInterceptor.skipAuthKey: true,
  };

  final ResourceClient<User> _users;

  @override
  Future<Result<AuthTokens>> login({
    required String username,
    required String password,
  }) =>
      apiCall(
        () async => _tokens(
          await _users.action(
            'POST',
            'login',
            body: {'username': username, 'password': password},
            extra: _anonymous,
          ),
        ),
      );

  @override
  Future<Result<Duration?>> requestOtp(String mobile) => apiCall(() async {
        await _users.action(
          'POST',
          'otp/send',
          body: {'mobile': mobile},
          extra: _anonymous,
        );
        return null;
      });

  @override
  Future<Result<AuthTokens>> verifyOtp({
    required String mobile,
    required String code,
  }) =>
      apiCall(
        () async => _tokens(
          await _users.action(
            'POST',
            'otp/login',
            body: {'mobile': mobile, 'code': code},
            extra: _anonymous,
          ),
        ),
      );

  /// The signed-in user's profile.
  Future<Result<User>> me() => apiCall(() async {
        final data = await _users.action('GET', 'me');
        if (data is! Map<String, dynamic>) {
          throw const UnknownFailure('Invalid profile response');
        }
        return User.fromJson(data);
      });

  /// Revokes the refresh token server-side; call before
  /// `SessionManager.signOut`.
  Future<Result<void>> logout(String refreshToken) => apiCall(
        () => _users.action(
          'POST',
          'logout',
          body: {'refreshToken': refreshToken},
        ),
      );

  Future<Result<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) =>
      apiCall(
        () => _users.action(
          'PATCH',
          'change-password',
          body: {
            'currentPassword': currentPassword,
            'newPassword': newPassword,
          },
        ),
      );

  /// Plug into `createDio(refresh: AuthApi.refreshTokens)`.
  static Future<AuthTokens> refreshTokens(
    Dio plainClient,
    String refreshToken,
  ) async {
    final data =
        await ResourceClient<User>(plainClient, 'users', User.fromJson).action(
      'POST',
      'refresh-token',
      body: {'refreshToken': refreshToken},
      extra: _anonymous,
    );
    return _tokens(data);
  }

  static AuthTokens _tokens(Object? data) {
    if (data is Map<String, dynamic>) {
      final access = data['accessToken'];
      final refresh = data['refreshToken'];
      if (access is String && refresh is String) {
        return AuthTokens(accessToken: access, refreshToken: refresh);
      }
    }
    throw const UnknownFailure('Invalid token response');
  }
}
