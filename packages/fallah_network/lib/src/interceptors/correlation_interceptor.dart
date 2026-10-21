import 'dart:math';

import 'package:dio/dio.dart';

/// Adds a random `X-Correlation-Id` (UUID v4) so a request can be traced
/// across client and server logs.
class CorrelationInterceptor extends Interceptor {
  CorrelationInterceptor({Random? random})
      : _random = random ?? Random.secure();

  static const header = 'X-Correlation-Id';
  final Random _random;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers.putIfAbsent(header, _uuidV4);
    handler.next(options);
  }

  String _uuidV4() {
    final b = List<int>.generate(16, (_) => _random.nextInt(256));
    b[6] = (b[6] & 0x0f) | 0x40;
    b[8] = (b[8] & 0x3f) | 0x80;
    final h = b.map((e) => e.toRadixString(16).padLeft(2, '0')).join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-'
        '${h.substring(16, 20)}-${h.substring(20)}';
  }
}
