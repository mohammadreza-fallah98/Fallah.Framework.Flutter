import 'package:fallah_core/fallah_core.dart';

import '../entities/{{name.snakeCase()}}.dart';
import '../repositories/{{name.snakeCase()}}_repository.dart';

class Add{{name.pascalCase()}} {
  const Add{{name.pascalCase()}}(this._repository);

  final {{name.pascalCase()}}Repository _repository;

  /// Returns the new record id.
  Future<Result<int>> call({{name.pascalCase()}} {{name.camelCase()}}) =>
      _repository.add({{name.camelCase()}});
}
