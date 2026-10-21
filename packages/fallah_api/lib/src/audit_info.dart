/// Lenient JSON readers: a field of an unexpected type reads as null instead
/// of crashing the whole list.
int? asInt(Object? v) =>
    v is num ? v.toInt() : (v is String ? int.tryParse(v) : null);

String? asString(Object? v) => v is String ? v : null;

bool asBool(Object? v, {bool fallback = false}) => v is bool ? v : fallback;

DateTime? asDate(Object? v) => v is String ? DateTime.tryParse(v) : null;

/// Fields shared by every base entity (except AuditLog).
class AuditInfo {
  const AuditInfo({
    this.createdBy,
    this.createdByName,
    this.createdAt,
    this.updatedBy,
    this.updatedAt,
    this.rowVersion,
  });

  factory AuditInfo.fromJson(Map<String, dynamic> json) => AuditInfo(
        createdBy: asInt(json['createdBy']),
        createdByName: asString(json['createdByName']),
        createdAt: asDate(json['createdAt']),
        updatedBy: asInt(json['updatedBy']),
        updatedAt: asDate(json['updatedAt']),
        rowVersion: json['rowVersion'],
      );

  static const none = AuditInfo();

  final int? createdBy;
  final String? createdByName;
  final DateTime? createdAt;
  final int? updatedBy;
  final DateTime? updatedAt;

  /// Optimistic-concurrency token, opaque to the client: send it back
  /// unchanged on edit (HTTP 409 on conflict).
  final Object? rowVersion;
}
