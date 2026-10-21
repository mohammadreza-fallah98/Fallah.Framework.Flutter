import 'package:fallah_core/fallah_core.dart';
import 'package:test/test.dart';

void main() {
  test('map transforms Success and preserves Error', () {
    expect(const Result.success(2).map((v) => v * 2).valueOrNull, 4);
    const err = Result<int>.error(NetworkFailure('offline'));
    expect(err.map((v) => v * 2).failureOrNull, isA<NetworkFailure>());
  });

  test('guard converts thrown errors to Failure', () async {
    final ok = await Result.guard(() async => 1);
    expect(ok.valueOrNull, 1);

    final bad = await Result.guard<int>(() async => throw StateError('x'));
    expect(bad.failureOrNull, isA<UnknownFailure>());
  });

  test('fold picks the right branch', () {
    const r = Result<int>.error(UnauthorizedFailure());
    expect(r.fold((_) => 'ok', (f) => f.message), 'Unauthorized');
  });

  test('ValidationFailure.errorsFor filters by field', () {
    const f = ValidationFailure(
      'bad',
      errors: [
        FieldError(field: 'mobile', message: 'invalid'),
        FieldError(field: 'name', message: 'required'),
      ],
    );
    expect(f.errorsFor('mobile'), ['invalid']);
  });

  test('PagedList paging math and PageQuery', () {
    const p = PagedList<int>(items: [1], totalCount: 45, page: 2, pageSize: 20);
    expect(p.totalPages, 3);
    expect(p.hasNext, isTrue);
    expect(
      const PageQuery(sortBy: ['name', 'id'], descending: true).toQuery(),
      {
        'Page': 1,
        'PageSize': 20,
        'SortBy': ['name', 'id'],
        'SortType': 'Desc',
      },
    );
    expect(const PageQuery().toQuery(), {'Page': 1, 'PageSize': 20});
    expect(const PageQuery().copyWith(page: 3).page, 3);
  });

  test('ConsoleLogger respects minLevel', () {
    final lines = <String>[];
    ConsoleLogger(minLevel: LogLevel.warning, sink: lines.add)
      ..log(LogLevel.info, 'skip')
      ..log(LogLevel.error, 'boom');
    expect(lines, ['[ERROR] boom']);
  });
}
