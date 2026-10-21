import 'dart:ui';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'locale_provider.g.dart';

/// Overridden in `bootstrap`.
@Riverpod(keepAlive: true)
SharedPreferences sharedPreferences(Ref ref) =>
    throw UnimplementedError('override in bootstrap');

/// App language (default `fa`, RTL). The choice persists in SharedPreferences.
@Riverpod(keepAlive: true)
class LocaleController extends _$LocaleController {
  static const _key = 'locale';

  @override
  Locale build() {
    final code = ref.watch(sharedPreferencesProvider).getString(_key);
    return Locale(code ?? 'fa');
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    await ref.read(sharedPreferencesProvider).setString(_key, locale.languageCode);
  }
}
