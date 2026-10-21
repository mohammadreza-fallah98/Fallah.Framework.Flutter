import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_config.g.dart';

enum Flavor { dev, stg, prd }

/// Read from `--dart-define-from-file=env/<flavor>.json`.
class AppConfig {
  const AppConfig({
    required this.flavor,
    required this.apiBaseUrl,
    this.enableLogging = false,
  });

  factory AppConfig.fromEnvironment() {
    const flavorName = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
    const apiBaseUrl = String.fromEnvironment('API_BASE_URL');
    assert(apiBaseUrl != '', 'API_BASE_URL is missing: use --dart-define-from-file');
    return AppConfig(
      flavor: Flavor.values.byName(flavorName),
      apiBaseUrl: apiBaseUrl,
      enableLogging: const bool.fromEnvironment('ENABLE_LOGGING'),
    );
  }

  final Flavor flavor;

  /// Includes the API prefix, e.g. `https://host/api/v1`.
  final String apiBaseUrl;
  final bool enableLogging;
}

/// Overridden in `bootstrap`.
@Riverpod(keepAlive: true)
AppConfig appConfig(Ref ref) => throw UnimplementedError('override in bootstrap');
