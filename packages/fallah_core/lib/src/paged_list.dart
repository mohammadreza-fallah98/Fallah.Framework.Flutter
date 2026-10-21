/// One page of a server-paged list. `page` starts at 1.
class PagedList<T> {
  const PagedList({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
  });

  const PagedList.empty({this.pageSize = 20})
      : items = const [],
        totalCount = 0,
        page = 1;

  final List<T> items;
  final int totalCount;
  final int page;
  final int pageSize;

  int get totalPages => pageSize <= 0 ? 0 : (totalCount / pageSize).ceil();
  bool get hasNext => page < totalPages;

  PagedList<R> map<R>(R Function(T item) transform) => PagedList<R>(
        items: items.map(transform).toList(growable: false),
        totalCount: totalCount,
        page: page,
        pageSize: pageSize,
      );
}

/// Query parameters shared by all list endpoints
/// (`Page`, `PageSize`, `SortBy[]`, `SortType` = `Asc`/`Desc`).
class PageQuery {
  const PageQuery({
    this.page = 1,
    this.pageSize = 20,
    this.sortBy = const [],
    this.descending = false,
  });

  final int page;
  final int pageSize;
  final List<String> sortBy;
  final bool descending;

  PageQuery copyWith({int? page, int? pageSize}) => PageQuery(
        page: page ?? this.page,
        pageSize: pageSize ?? this.pageSize,
        sortBy: sortBy,
        descending: descending,
      );

  /// Repeated `SortBy` keys are encoded by Dio as `SortBy=a&SortBy=b`
  /// (default `ListFormat.multi`).
  Map<String, Object> toQuery() => {
        'Page': page,
        'PageSize': pageSize,
        if (sortBy.isNotEmpty) 'SortBy': sortBy,
        if (sortBy.isNotEmpty) 'SortType': descending ? 'Desc' : 'Asc',
      };
}
