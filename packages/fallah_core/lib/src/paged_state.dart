import 'failure.dart';
import 'paged_list.dart';

/// Accumulated pages of a list screen plus the load-more flag. UI-agnostic:
/// a Riverpod notifier or a Bloc can hold it.
class PagedState<T> {
  const PagedState(this.page, {this.isLoadingMore = false});

  final PagedList<T> page;
  final bool isLoadingMore;

  List<T> get items => page.items;
  bool get hasMore => page.hasNext;

  PagedState<T> loadingMore() => PagedState(page, isLoadingMore: true);

  /// Appends [next] (the following page) to the current items.
  PagedState<T> appended(PagedList<T> next) => PagedState(
        PagedList(
          items: [...page.items, ...next.items],
          totalCount: next.totalCount,
          page: next.page,
          pageSize: next.pageSize,
        ),
      );
}

/// Fetches the page after [current] with [fetch] and returns the merged
/// state. A failed page returns [current] unchanged (not loading): the list
/// stays usable and the user can pull to refresh to retry.
Future<PagedState<T>> nextPage<T>(
  PagedState<T> current,
  Future<PagedList<T>> Function(PageQuery query) fetch,
) async {
  try {
    final next = await fetch(
      PageQuery(
        page: current.page.page + 1,
        pageSize: current.page.pageSize,
      ),
    );
    return current.appended(next);
  } on Failure {
    return PagedState(current.page);
  }
}
