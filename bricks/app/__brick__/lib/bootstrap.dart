import 'dart:async';

import 'package:fallah_core/fallah_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:{{project_name.snakeCase()}}/app.dart';
import 'package:{{project_name.snakeCase()}}/core/auth/auth_providers.dart';
import 'package:{{project_name.snakeCase()}}/core/config/app_config.dart';
import 'package:{{project_name.snakeCase()}}/core/l10n/locale_provider.dart';
import 'package:{{project_name.snakeCase()}}/core/logging/logger_provider.dart';

Future<void> bootstrap(AppConfig config) async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      appConfigProvider.overrideWithValue(config),
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
    // Riverpod 3 retries failed providers by default. API failures (4xx, ...)
    // must reach the UI instead, where the user can retry explicitly.
    retry: (_, __) => null,
  );

  final logger = container.read(loggerProvider);
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    logger.log(LogLevel.error, details.exceptionAsString(),
        error: details.exception, stack: details.stack);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    logger.log(LogLevel.error, 'Uncaught error', error: error, stack: stack);
    return true;
  };

  // Resolves the splash: authenticated or unauthenticated.
  unawaited(container.read(sessionManagerProvider).restore());

  runApp(UncontrolledProviderScope(container: container, child: const App()));
}
