import 'package:dio/dio.dart';
import 'package:fallah_core/fallah_core.dart';
import 'package:fallah_network/fallah_network.dart';

/// Result-returning CRUD over a [ResourceClient]. Entity repositories extend
/// it and add their special endpoints; nothing here throws.
class CrudRepository<T> {
  CrudRepository(
    Dio dio, {
    required String path,
    required T Function(Map<String, dynamic> json) fromJson,
    required Map<String, dynamic> Function(T entity) createBody,
    required Map<String, dynamic> Function(T entity) updateBody,
    required int Function(T entity) idOf,
  })  : client = ResourceClient<T>(dio, path, fromJson),
        _createBody = createBody,
        _updateBody = updateBody,
        _idOf = idOf;

  final ResourceClient<T> client;
  final Map<String, dynamic> Function(T) _createBody;
  final Map<String, dynamic> Function(T) _updateBody;
  final int Function(T) _idOf;

  Future<Result<PagedList<T>>> list([
    PageQuery query = const PageQuery(),
    Map<String, Object?> filters = const {},
  ]) =>
      apiCall(() => client.list(query, filters: filters));

  Future<Result<T>> get(int id) => apiCall(() => client.get(id));

  /// Returns the new record id.
  Future<Result<int>> add(T entity) =>
      apiCall(() => client.add(_createBody(entity)));

  Future<Result<void>> edit(T entity) =>
      apiCall(() => client.edit(_idOf(entity), _updateBody(entity)));

  Future<Result<void>> remove(int id) => apiCall(() => client.remove(id));
}
