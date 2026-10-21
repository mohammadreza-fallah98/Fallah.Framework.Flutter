import 'package:dio/dio.dart';
import 'package:fallah_core/fallah_core.dart';
import 'package:fallah_network/fallah_network.dart';

import 'package:{{package.snakeCase()}}/core/network/endpoints.dart';

import '../models/{{name.snakeCase()}}_model.dart';

/// Talks to the backend and unwraps the envelope. Throws a [Failure] when the
/// envelope reports an error; Dio errors propagate and are mapped by the
/// repository.
class {{name.pascalCase()}}RemoteDataSource {
  const {{name.pascalCase()}}RemoteDataSource(this._dio);

  final Dio _dio;

  Future<PagedList<{{name.pascalCase()}}Model>> getList(PageQuery query) async {
    final response = await _dio.get<Map<String, dynamic>>(
      Endpoints.{{plural.camelCase()}},
      queryParameters: query.toQuery(),
    );
    return ApiListResponse.fromJson(
      response.data!,
      {{name.pascalCase()}}Model.fromJson,
    ).requireSuccess().toPagedList();
  }

  Future<{{name.pascalCase()}}Model> getById(int id) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '${Endpoints.{{plural.camelCase()}}}/$id',
    );
    return ApiResponse<{{name.pascalCase()}}Model>.fromJson(
      response.data!,
      (json) => {{name.pascalCase()}}Model.fromJson(json! as Map<String, dynamic>),
    ).requireData();
  }
}
