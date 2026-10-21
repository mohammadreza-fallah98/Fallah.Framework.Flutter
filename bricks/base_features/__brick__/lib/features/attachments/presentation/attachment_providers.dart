import 'dart:async';

import 'package:fallah_api/fallah_api.dart';
import 'package:fallah_core/fallah_core.dart';
import 'package:file_picker/file_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:{{project_name.snakeCase()}}/core/api/api_providers.dart';

part 'attachment_providers.g.dart';

/// Lets the user pick one or more files (empty list when cancelled). Read
/// the content with `PlatformFile.readAsBytes()`, which works on mobile and web.
Future<List<PlatformFile>> pickFiles() => FilePicker.pickFiles();

@riverpod
class AttachmentList extends _$AttachmentList {
  @override
  Future<PagedState<Attachment>> build() async =>
      PagedState(await _fetch(const PageQuery()));

  Future<PagedList<Attachment>> _fetch(PageQuery query) async =>
      (await ref.read(attachmentRepositoryProvider).list(query)).getOrThrow();

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || current.isLoadingMore || !current.hasMore) return;
    state = AsyncData(current.loadingMore());
    state = AsyncData(await nextPage(current, _fetch));
  }
}

/// Short-lived display / download URL of an attachment.
@riverpod
Future<String> attachmentUrl(Ref ref, int id) async =>
    (await ref.watch(attachmentRepositoryProvider).urlOf(id)).getOrThrow();

/// Upload / delete. `state.isLoading` drives progress indicators; methods
/// return the [Failure] or null on success.
@riverpod
class AttachmentActions extends _$AttachmentActions {
  @override
  FutureOr<void> build() {}

  Future<Failure?> upload(List<PlatformFile> files) async {
    state = const AsyncLoading();
    Failure? failure;
    for (final f in files) {
      final result = await ref.read(attachmentRepositoryProvider).upload(
            bytes: await f.readAsBytes(),
            filename: f.name,
          );
      failure = result.failureOrNull;
      if (failure != null) break;
    }
    state = const AsyncData(null);
    ref.invalidate(attachmentListProvider);
    return failure;
  }

  Future<Failure?> remove(int id) async {
    state = const AsyncLoading();
    final result = await ref.read(attachmentRepositoryProvider).remove(id);
    state = const AsyncData(null);
    ref.invalidate(attachmentListProvider);
    return result.failureOrNull;
  }
}
