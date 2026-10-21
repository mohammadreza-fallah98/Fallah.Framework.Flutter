import 'dart:async';

import 'package:fallah_core/fallah_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:{{package.snakeCase()}}/core/network/dio_provider.dart';

import '../../data/datasources/{{name.snakeCase()}}_remote_data_source.dart';
import '../../data/repositories/{{name.snakeCase()}}_repository_impl.dart';
import '../../domain/entities/{{name.snakeCase()}}.dart';
import '../../domain/repositories/{{name.snakeCase()}}_repository.dart';
import '../../domain/usecases/add_{{name.snakeCase()}}.dart';
import '../../domain/usecases/edit_{{name.snakeCase()}}.dart';
import '../../domain/usecases/get_{{name.snakeCase()}}.dart';
import '../../domain/usecases/get_{{plural.snakeCase()}}.dart';
import '../../domain/usecases/remove_{{name.snakeCase()}}.dart';

part '{{name.snakeCase()}}_providers.g.dart';

@riverpod
{{name.pascalCase()}}RemoteDataSource {{name.camelCase()}}RemoteDataSource(Ref ref) =>
    {{name.pascalCase()}}RemoteDataSource(ref.watch(dioProvider));

@riverpod
{{name.pascalCase()}}Repository {{name.camelCase()}}Repository(Ref ref) =>
    {{name.pascalCase()}}RepositoryImpl(ref.watch({{name.camelCase()}}RemoteDataSourceProvider));

@riverpod
Get{{plural.pascalCase()}} get{{plural.pascalCase()}}(Ref ref) =>
    Get{{plural.pascalCase()}}(ref.watch({{name.camelCase()}}RepositoryProvider));

@riverpod
Get{{name.pascalCase()}} get{{name.pascalCase()}}(Ref ref) =>
    Get{{name.pascalCase()}}(ref.watch({{name.camelCase()}}RepositoryProvider));

@riverpod
Add{{name.pascalCase()}} add{{name.pascalCase()}}(Ref ref) =>
    Add{{name.pascalCase()}}(ref.watch({{name.camelCase()}}RepositoryProvider));

@riverpod
Edit{{name.pascalCase()}} edit{{name.pascalCase()}}(Ref ref) =>
    Edit{{name.pascalCase()}}(ref.watch({{name.camelCase()}}RepositoryProvider));

@riverpod
Remove{{name.pascalCase()}} remove{{name.pascalCase()}}(Ref ref) =>
    Remove{{name.pascalCase()}}(ref.watch({{name.camelCase()}}RepositoryProvider));

/// Unwraps a [Result] for AsyncValue-based providers: the UI receives the
/// [Failure] as the error object.
T _unwrap<T>(Result<T> result) => switch (result) {
      Success(:final value) => value,
      Error(:final failure) => throw failure,
    };

/// Accumulated pages of the list plus the load-more flag.
class {{name.pascalCase()}}ListState {
  const {{name.pascalCase()}}ListState({required this.page, this.isLoadingMore = false});

  final PagedList<{{name.pascalCase()}}> page;
  final bool isLoadingMore;

  List<{{name.pascalCase()}}> get items => page.items;
  bool get hasMore => page.hasNext;
}

@riverpod
class {{name.pascalCase()}}List extends _${{name.pascalCase()}}List {
  @override
  Future<{{name.pascalCase()}}ListState> build() async =>
      {{name.pascalCase()}}ListState(page: await _fetch(const PageQuery()));

  Future<PagedList<{{name.pascalCase()}}>> _fetch(PageQuery query) async =>
      _unwrap(await ref.read(get{{plural.pascalCase()}}Provider).call(query));

  /// Appends the next page. A failed page keeps the current list; pull to
  /// refresh to retry.
  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || current.isLoadingMore || !current.hasMore) return;

    state = AsyncData({{name.pascalCase()}}ListState(page: current.page, isLoadingMore: true));
    try {
      final next = await _fetch(
        PageQuery(page: current.page.page + 1, pageSize: current.page.pageSize),
      );
      state = AsyncData(
        {{name.pascalCase()}}ListState(
          page: PagedList(
            items: [...current.items, ...next.items],
            totalCount: next.totalCount,
            page: next.page,
            pageSize: next.pageSize,
          ),
        ),
      );
    } on Failure {
      state = AsyncData({{name.pascalCase()}}ListState(page: current.page));
    }
  }
}

@riverpod
Future<{{name.pascalCase()}}> {{name.camelCase()}}Detail(Ref ref, int id) async =>
    _unwrap(await ref.watch(get{{name.pascalCase()}}Provider).call(id));

/// Create / edit / delete. `state.isLoading` drives the disabled submit
/// button. Each method returns the [Failure] (or null on success); on success
/// the affected providers are invalidated.
@riverpod
class {{name.pascalCase()}}Mutation extends _${{name.pascalCase()}}Mutation {
  @override
  FutureOr<void> build() {}

  Future<Failure?> save({{name.pascalCase()}} {{name.camelCase()}}, {required bool isNew}) async {
    state = const AsyncLoading();
    final Result<Object?> result = isNew
        ? await ref.read(add{{name.pascalCase()}}Provider).call({{name.camelCase()}})
        : await ref.read(edit{{name.pascalCase()}}Provider).call({{name.camelCase()}});
    state = const AsyncData(null);

    return result.fold<Failure?>(
      (_) {
        ref.invalidate({{name.camelCase()}}ListProvider);
        if (!isNew) ref.invalidate({{name.camelCase()}}DetailProvider({{name.camelCase()}}.id));
        return null;
      },
      (failure) => failure,
    );
  }

  Future<Failure?> remove(int id) async {
    state = const AsyncLoading();
    final result = await ref.read(remove{{name.pascalCase()}}Provider).call(id);
    state = const AsyncData(null);

    return result.fold<Failure?>(
      (_) {
        ref.invalidate({{name.camelCase()}}ListProvider);
        return null;
      },
      (failure) => failure,
    );
  }
}
