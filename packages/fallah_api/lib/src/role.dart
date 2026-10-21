import 'package:fallah_core/fallah_core.dart';
import 'package:fallah_network/fallah_network.dart';

import 'audit_info.dart';
import 'crud_repository.dart';

/// Role (`api/v1/roles`, scope `role:*`). `Admin` is always id 1.
class Role {
  const Role({
    required this.id,
    required this.name,
    this.description,
    this.audit = AuditInfo.none,
  });

  factory Role.fromJson(Map<String, dynamic> json) => Role(
        id: asInt(json['id'])!,
        name: asString(json['name']) ?? '',
        description: asString(json['description']),
        audit: AuditInfo.fromJson(json),
      );

  static const adminId = 1;

  final int id;
  final String name;
  final String? description;
  final AuditInfo audit;

  Map<String, dynamic> toCreateJson() =>
      {'name': name, 'description': description};

  Map<String, dynamic> toUpdateJson() => {
        'id': id,
        'name': name,
        'description': description,
        if (audit.rowVersion != null) 'rowVersion': audit.rowVersion,
      };
}

class RoleRepository extends CrudRepository<Role> {
  RoleRepository(super.dio)
      : super(
          path: 'roles',
          fromJson: Role.fromJson,
          createBody: (e) => e.toCreateJson(),
          updateBody: (e) => e.toUpdateJson(),
          idOf: (e) => e.id,
        );
}

/// Row visibility of a scope. Projects may append their own levels, so
/// [RoleScope.visibilityLevel] keeps the raw code.
enum VisibilityLevel {
  own(1),
  roles(2),
  assigned(3),
  all(4);

  const VisibilityLevel(this.code);
  final int code;

  static VisibilityLevel? fromCode(int? code) {
    for (final v in values) {
      if (v.code == code) return v;
    }
    return null;
  }
}

/// Permission of a role on one entity (`api/v1/role-scopes`).
/// The scope string is `<entityName>:<read|create|update|delete>`.
class RoleScope {
  const RoleScope({
    required this.id,
    required this.roleId,
    required this.entityName,
    this.canRead = false,
    this.canCreate = false,
    this.canUpdate = false,
    this.canDelete = false,
    this.visibilityLevel = 1,
    this.audit = AuditInfo.none,
  });

  factory RoleScope.fromJson(Map<String, dynamic> json) => RoleScope(
        id: asInt(json['id'])!,
        roleId: asInt(json['roleId']) ?? 0,
        entityName: asString(json['entityName']) ?? '',
        canRead: asBool(json['canRead']),
        canCreate: asBool(json['canCreate']),
        canUpdate: asBool(json['canUpdate']),
        canDelete: asBool(json['canDelete']),
        visibilityLevel: asInt(json['visibilityLevel']) ?? 1,
        audit: AuditInfo.fromJson(json),
      );

  final int id;
  final int roleId;
  final String entityName;
  final bool canRead;
  final bool canCreate;
  final bool canUpdate;
  final bool canDelete;
  final int visibilityLevel;
  final AuditInfo audit;

  VisibilityLevel? get visibility => VisibilityLevel.fromCode(visibilityLevel);

  Map<String, dynamic> _fields() => {
        'roleId': roleId,
        'entityName': entityName,
        'canRead': canRead,
        'canCreate': canCreate,
        'canUpdate': canUpdate,
        'canDelete': canDelete,
        'visibilityLevel': visibilityLevel,
      };

  Map<String, dynamic> toCreateJson() => _fields();

  Map<String, dynamic> toUpdateJson() => {
        'id': id,
        ..._fields(),
        if (audit.rowVersion != null) 'rowVersion': audit.rowVersion,
      };
}

class RoleScopeRepository extends CrudRepository<RoleScope> {
  RoleScopeRepository(super.dio)
      : super(
          path: 'role-scopes',
          fromJson: RoleScope.fromJson,
          createBody: (e) => e.toCreateJson(),
          updateBody: (e) => e.toUpdateJson(),
          idOf: (e) => e.id,
        );

  /// All scopes of one role (the roles matrix screen).
  Future<Result<PagedList<RoleScope>>> byRole(
    int roleId, [
    PageQuery query = const PageQuery(pageSize: 500),
  ]) =>
      apiCall(() => client.list(query, subPath: 'by-role/$roleId'));

  /// Scopes of the signed-in user, e.g. `{'user:read', 'user:create'}`
  /// (`['*']` for Admin). Feed the result to `SessionManager`.
  Future<Result<Set<String>>> myScopes() => apiCall(() async {
        final data = await client.action('GET', 'my-scopes');
        return {
          if (data is List) ...data.whereType<String>(),
        };
      });
}
