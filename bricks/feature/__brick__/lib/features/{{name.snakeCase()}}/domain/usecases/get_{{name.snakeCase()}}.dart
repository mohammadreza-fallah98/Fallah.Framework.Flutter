import 'package:fallah_core/fallah_core.dart';

import '../entities/{{name.snakeCase()}}.dart';
import '../repositories/{{name.snakeCase()}}_repository.dart';

class Get{{name.pascalCase()}} {
  const Get{{name.pascalCase()}}(this._repository);

  final {{name.pascalCase()}}Repository _repository;

  Future<Result<{{name.pascalCase()}}>> call(int id) => _repository.getById(id);
}
