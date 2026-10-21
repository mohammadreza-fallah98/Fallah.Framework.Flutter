/// Static settings for the shared Dio client.
class NetworkConfig {
  const NetworkConfig({
    required this.baseUrl,
    this.connectTimeout = const Duration(seconds: 10),
    this.receiveTimeout = const Duration(seconds: 30),
    this.sendTimeout = const Duration(seconds: 30),
    this.maxRetries = 2,
    this.enableLogging = false,
  });

  /// Includes the API prefix, e.g. `https://host/api/v1`.
  final String baseUrl;
  final Duration connectTimeout;
  final Duration receiveTimeout;
  final Duration sendTimeout;

  /// Retries for idempotent GET requests that failed with a network error.
  final int maxRetries;

  /// Enable only in debug builds.
  final bool enableLogging;
}
