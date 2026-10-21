import 'package:dio/dio.dart';
import 'package:fallah_api/fallah_api.dart';
import 'package:fallah_network/fallah_network.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:{{project_name.snakeCase()}}/core/auth/auth_providers.dart';
import 'package:{{project_name.snakeCase()}}/core/config/app_config.dart';
import 'package:{{project_name.snakeCase()}}/core/l10n/locale_provider.dart';
import 'package:{{project_name.snakeCase()}}/core/logging/logger_provider.dart';

part 'dio_provider.g.dart';

/// The one Dio of the app. Datasources receive it; widgets never touch it.
@Riverpod(keepAlive: true)
Dio dio(Ref ref) {
  final config = ref.watch(appConfigProvider);
  return createDio(
    config: NetworkConfig(
      baseUrl: config.apiBaseUrl,
      enableLogging: config.enableLogging,
    ),
    languageCode: () => ref.read(localeControllerProvider).languageCode,
    tokenStore: ref.watch(tokenStoreProvider),
    refresh: AuthApi.refreshTokens,
    // Read lazily: SessionManager's permission loader itself uses this Dio.
    onSessionExpired: () => ref.read(sessionManagerProvider).expire(),
    logger: ref.watch(loggerProvider),
  );
}
