import 'package:flutter/material.dart';

/// Brand tokens that Material's [ColorScheme] has no slot for.
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    required this.success,
    required this.onSuccess,
    required this.warning,
    required this.onWarning,
    required this.info,
    required this.onInfo,
  });

  static const light = AppTokens(
    success: Color(0xFF1B7F3B),
    onSuccess: Colors.white,
    warning: Color(0xFFB26A00),
    onWarning: Colors.white,
    info: Color(0xFF0B63C5),
    onInfo: Colors.white,
  );

  static const dark = AppTokens(
    success: Color(0xFF6FD28B),
    onSuccess: Color(0xFF00210C),
    warning: Color(0xFFFFB95C),
    onWarning: Color(0xFF3A2000),
    info: Color(0xFF9CC6FF),
    onInfo: Color(0xFF002D5E),
  );

  final Color success;
  final Color onSuccess;
  final Color warning;
  final Color onWarning;
  final Color info;
  final Color onInfo;

  @override
  AppTokens copyWith({
    Color? success,
    Color? onSuccess,
    Color? warning,
    Color? onWarning,
    Color? info,
    Color? onInfo,
  }) =>
      AppTokens(
        success: success ?? this.success,
        onSuccess: onSuccess ?? this.onSuccess,
        warning: warning ?? this.warning,
        onWarning: onWarning ?? this.onWarning,
        info: info ?? this.info,
        onInfo: onInfo ?? this.onInfo,
      );

  @override
  AppTokens lerp(ThemeExtension<AppTokens>? other, double t) {
    if (other is! AppTokens) return this;
    return AppTokens(
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      info: Color.lerp(info, other.info, t)!,
      onInfo: Color.lerp(onInfo, other.onInfo, t)!,
    );
  }
}

extension AppTokensContext on BuildContext {
  AppTokens get tokens =>
      Theme.of(this).extension<AppTokens>() ?? AppTokens.light;
}
