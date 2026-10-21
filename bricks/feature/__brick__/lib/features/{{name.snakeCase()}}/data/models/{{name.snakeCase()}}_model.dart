import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/{{name.snakeCase()}}.dart';

part '{{name.snakeCase()}}_model.freezed.dart';
part '{{name.snakeCase()}}_model.g.dart';

@freezed
abstract class {{name.pascalCase()}}Model with _${{name.pascalCase()}}Model {
  const {{name.pascalCase()}}Model._();

  const factory {{name.pascalCase()}}Model({
    required int id,
    required String title,
    String? createdByName,
    DateTime? createdAt,
    Object? rowVersion,
  }) = _{{name.pascalCase()}}Model;

  factory {{name.pascalCase()}}Model.fromJson(Map<String, dynamic> json) =>
      _${{name.pascalCase()}}ModelFromJson(json);

  factory {{name.pascalCase()}}Model.fromEntity({{name.pascalCase()}} entity) =>
      {{name.pascalCase()}}Model(
        id: entity.id,
        title: entity.title,
        createdByName: entity.createdByName,
        createdAt: entity.createdAt,
        rowVersion: entity.rowVersion,
      );

  {{name.pascalCase()}} toEntity() => {{name.pascalCase()}}(
        id: id,
        title: title,
        createdByName: createdByName,
        createdAt: createdAt,
        rowVersion: rowVersion,
      );

  /// Request body of create: only fields the client may send. Server-owned
  /// fields (createdBy, createdAt, ...) are never in the DTO.
  Map<String, dynamic> toCreateJson() => {'title': title};

  /// Request body of edit: includes the id and `rowVersion` for concurrency.
  Map<String, dynamic> toUpdateJson() => {
        'id': id,
        'title': title,
        if (rowVersion != null) 'rowVersion': rowVersion,
      };
}
