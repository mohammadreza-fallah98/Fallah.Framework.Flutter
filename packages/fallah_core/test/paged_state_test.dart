import 'package:fallah_core/fallah_core.dart';
import 'package:test/test.dart';

PagedList<int> page(List<int> items, int p) =>
    PagedList(items: items, totalCount: 4, page: p, pageSize: 2);

void main() {
  test('nextPage appends and updates paging', () async {
    final first = PagedState(page([1, 2], 1));
    expect(first.hasMore, isTrue);

    final all = await nextPage(first.loadingMore(), (q) async {
      expect(q.page, 2);
      return page([3, 4], 2);
    });

    expect(all.items, [1, 2, 3, 4]);
    expect(all.hasMore, isFalse);
    expect(all.isLoadingMore, isFalse);
  });

  test('a failed page keeps the current items and stops loading', () async {
    final first = PagedState(page([1, 2], 1));

    final result = await nextPage<int>(
      first.loadingMore(),
      (_) async => throw const NetworkFailure('x'),
    );

    expect(result.items, [1, 2]);
    expect(result.isLoadingMore, isFalse);
  });

  test('getOrThrow returns the value or throws the Failure', () {
    expect(const Result.success(3).getOrThrow(), 3);
    expect(
      const Result<int>.error(NotFoundFailure()).getOrThrow,
      throwsA(isA<NotFoundFailure>()),
    );
  });
}
