import 'package:fallah_core/fallah_core.dart';
import 'package:fallah_network/fallah_network.dart';

import 'attachment.dart';
import 'audit_info.dart';
import 'crud_repository.dart';

/// A chat message (`api/v1/chats`, scope `chat:*`). The sender is
/// `audit.createdBy`. `subject == 'support'` (no [subjectId]) is the support
/// queue when [receiverUserId] is null.
class Chat {
  const Chat({
    required this.id,
    required this.subject,
    required this.message,
    this.subjectId,
    this.receiverUserId,
    this.parentId,
    this.title,
    this.isSeen = false,
    this.seenAt,
    this.attachments = const [],
    this.audit = AuditInfo.none,
  });

  factory Chat.fromJson(Map<String, dynamic> json) => Chat(
        id: asInt(json['id'])!,
        subject: asString(json['subject']) ?? 'support',
        message: asString(json['message']) ?? '',
        subjectId: asInt(json['subjectId']),
        receiverUserId: asInt(json['receiverUserId']),
        parentId: asInt(json['parentId']),
        title: asString(json['title']),
        isSeen: asBool(json['isSeen']),
        seenAt: asDate(json['seenAt']),
        attachments: [
          if (json['attachments'] case final List<Object?> list)
            for (final a in list)
              if (a is Map<String, dynamic>) Attachment.fromJson(a),
        ],
        audit: AuditInfo.fromJson(json),
      );

  static const supportSubject = 'support';

  final int id;
  final String subject;
  final String message;
  final int? subjectId;
  final int? receiverUserId;
  final int? parentId;
  final String? title;
  final bool isSeen;
  final DateTime? seenAt;

  /// Filled by `GET chats/with-attachments`.
  final List<Attachment> attachments;
  final AuditInfo audit;

  Map<String, dynamic> toCreateJson() => {
        'subject': subject,
        'subjectId': subjectId,
        'receiverUserId': receiverUserId,
        'parentId': parentId,
        'title': title,
        'message': message,
      };

  /// Editing is allowed only for the sender and only before it is seen.
  Map<String, dynamic> toUpdateJson() => {
        'id': id,
        'title': title,
        'message': message,
        if (audit.rowVersion != null) 'rowVersion': audit.rowVersion,
      };
}

class ChatRepository extends CrudRepository<Chat> {
  ChatRepository(super.dio)
      : super(
          path: 'chats',
          fromJson: Chat.fromJson,
          createBody: (e) => e.toCreateJson(),
          updateBody: (e) => e.toUpdateJson(),
          idOf: (e) => e.id,
        );

  /// Messages of one thread / subject, newest handling is up to the caller.
  Future<Result<PagedList<Chat>>> bySubject(
    String subject, {
    int? subjectId,
    int? receiverUserId,
    PageQuery query = const PageQuery(),
  }) =>
      list(query, {
        'Subject': subject,
        'SubjectId': subjectId,
        'ReceiverUserId': receiverUserId,
      });

  /// Same as [bySubject] but each message carries its attachments.
  Future<Result<PagedList<Chat>>> withAttachments(
    String subject, {
    int? subjectId,
    int? receiverUserId,
    PageQuery query = const PageQuery(),
  }) =>
      apiCall(
        () => client.list(
          query,
          subPath: 'with-attachments',
          filters: {
            'Subject': subject,
            'SubjectId': subjectId,
            'ReceiverUserId': receiverUserId,
          },
        ),
      );

  Future<Result<void>> markSeen(int id) =>
      apiCall(() => client.action('PATCH', '$id/seen'));
}
