import 'package:dio/dio.dart';
import 'package:fallah_core/fallah_core.dart';

import 'api_response.dart';

/// Standard CRUD calls of a Fallah backend resource (`api/v1/<plural>`):
/// `GET` list/by-id, `POST` (returns `{ id }`), `PUT {id}`, `DELETE {id}`.
/// Every method unwraps the `{isSuccess,data,errorMessages}` envelope and
/// throws a [Failure] when it reports an error; Dio errors propagate as
/// `DioException` (map both with `apiCall`).
class ResourceClient<T> {
  ResourceClient(this._dio, this.path, this._fromJson);

  final Dio _dio;

  /// Relative to the Dio base URL, e.g. `provinces`.
  final String path;
  final T Function(Map<String, dynamic> json) _fromJson;

  Future<PagedList<T>> list(
    PageQuery query, {
    Map<String, Object?> filters = const {},
    String subPath = '',
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      _url(subPath),
      queryParameters: {
        ...query.toQuery(),
        for (final e in filters.entries)
          if (e.value != null) e.key: e.value,
      },
    );
    return ApiListResponse.fromJson(response.data!, _fromJson)
        .requireSuccess()
        .toPagedList();
  }

  Future<T> get(int id, {String subPath = ''}) async {
    final response = await _dio.get<Map<String, dynamic>>(_url('$id$subPath'));
    return ApiResponse<T>.fromJson(
      response.data!,
      (json) => _fromJson(json! as Map<String, dynamic>),
    ).requireData();
  }

  /// Returns the new record id (`data.id`).
  Future<int> add(Map<String, dynamic> body) async {
    final response = await _dio.post<Map<String, dynamic>>(
      _url(''),
      data: body,
    );
    final data = ApiResponse<Map<String, dynamic>>.fromJson(
      response.data!,
      (json) => json! as Map<String, dynamic>,
    ).requireData();
    return (data['id']! as num).toInt();
  }

  /// `PUT path/{id}`; [body] must include `id` (and `rowVersion` when known).
  Future<void> edit(int id, Map<String, dynamic> body) async {
    final response = await _dio.put<Map<String, dynamic>>(
      _url('$id'),
      data: body,
    );
    _requireSuccess(response.data!);
  }

  Future<void> remove(int id) async {
    final response = await _dio.delete<Map<String, dynamic>>(_url('$id'));
    _requireSuccess(response.data!);
  }

  /// Raw call under this resource (login-style actions, PATCH, ...), unwrapped
  /// to the envelope's `data` (null when absent).
  Future<Object?> action(
    String method,
    String subPath, {
    Object? body,
    Map<String, Object?> query = const {},
    Map<String, Object?>? extra,
  }) async {
    final response = await _dio.request<Map<String, dynamic>>(
      _url(subPath),
      data: body,
      queryParameters: {
        for (final e in query.entries)
          if (e.value != null) e.key: e.value,
      },
      options: Options(method: method, extra: extra),
    );
    final envelope = ApiResponse<Object>.fromJson(
      response.data!,
      (json) => json!,
    )..requireSuccess();
    return envelope.data;
  }

  void _requireSuccess(Map<String, dynamic> json) =>
      ApiResponse<Object>.fromJson(json, (j) => j!).requireSuccess();

  String _url(String sub) => sub.isEmpty ? path : '$path/$sub';
}
