import 'package:fallah_core/fallah_core.dart';

import '../entities/{{name.snakeCase()}}.dart';
import '../repositories/{{name.snakeCase()}}_repository.dart';

class Edit{{name.pascalCase()}} {
  const Edit{{name.pascalCase()}}(this._repository);

  final {{name.pascalCase()}}Repository _repository;

  Future<Result<void>> call({{name.pascalCase()}} {{name.camelCase()}}) =>
      _repository.edit({{name.camelCase()}});
}
