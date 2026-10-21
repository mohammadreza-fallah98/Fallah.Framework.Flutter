import 'package:fallah_core/fallah_core.dart';

import 'error_mapper.dart';

/// Backend envelope: `{ isSuccess, data, errorMessages }`.
class ApiResponse<T> {
  const ApiResponse({
    required this.isSuccess,
    this.data,
    this.errorMessages = const [],
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromData,
  ) {
    final raw = json['data'];
    return ApiResponse(
      isSuccess: json['isSuccess'] == true,
      data: raw == null ? null : fromData(raw),
      errorMessages: parseErrorMessages(json['errorMessages']),
    );
  }

  final bool isSuccess;
  final T? data;
  final List<Object> errorMessages;

  /// Throws a [Failure] when the envelope reports an error (even on HTTP 200).
  void requireSuccess() {
    if (!isSuccess) throw ErrorMapper.fromEnvelope(errorMessages);
  }

  /// Like [requireSuccess], and also requires a non-null [data].
  T requireData() {
    requireSuccess();
    final value = data;
    if (value == null) throw const UnknownFailure('Empty response');
    return value;
  }
}

/// Backend list envelope: `data: { items, totalCount, page, pageSize }`.
class ApiListResponse<T> {
  const ApiListResponse({
    required this.isSuccess,
    this.items = const [],
    this.totalCount = 0,
    this.page = 1,
    this.pageSize = 20,
    this.errorMessages = const [],
  });

  factory ApiListResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic> json) fromItem,
  ) {
    final data = json['data'];
    final map = data is Map<String, dynamic> ? data : const <String, dynamic>{};
    final rawItems = map['items'];
    return ApiListResponse(
      isSuccess: json['isSuccess'] == true,
      items: [
        if (rawItems is List)
          for (final item in rawItems)
            if (item is Map<String, dynamic>) fromItem(item),
      ],
      totalCount: (map['totalCount'] as num?)?.toInt() ?? 0,
      page: (map['page'] as num?)?.toInt() ?? 1,
      pageSize: (map['pageSize'] as num?)?.toInt() ?? 20,
      errorMessages: parseErrorMessages(json['errorMessages']),
    );
  }

  final bool isSuccess;
  final List<T> items;
  final int totalCount;
  final int page;
  final int pageSize;
  final List<Object> errorMessages;

  /// Throws a [Failure] when the envelope reports an error.
  ApiListResponse<T> requireSuccess() {
    if (!isSuccess) throw ErrorMapper.fromEnvelope(errorMessages);
    return this;
  }

  PagedList<T> toPagedList() => PagedList(
        items: items,
        totalCount: totalCount,
        page: page,
        pageSize: pageSize,
      );
}

/// `errorMessages` may be plain strings or `{field, message, code}` objects.
List<Object> parseErrorMessages(Object? raw) {
  if (raw is! List) return const [];
  return [
    for (final e in raw)
      if (e is String || e is Map) e as Object,
  ];
}
