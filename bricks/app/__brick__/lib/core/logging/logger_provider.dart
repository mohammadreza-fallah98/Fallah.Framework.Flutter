import 'package:fallah_core/fallah_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:{{project_name.snakeCase()}}/core/config/app_config.dart';

part 'logger_provider.g.dart';

/// Swap [ConsoleLogger] for a Sentry-backed [AppLogger] in production.
@Riverpod(keepAlive: true)
AppLogger logger(Ref ref) => ConsoleLogger(
      minLevel: ref.watch(appConfigProvider).enableLogging
          ? LogLevel.debug
          : LogLevel.warning,
    );
