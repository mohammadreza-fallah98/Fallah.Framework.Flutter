import 'package:fallah_core/fallah_core.dart';

import '../entities/{{name.snakeCase()}}.dart';
import '../repositories/{{name.snakeCase()}}_repository.dart';

class Get{{plural.pascalCase()}} {
  const Get{{plural.pascalCase()}}(this._repository);

  final {{name.pascalCase()}}Repository _repository;

  Future<Result<PagedList<{{name.pascalCase()}}>>> call(PageQuery query) =>
      _repository.getList(query);
}
