import 'package:dio/dio.dart';
import 'package:fallah_core/fallah_core.dart';
import 'package:fallah_network/fallah_network.dart';
import 'package:test/test.dart';

DioException badResponse(
  int status, [
  Object? data,
  Map<String, List<String>>? headers,
]) {
  final options = RequestOptions(path: '/x');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response(
      requestOptions: options,
      statusCode: status,
      data: data,
      headers: Headers.fromMap(headers ?? {}),
    ),
  );
}

void main() {
  test('maps status codes to Failure types', () {
    expect(ErrorMapper.map(badResponse(401)), isA<UnauthorizedFailure>());
    expect(ErrorMapper.map(badResponse(403)), isA<ForbiddenFailure>());
    expect(ErrorMapper.map(badResponse(404)), isA<NotFoundFailure>());
    expect(ErrorMapper.map(badResponse(409)), isA<ConflictFailure>());
    expect(ErrorMapper.map(badResponse(500)), isA<ServerFailure>());
  });

  test('400 carries field errors from errorMessages', () {
    final f = ErrorMapper.map(
      badResponse(400, {
        'isSuccess': false,
        'errorMessages': [
          {'field': 'mobile', 'message': 'invalid mobile', 'code': 'E1'},
          'plain message',
        ],
      }),
    ) as ValidationFailure;
    expect(f.message, 'invalid mobile');
    expect(f.code, 'E1');
    expect(f.errorsFor('mobile'), ['invalid mobile']);
    expect(f.errors, hasLength(2));
  });

  test('429 reads Retry-After', () {
    final f = ErrorMapper.map(
      badResponse(429, null, {
        'retry-after': ['7'],
      }),
    ) as RateLimitFailure;
    expect(f.retryAfter, const Duration(seconds: 7));
  });

  test('timeouts and connection errors are NetworkFailure', () {
    for (final type in [
      DioExceptionType.connectionTimeout,
      DioExceptionType.receiveTimeout,
      DioExceptionType.connectionError,
    ]) {
      final e =
          DioException(requestOptions: RequestOptions(path: '/x'), type: type);
      expect(ErrorMapper.map(e), isA<NetworkFailure>());
    }
  });

  test('apiCall converts thrown DioException to Error result', () async {
    final result = await apiCall<int>(() async => throw badResponse(404));
    expect(result.failureOrNull, isA<NotFoundFailure>());
  });
}
