import 'package:fallah_core/fallah_core.dart';
import 'package:fallah_network/fallah_network.dart';
import 'package:test/test.dart';

void main() {
  test('ApiResponse parses envelope', () {
    final r = ApiResponse<int>.fromJson(
      {'isSuccess': true, 'data': 5, 'errorMessages': <Object>[]},
      (j) => j! as int,
    );
    expect(r.isSuccess, isTrue);
    expect(r.data, 5);
  });

  test('requireData throws Failure for isSuccess=false even on 200', () {
    final r = ApiResponse<int>.fromJson(
      {
        'isSuccess': false,
        'errorMessages': ['boom'],
      },
      (j) => j! as int,
    );
    expect(r.requireData, throwsA(isA<ServerFailure>()));
  });

  test('ApiListResponse parses items and paging', () {
    final r = ApiListResponse<String>.fromJson(
      {
        'isSuccess': true,
        'data': {
          'items': [
            {'name': 'a'},
            {'name': 'b'},
          ],
          'totalCount': 42,
          'page': 2,
          'pageSize': 2,
        },
      },
      (j) => j['name'] as String,
    );
    final page = r.toPagedList();
    expect(page.items, ['a', 'b']);
    expect(page.totalCount, 42);
    expect(page.page, 2);
  });
}
