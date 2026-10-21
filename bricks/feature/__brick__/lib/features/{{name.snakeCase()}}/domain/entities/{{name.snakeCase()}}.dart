import 'package:freezed_annotation/freezed_annotation.dart';

part '{{name.snakeCase()}}.freezed.dart';

@freezed
abstract class {{name.pascalCase()}} with _${{name.pascalCase()}} {
  const factory {{name.pascalCase()}}({
    required int id,
    required String title,
    String? createdByName,
    DateTime? createdAt,

    /// Optimistic-concurrency token; sent back unchanged on edit (409 on
    /// conflict). Opaque to the client.
    Object? rowVersion,
  }) = _{{name.pascalCase()}};
}
