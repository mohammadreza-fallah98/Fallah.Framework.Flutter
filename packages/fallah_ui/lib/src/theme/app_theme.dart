import 'package:flutter/material.dart';

import 'app_spacing.dart';
import 'app_tokens.dart';

/// Font families bundled with `fallah_ui` (Samim, SIL OFL 1.1).
abstract final class AppFonts {
  /// Latin digits stay Latin.
  static const samim = 'packages/fallah_ui/Samim';

  /// Same face; Latin digits are drawn as Persian digits (۰-۹).
  static const samimFarsiDigits = 'packages/fallah_ui/SamimFD';
}

/// Material 3 themes using the bundled Samim font. Pass another family name
/// (declared in the app's own `pubspec.yaml`) to override it.
abstract final class AppTheme {
  static const defaultFontFamily = AppFonts.samim;
  static const defaultSeed = Color(0xFF2E7D32);

  static ThemeData light({
    Color seed = defaultSeed,
    String fontFamily = defaultFontFamily,
  }) =>
      _build(Brightness.light, seed, fontFamily, AppTokens.light);

  static ThemeData dark({
    Color seed = defaultSeed,
    String fontFamily = defaultFontFamily,
  }) =>
      _build(Brightness.dark, seed, fontFamily, AppTokens.dark);

  static ThemeData _build(
    Brightness brightness,
    Color seed,
    String fontFamily,
    AppTokens tokens,
  ) {
    final scheme =
        ColorScheme.fromSeed(seedColor: seed, brightness: brightness);
    final radius = BorderRadius.circular(AppRadius.md);
    const minSize = Size(kMinTouchTarget, kMinTouchTarget);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: fontFamily,
      extensions: [tokens],
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: radius),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: minSize,
          shape: RoundedRectangleBorder(borderRadius: radius),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: minSize,
          shape: RoundedRectangleBorder(borderRadius: radius),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(minimumSize: minSize),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: radius),
      ),
    );
  }
}
