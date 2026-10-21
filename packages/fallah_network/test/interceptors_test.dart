import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:fallah_network/fallah_network.dart';
import 'package:test/test.dart';

import 'support.dart';

Dio build({
  required FakeAdapter adapter,
  MemoryTokenStore? store,
  TokenRefresher? refresh,
  Future<void> Function()? onExpired,
  String lang = 'fa',
  int retries = 2,
}) =>
    createDio(
      config: NetworkConfig(baseUrl: 'http://test/api/v1', maxRetries: retries),
      languageCode: () => lang,
      tokenStore: store,
      refresh: refresh,
      onSessionExpired: onExpired,
      adapter: adapter,
    );

void main() {
  test('adds correlation id, language and bearer token', () async {
    final adapter = FakeAdapter((_) => jsonBody(200, {'isSuccess': true}));
    final store = MemoryTokenStore(
      const AuthTokens(accessToken: 'a1', refreshToken: 'r1'),
    );
    final dio = build(
      adapter: adapter,
      store: store,
      refresh: (_, __) async => throw StateError('unused'),
      lang: 'en',
    );

    await dio.get<dynamic>('/ping');

    final h = adapter.requests.single.headers;
    expect(h['Authorization'], 'Bearer a1');
    expect(h['X-Language'], 'en');
    expect(h['X-Correlation-Id'], matches(RegExp(r'^[0-9a-f-]{36}$')));
  });

  test('persian sends no X-Language', () async {
    final adapter = FakeAdapter((_) => jsonBody(200, {}));
    await build(adapter: adapter).get<dynamic>('/ping');
    expect(adapter.requests.single.headers.containsKey('X-Language'), isFalse);
  });

  test('401 triggers a single refresh shared by concurrent requests', () async {
    var refreshCalls = 0;
    final adapter = FakeAdapter((o) {
      return o.headers['Authorization'] == 'Bearer new'
          ? jsonBody(200, {'ok': true})
          : jsonBody(401, {'isSuccess': false});
    });
    final store = MemoryTokenStore(
      const AuthTokens(accessToken: 'old', refreshToken: 'r1'),
    );
    final dio = build(
      adapter: adapter,
      store: store,
      refresh: (plain, refreshToken) async {
        refreshCalls++;
        expect(refreshToken, 'r1');
        return const AuthTokens(accessToken: 'new', refreshToken: 'r2');
      },
    );

    final results = await Future.wait([
      dio.get<dynamic>('/a'),
      dio.get<dynamic>('/b'),
    ]);

    expect(results.map((r) => r.statusCode), [200, 200]);
    expect(refreshCalls, 1);
    expect(store.tokens!.refreshToken, 'r2');
  });

  test('failed refresh clears session and surfaces the 401', () async {
    var expired = false;
    final adapter = FakeAdapter((_) => jsonBody(401, {'isSuccess': false}));
    final store = MemoryTokenStore(
      const AuthTokens(accessToken: 'old', refreshToken: 'r1'),
    );
    final dio = build(
      adapter: adapter,
      store: store,
      refresh: (_, __) async => throw DioException(
        requestOptions: RequestOptions(path: '/refresh'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/refresh'),
          statusCode: 401,
        ),
      ),
      onExpired: () async => expired = true,
    );

    await expectLater(
      dio.get<dynamic>('/a'),
      throwsA(
        isA<DioException>()
            .having((e) => e.response?.statusCode, 'status', 401),
      ),
    );
    expect(store.tokens, isNull);
    expect(expired, isTrue);
  });

  test('refresh hitting a 5xx keeps the session', () async {
    var expired = false;
    final adapter = FakeAdapter((_) => jsonBody(401, {'isSuccess': false}));
    final store = MemoryTokenStore(
      const AuthTokens(accessToken: 'old', refreshToken: 'r1'),
    );
    final dio = build(
      adapter: adapter,
      store: store,
      refresh: (_, __) async => throw DioException(
        requestOptions: RequestOptions(path: '/refresh'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/refresh'),
          statusCode: 503,
        ),
      ),
      onExpired: () async => expired = true,
    );

    await expectLater(dio.get<dynamic>('/a'), throwsA(isA<DioException>()));
    expect(store.tokens, isNotNull);
    expect(expired, isFalse);
  });

  test('uploadBytes sends multipart and reports progress', () async {
    final adapter = FakeAdapter((_) => jsonBody(200, {'isSuccess': true}));
    final dio = build(adapter: adapter);

    final result = await uploadBytes(
      dio,
      '/attachments/upload',
      bytes: Uint8List.fromList([1, 2, 3]),
      filename: 'a.png',
      fields: {'subject': 'chat'},
    );

    expect(result['isSuccess'], isTrue);
    final data = adapter.requests.single.data as FormData;
    expect(data.files.single.key, 'file');
    expect(data.files.single.value.filename, 'a.png');
    expect(data.fields.single.key, 'subject');
    expect(data.fields.single.value, 'chat');
  });

  test('GET is retried on connection error, then succeeds', () async {
    var calls = 0;
    final adapter = FakeAdapter((o) {
      calls++;
      if (calls < 3) {
        throw DioException(
          requestOptions: o,
          type: DioExceptionType.connectionError,
        );
      }
      return jsonBody(200, {'ok': true});
    });
    final dio = createDio(
      config: const NetworkConfig(baseUrl: 'http://test', maxRetries: 0),
      languageCode: () => 'fa',
      adapter: adapter,
    );
    dio.interceptors.add(
      RetryInterceptor(
        dio: dio,
        delay: (_) async {},
      ),
    );

    final r = await dio.get<dynamic>('/x');
    expect(r.statusCode, 200);
    expect(calls, 3);
  });

  test('POST is never retried', () async {
    var calls = 0;
    final adapter = FakeAdapter((o) {
      calls++;
      throw DioException(
        requestOptions: o,
        type: DioExceptionType.connectionError,
      );
    });
    final dio = createDio(
      config: const NetworkConfig(baseUrl: 'http://test', maxRetries: 0),
      languageCode: () => 'fa',
      adapter: adapter,
    );
    dio.interceptors.add(RetryInterceptor(dio: dio, delay: (_) async {}));

    await expectLater(dio.post<dynamic>('/x'), throwsA(isA<DioException>()));
    expect(calls, 1);
  });
}
