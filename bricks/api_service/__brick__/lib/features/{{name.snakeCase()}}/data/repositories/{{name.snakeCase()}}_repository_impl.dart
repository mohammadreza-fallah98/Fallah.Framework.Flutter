import 'package:fallah_core/fallah_core.dart';
import 'package:fallah_network/fallah_network.dart';

import '../../domain/entities/{{name.snakeCase()}}.dart';
import '../../domain/repositories/{{name.snakeCase()}}_repository.dart';
import '../datasources/{{name.snakeCase()}}_remote_data_source.dart';

class {{name.pascalCase()}}RepositoryImpl implements {{name.pascalCase()}}Repository {
  const {{name.pascalCase()}}RepositoryImpl(this._remote);

  final {{name.pascalCase()}}RemoteDataSource _remote;

  @override
  Future<Result<PagedList<{{name.pascalCase()}}>>> getList(PageQuery query) => apiCall(
        () async => (await _remote.getList(query)).map((m) => m.toEntity()),
      );

  @override
  Future<Result<{{name.pascalCase()}}>> getById(int id) =>
      apiCall(() async => (await _remote.getById(id)).toEntity());
}
