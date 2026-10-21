import 'package:fallah_core/fallah_core.dart';
import 'package:fallah_network/fallah_network.dart';

/// Username + password sign-in. Implemented per project.
abstract interface class PasswordAuthRepository {
  Future<Result<AuthTokens>> login({
    required String username,
    required String password,
  });
}

/// Mobile + one-time-code sign-in. Implemented per project.
abstract interface class OtpAuthRepository {
  /// Sends the code; returns the resend cool-down if the backend reports one.
  Future<Result<Duration?>> requestOtp(String mobile);

  Future<Result<AuthTokens>> verifyOtp({
    required String mobile,
    required String code,
  });
}
