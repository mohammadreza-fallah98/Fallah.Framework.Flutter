import 'package:dio/dio.dart';
import 'package:fallah_core/fallah_core.dart';
import 'package:fallah_network/fallah_network.dart';

import 'audit_info.dart';

/// Link between an attachment and a chat message
/// (`api/v1/attachment-chats`). Create / delete / read only.
class AttachmentChat {
  const AttachmentChat({
    required this.id,
    required this.attachmentId,
    required this.chatId,
    this.audit = AuditInfo.none,
  });

  factory AttachmentChat.fromJson(Map<String, dynamic> json) => AttachmentChat(
        id: asInt(json['id'])!,
        attachmentId: asInt(json['attachmentId']) ?? 0,
        chatId: asInt(json['chatId']) ?? 0,
        audit: AuditInfo.fromJson(json),
      );

  final int id;
  final int attachmentId;
  final int chatId;
  final AuditInfo audit;
}

class AttachmentChatRepository {
  AttachmentChatRepository(Dio dio)
      : _client = ResourceClient<AttachmentChat>(
          dio,
          'attachment-chats',
          AttachmentChat.fromJson,
        );

  final ResourceClient<AttachmentChat> _client;

  Future<Result<PagedList<AttachmentChat>>> list([
    PageQuery query = const PageQuery(),
    Map<String, Object?> filters = const {},
  ]) =>
      apiCall(() => _client.list(query, filters: filters));

  Future<Result<AttachmentChat>> get(int id) => apiCall(() => _client.get(id));

  /// A duplicate `(attachmentId, chatId)` fails with a ValidationFailure.
  Future<Result<int>> link({
    required int attachmentId,
    required int chatId,
  }) =>
      apiCall(
        () => _client.add({'attachmentId': attachmentId, 'chatId': chatId}),
      );

  Future<Result<void>> unlink(int id) => apiCall(() => _client.remove(id));
}
