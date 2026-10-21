import 'package:dio/dio.dart';
import 'package:fallah_core/fallah_core.dart';
import 'package:fallah_network/fallah_network.dart';

import 'audit_info.dart';

/// Append-only change record (`api/v1/audit-logs`, scope `audit-log:read`,
/// Admin only). Not editable.
class AuditLog {
  const AuditLog({
    required this.id,
    required this.entityName,
    required this.action,
    this.entityId,
    this.before,
    this.after,
    this.userId,
    this.createdAt,
    this.correlationId,
  });

  factory AuditLog.fromJson(Map<String, dynamic> json) => AuditLog(
        id: asInt(json['id'])!,
        entityName: asString(json['entityName']) ?? '',
        action: asString(json['action']) ?? '',
        entityId: asInt(json['entityId']),
        before: asString(json['before']),
        after: asString(json['after']),
        userId: asInt(json['userId']),
        createdAt: asDate(json['createdAt']),
        correlationId: asString(json['correlationId']),
      );

  final int id;
  final String entityName;

  /// `Added`, `Modified` or `Deleted`.
  final String action;
  final int? entityId;

  /// JSON text; sensitive properties are masked by the server.
  final String? before;
  final String? after;
  final int? userId;
  final DateTime? createdAt;
  final String? correlationId;
}

class AuditLogRepository {
  AuditLogRepository(Dio dio)
      : _client =
            ResourceClient<AuditLog>(dio, 'audit-logs', AuditLog.fromJson);

  final ResourceClient<AuditLog> _client;

  Future<Result<PagedList<AuditLog>>> list({
    PageQuery query = const PageQuery(),
    String? entityName,
    int? entityId,
    int? userId,
    DateTime? from,
    DateTime? to,
  }) =>
      apiCall(
        () => _client.list(
          query,
          filters: {
            'EntityName': entityName,
            'EntityId': entityId,
            'UserId': userId,
            'From': from?.toUtc().toIso8601String(),
            'To': to?.toUtc().toIso8601String(),
          },
        ),
      );

  Future<Result<AuditLog>> get(int id) => apiCall(() => _client.get(id));
}
