import 'package:dio/dio.dart';
import 'package:fallah_core/fallah_core.dart';
import 'package:fallah_network/fallah_network.dart';
import 'package:test/test.dart';

import 'support.dart';

class _Item {
  const _Item(this.id, this.name);
  factory _Item.fromJson(Map<String, dynamic> j) =>
      _Item(j['id'] as int, j['name'] as String);
  final int id;
  final String name;
}

void main() {
  late FakeAdapter adapter;
  late ResourceClient<_Item> client;

  ResourceClient<_Item> build(ResponseBody Function(RequestOptions) h) {
    adapter = FakeAdapter(h);
    final dio = Dio(BaseOptions(baseUrl: 'http://t/api/v1'))
      ..httpClientAdapter = adapter;
    return client = ResourceClient(dio, 'items', _Item.fromJson);
  }

  test('list sends paging and non-null filters, parses items', () async {
    build(
      (_) => jsonBody(200, {
        'isSuccess': true,
        'data': {
          'items': [
            {'id': 1, 'name': 'a'},
          ],
          'totalCount': 1,
          'page': 1,
          'pageSize': 20,
        },
      }),
    );

    final page = await client.list(
      const PageQuery(),
      filters: {'ProvinceId': 3, 'Skip': null},
    );

    expect(page.items.single.name, 'a');
    final q = adapter.requests.single.queryParameters;
    expect(q['Page'], 1);
    expect(q['ProvinceId'], 3);
    expect(q.containsKey('Skip'), isFalse);
  });

  test('add returns data.id', () async {
    build(
      (_) => jsonBody(200, {
        'isSuccess': true,
        'data': {'id': 42},
      }),
    );
    expect(await client.add({'name': 'x'}), 42);
    expect(adapter.requests.single.method, 'POST');
  });

  test('edit PUTs to path/id and remove DELETEs', () async {
    build(
      (_) => jsonBody(200, {'isSuccess': true, 'data': <String, dynamic>{}}),
    );
    await client.edit(5, {'id': 5, 'name': 'y'});
    await client.remove(5);
    expect(adapter.requests[0].method, 'PUT');
    expect(adapter.requests[0].path, 'items/5');
    expect(adapter.requests[1].method, 'DELETE');
  });

  test('envelope failure on HTTP 200 throws a Failure', () {
    build(
      (_) => jsonBody(200, {
        'isSuccess': false,
        'errorMessages': ['nope'],
      }),
    );
    expect(client.remove(1), throwsA(isA<ServerFailure>()));
  });

  test('action issues a custom method and returns data', () async {
    build(
      (_) => jsonBody(200, {
        'isSuccess': true,
        'data': {'k': 'v'},
      }),
    );
    final data = await client.action('PATCH', '1/status', body: {'a': 1});
    expect((data! as Map)['k'], 'v');
    expect(adapter.requests.single.method, 'PATCH');
    expect(adapter.requests.single.path, 'items/1/status');
  });
}
