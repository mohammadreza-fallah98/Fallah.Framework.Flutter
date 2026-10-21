import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:fallah_api/fallah_api.dart';
import 'package:fallah_core/fallah_core.dart';
import 'package:fallah_network/fallah_network.dart';
import 'package:test/test.dart';

class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.handler);

  final ResponseBody Function(RequestOptions options) handler;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody ok(Object? data) => ResponseBody.fromString(
      jsonEncode({'isSuccess': true, 'data': data}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

Map<String, dynamic> page(List<Map<String, dynamic>> items) => {
      'items': items,
      'totalCount': items.length,
      'page': 1,
      'pageSize': 20,
    };

void main() {
  late FakeAdapter adapter;
  late Dio dio;

  void serve(ResponseBody Function(RequestOptions) handler) {
    adapter = FakeAdapter(handler);
    dio = Dio(BaseOptions(baseUrl: 'http://t/api/v1'))
      ..httpClientAdapter = adapter;
  }

  test('Province round-trips audit fields and rowVersion', () {
    final p = Province.fromJson({
      'id': 1,
      'name': 'Tehran',
      'createdByName': 'admin',
      'createdAt': '2026-08-02T13:45:10+03:30',
      'rowVersion': 'AAAB',
    });
    expect(p.audit.createdByName, 'admin');
    expect(p.audit.createdAt!.toUtc().hour, 10);
    expect(p.toUpdateJson(), {'id': 1, 'name': 'Tehran', 'rowVersion': 'AAAB'});
    expect(p.toCreateJson(), {'name': 'Tehran'});
  });

  test('CityRepository.byProvince filters by ProvinceId', () async {
    serve(
      (_) => ok(
        page([
          {'id': 5, 'name': 'Ray', 'provinceId': 3},
        ]),
      ),
    );

    final result = await CityRepository(dio).byProvince(3);

    expect(result.valueOrNull!.items.single.name, 'Ray');
    expect(adapter.requests.single.path, 'cities');
    expect(adapter.requests.single.queryParameters['ProvinceId'], 3);
  });

  test('RoleScopeRepository.myScopes returns the scope set', () async {
    serve((_) => ok(['user:read', 'user:create', 7]));

    final result = await RoleScopeRepository(dio).myScopes();

    expect(result.valueOrNull, {'user:read', 'user:create'});
    expect(adapter.requests.single.path, 'role-scopes/my-scopes');
  });

  test('RoleScope keeps unknown visibility codes', () {
    final s = RoleScope.fromJson({
      'id': 1,
      'roleId': 2,
      'entityName': 'chat',
      'canRead': true,
      'visibilityLevel': 9,
    });
    expect(s.canRead, isTrue);
    expect(s.visibility, isNull);
    expect(s.visibilityLevel, 9);
    expect(VisibilityLevel.fromCode(4), VisibilityLevel.all);
  });

  group('AuthApi', () {
    test('login returns tokens and skips the bearer token', () async {
      serve((_) => ok({'accessToken': 'a', 'refreshToken': 'r'}));

      final result = await AuthApi(dio).login(username: 'u', password: 'p');

      expect(result.valueOrNull!.accessToken, 'a');
      final req = adapter.requests.single;
      expect(req.path, 'users/login');
      expect(req.extra[AuthInterceptor.skipAuthKey], isTrue);
      expect(req.data, {'username': 'u', 'password': 'p'});
    });

    test('a malformed token response is an UnknownFailure', () async {
      serve((_) => ok({'oops': true}));

      final result = await AuthApi(dio).login(username: 'u', password: 'p');

      expect(result.failureOrNull, isA<UnknownFailure>());
    });

    test('OTP flow and refreshTokens use the right routes', () async {
      serve(
        (o) => ok(
          o.path.endsWith('otp/send')
              ? null
              : {'accessToken': 'a2', 'refreshToken': 'r2'},
        ),
      );
      final api = AuthApi(dio);

      expect((await api.requestOtp('09121234567')).isSuccess, isTrue);
      expect(
        (await api.verifyOtp(mobile: '09121234567', code: '1234'))
            .valueOrNull!
            .refreshToken,
        'r2',
      );
      final tokens = await AuthApi.refreshTokens(dio, 'old');

      expect(tokens.accessToken, 'a2');
      expect(
        adapter.requests.map((r) => r.path),
        ['users/otp/send', 'users/otp/login', 'users/refresh-token'],
      );
    });

    test('me parses the profile', () async {
      serve((_) => ok({'id': 9, 'roleId': 1, 'username': 'admin'}));
      expect((await AuthApi(dio).me()).valueOrNull!.username, 'admin');
    });
  });

  test('UserRepository.create sends the password, responses never do',
      () async {
    serve((_) => ok({'id': 11}));

    final id = await UserRepository(dio).create(
      const User(id: 0, roleId: 2, username: 'ali', mobile: '09121234567'),
      password: 'Secret#1',
    );

    expect(id.valueOrNull, 11);
    final body = adapter.requests.single.data as Map<String, dynamic>;
    expect(body['password'], 'Secret#1');
    expect(
      const User(id: 1, roleId: 1, username: 'x').toUpdateJson(),
      isNot(contains('password')),
    );
  });

  test('ChatRepository: markSeen PATCH and attachments parsing', () async {
    serve((o) {
      if (o.path.endsWith('with-attachments')) {
        return ok(
          page([
            {
              'id': 1,
              'subject': 'support',
              'message': 'hi',
              'attachments': [
                {
                  'id': 3,
                  'url': 'a/b.png',
                  'fileName': 'b.png',
                  'contentType': 'image/png',
                },
              ],
            },
          ]),
        );
      }
      return ok(null);
    });
    final repo = ChatRepository(dio);

    final result = await repo.withAttachments('support');
    expect(result.valueOrNull!.items.single.attachments.single.isImage, isTrue);

    await repo.markSeen(1);
    expect(adapter.requests.last.method, 'PATCH');
    expect(adapter.requests.last.path, 'chats/1/seen');
  });

  test('AttachmentRepository.upload returns url and id', () async {
    serve((_) => ok({'url': 'x/y.png', 'attachmentId': 8}));

    final result = await AttachmentRepository(dio).upload(
      bytes: Uint8List.fromList([1, 2, 3]),
      filename: 'y.png',
    );

    expect(result.valueOrNull!.attachmentId, 8);
    expect(adapter.requests.single.data, isA<FormData>());
  });

  test('AuditLogRepository sends filters and ISO dates', () async {
    serve(
      (_) => ok(
        page([
          {'id': 1, 'entityName': 'user', 'action': 'Added'},
        ]),
      ),
    );

    final result = await AuditLogRepository(dio).list(
      entityName: 'user',
      from: DateTime.utc(2026),
    );

    expect(result.valueOrNull!.items.single.action, 'Added');
    final q = adapter.requests.single.queryParameters;
    expect(q['EntityName'], 'user');
    expect(q['From'], '2026-01-01T00:00:00.000Z');
    expect(q.containsKey('UserId'), isFalse);
  });

  test('AttachmentChatRepository links and unlinks', () async {
    serve((_) => ok({'id': 4}));
    final repo = AttachmentChatRepository(dio);

    expect((await repo.link(attachmentId: 1, chatId: 2)).valueOrNull, 4);
    await repo.unlink(4);

    expect(adapter.requests[0].data, {'attachmentId': 1, 'chatId': 2});
    expect(adapter.requests[1].method, 'DELETE');
  });
}
