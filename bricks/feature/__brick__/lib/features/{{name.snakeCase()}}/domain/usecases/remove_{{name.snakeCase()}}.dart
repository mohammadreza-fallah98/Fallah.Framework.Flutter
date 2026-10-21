import 'package:fallah_core/fallah_core.dart';

import '../repositories/{{name.snakeCase()}}_repository.dart';

class Remove{{name.pascalCase()}} {
  const Remove{{name.pascalCase()}}(this._repository);

  final {{name.pascalCase()}}Repository _repository;

  Future<Result<void>> call(int id) => _repository.remove(id);
}
