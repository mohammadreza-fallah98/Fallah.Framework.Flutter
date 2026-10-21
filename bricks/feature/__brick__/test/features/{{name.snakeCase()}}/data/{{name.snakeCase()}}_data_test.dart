import 'package:dio/dio.dart';
import 'package:fallah_core/fallah_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:{{package.snakeCase()}}/features/{{name.snakeCase()}}/data/datasources/{{name.snakeCase()}}_remote_data_source.dart';
import 'package:{{package.snakeCase()}}/features/{{name.snakeCase()}}/data/models/{{name.snakeCase()}}_model.dart';
import 'package:{{package.snakeCase()}}/features/{{name.snakeCase()}}/data/repositories/{{name.snakeCase()}}_repository_impl.dart';

class _MockRemote extends Mock implements {{name.pascalCase()}}RemoteDataSource {}

void main() {
  late _MockRemote remote;
  late {{name.pascalCase()}}RepositoryImpl repository;

  setUpAll(() => registerFallbackValue(const PageQuery()));

  setUp(() {
    remote = _MockRemote();
    repository = {{name.pascalCase()}}RepositoryImpl(remote);
  });

  group('{{name.pascalCase()}}Model', () {
    test('fromJson -> toEntity', () {
      final entity = {{name.pascalCase()}}Model.fromJson({'id': 1, 'title': 'a'}).toEntity();
      expect(entity.id, 1);
      expect(entity.title, 'a');
    });
  });

  group('{{name.pascalCase()}}RepositoryImpl', () {
    test('getList maps models to entities', () async {
      when(() => remote.getList(any())).thenAnswer(
        (_) async => const PagedList(
          items: [{{name.pascalCase()}}Model(id: 1, title: 'a')],
          totalCount: 1,
          page: 1,
          pageSize: 20,
        ),
      );

      final result = await repository.getList(const PageQuery());

      expect(result.valueOrNull!.items.single.title, 'a');
    });

    test('getById maps a 404 to NotFoundFailure', () async {
      final options = RequestOptions(path: '/x');
      when(() => remote.getById(any())).thenThrow(
        DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          response: Response(requestOptions: options, statusCode: 404),
        ),
      );

      final result = await repository.getById(1);

      expect(result.failureOrNull, isA<NotFoundFailure>());
    });
  });
}
