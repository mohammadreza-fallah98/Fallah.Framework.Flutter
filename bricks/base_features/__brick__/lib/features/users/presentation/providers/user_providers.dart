import 'dart:async';

import 'package:fallah_api/fallah_api.dart';
import 'package:fallah_core/fallah_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:{{project_name.snakeCase()}}/core/api/api_providers.dart';

part 'user_providers.g.dart';

@riverpod
class UserList extends _$UserList {
  @override
  Future<PagedState<User>> build() async =>
      PagedState(await _fetch(const PageQuery()));

  Future<PagedList<User>> _fetch(PageQuery query) async =>
      (await ref.read(userRepositoryProvider).list(query)).getOrThrow();

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || current.isLoadingMore || !current.hasMore) return;
    state = AsyncData(current.loadingMore());
    state = AsyncData(await nextPage(current, _fetch));
  }
}

@riverpod
Future<User> userDetail(Ref ref, int id) async =>
    (await ref.watch(userRepositoryProvider).get(id)).getOrThrow();

/// Create / edit / delete / activate. `state.isLoading` drives disabled
/// buttons; every method returns the [Failure] or null on success.
@riverpod
class UserMutation extends _$UserMutation {
  @override
  FutureOr<void> build() {}

  Future<Failure?> save(User user, {String? password}) async {
    state = const AsyncLoading();
    final repo = ref.read(userRepositoryProvider);
    final Result<Object?> result = user.id == 0
        ? await repo.create(user, password: password ?? '')
        : await repo.edit(user);
    state = const AsyncData(null);
    return _done(result, user.id);
  }

  Future<Failure?> remove(int id) async {
    state = const AsyncLoading();
    final result = await ref.read(userRepositoryProvider).remove(id);
    state = const AsyncData(null);
    return _done(result, id);
  }

  Future<Failure?> setActive(int id, {required bool isActive}) async {
    state = const AsyncLoading();
    final result = await ref
        .read(userRepositoryProvider)
        .setActive(id, isActive: isActive);
    state = const AsyncData(null);
    return _done(result, id);
  }

  Failure? _done(Result<Object?> result, int id) => result.fold<Failure?>(
        (_) {
          ref
            ..invalidate(userListProvider)
            ..invalidate(userDetailProvider(id));
          return null;
        },
        (failure) => failure,
      );
}
