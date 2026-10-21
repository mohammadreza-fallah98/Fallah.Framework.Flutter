import 'package:fallah_api/fallah_api.dart';
import 'package:fallah_core/fallah_core.dart';
import 'package:file_picker/file_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:{{project_name.snakeCase()}}/core/api/api_providers.dart';

part 'chat_providers.g.dart';

/// Which conversation a thread shows: `support` (queue / own tickets) or the
/// name of a related entity plus its id (e.g. `order`, 17).
class ChatThreadKey {
  const ChatThreadKey({
    this.subject = Chat.supportSubject,
    this.subjectId,
    this.receiverUserId,
  });

  final String subject;
  final int? subjectId;
  final int? receiverUserId;

  @override
  bool operator ==(Object other) =>
      other is ChatThreadKey &&
      other.subject == subject &&
      other.subjectId == subjectId &&
      other.receiverUserId == receiverUserId;

  @override
  int get hashCode => Object.hash(subject, subjectId, receiverUserId);
}

/// Messages of one thread, newest first (the UI shows them bottom-up).
@riverpod
class ChatMessages extends _$ChatMessages {
  static const _newestFirst = PageQuery(
    pageSize: 30,
    sortBy: ['Id'],
    descending: true,
  );

  @override
  Future<PagedState<Chat>> build(ChatThreadKey thread) async =>
      PagedState(await _fetch(_newestFirst));

  Future<PagedList<Chat>> _fetch(PageQuery query) async =>
      (await ref.read(chatRepositoryProvider).withAttachments(
                thread.subject,
                subjectId: thread.subjectId,
                receiverUserId: thread.receiverUserId,
                query: query,
              ))
          .getOrThrow();

  /// Loads older messages.
  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || current.isLoadingMore || !current.hasMore) return;
    state = AsyncData(current.loadingMore());
    state = AsyncData(await nextPage(current, _fetch));
  }

  /// Uploads [files], posts the message and links the uploads to it. Returns
  /// the first [Failure] or null; reloads the thread either way.
  Future<Failure?> send(String text, List<PlatformFile> files) async {
    final failure = await _send(text, files);
    ref.invalidateSelf();
    return failure;
  }

  Future<Failure?> _send(String text, List<PlatformFile> files) async {
    final uploads = ref.read(attachmentRepositoryProvider);
    final attachmentIds = <int>[];
    for (final f in files) {
      final result = await uploads.upload(bytes: await f.readAsBytes(), filename: f.name);
      final failure = result.failureOrNull;
      if (failure != null) return failure;
      attachmentIds.add(result.valueOrNull!.attachmentId);
    }

    final created = await ref.read(chatRepositoryProvider).add(
          Chat(
            id: 0,
            subject: thread.subject,
            subjectId: thread.subjectId,
            receiverUserId: thread.receiverUserId,
            message: text,
          ),
        );
    final createFailure = created.failureOrNull;
    if (createFailure != null) return createFailure;

    final links = ref.read(attachmentChatRepositoryProvider);
    for (final attachmentId in attachmentIds) {
      final linked = await links.link(
        attachmentId: attachmentId,
        chatId: created.valueOrNull!,
      );
      final failure = linked.failureOrNull;
      if (failure != null) return failure;
    }
    return null;
  }

  /// Marks a received message as seen (fire and forget).
  Future<void> markSeen(int chatId) async {
    await ref.read(chatRepositoryProvider).markSeen(chatId);
  }
}
