import 'package:fallah_core/fallah_core.dart';

import '../entities/{{name.snakeCase()}}.dart';

abstract interface class {{name.pascalCase()}}Repository {
  Future<Result<PagedList<{{name.pascalCase()}}>>> getList(PageQuery query);
  Future<Result<{{name.pascalCase()}}>> getById(int id);
  Future<Result<int>> add({{name.pascalCase()}} {{name.camelCase()}});
  Future<Result<void>> edit({{name.pascalCase()}} {{name.camelCase()}});
  Future<Result<void>> remove(int id);
}
