import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:fallah_auth/fallah_auth.dart';

import 'package:{{project_name.snakeCase()}}/core/auth/auth_providers.dart';
import 'package:{{project_name.snakeCase()}}/core/router/app_routes.dart';
import 'package:{{project_name.snakeCase()}}/features/attachments/presentation/attachments_screen.dart';
import 'package:{{project_name.snakeCase()}}/features/audit_logs/presentation/audit_logs_screen.dart';
import 'package:{{project_name.snakeCase()}}/features/chat/presentation/support_screen.dart';
import 'package:{{project_name.snakeCase()}}/features/profile/presentation/profile_screen.dart';
import 'package:{{project_name.snakeCase()}}/features/regions/presentation/regions_screen.dart';
import 'package:{{project_name.snakeCase()}}/features/roles/presentation/role_scopes_screen.dart';
import 'package:{{project_name.snakeCase()}}/features/roles/presentation/roles_screen.dart';
import 'package:{{project_name.snakeCase()}}/features/users/presentation/screens/user_detail_screen.dart';
import 'package:{{project_name.snakeCase()}}/features/users/presentation/screens/user_form_screen.dart';
import 'package:{{project_name.snakeCase()}}/features/users/presentation/screens/user_list_screen.dart';

/// Paths of the base-entity screens. `userNew` must stay registered before
/// the `:id` route (see [baseFeatureRoutes]).
abstract final class BaseRoutes {
  static const profile = '/profile';
  static const users = '/users';
  static const userNew = '/users/new';
  static String user(int id) => '/users/$id';
  static String userEdit(int id) => '/users/$id/edit';
  static const regions = '/regions';
  static const roles = '/roles';
  static String roleScopes(int roleId) => '/roles/$roleId/scopes';
  static const auditLogs = '/audit-logs';
  static const support = '/support';
  static const attachments = '/attachments';
}

/// Sends users without `permission` to the home page.
GoRouterRedirect _guard(String permission) => (context, state) {
      final session =
          ProviderScope.containerOf(context).read(sessionManagerProvider).state;
      return permissionRedirect(
        state: session,
        permission: permission,
        fallbackPath: AppRoutes.home,
      );
    };

int _id(GoRouterState state, [String key = 'id']) =>
    int.parse(state.pathParameters[key]!);

/// Spread into `GoRouter.routes` (the brick's hook does this for you).
List<RouteBase> baseFeatureRoutes() => [
      GoRoute(
        path: BaseRoutes.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: BaseRoutes.users,
        redirect: _guard('user:read'),
        builder: (context, state) => const UserListScreen(),
      ),
      GoRoute(
        path: BaseRoutes.userNew,
        redirect: _guard('user:create'),
        builder: (context, state) => const UserFormScreen(),
      ),
      GoRoute(
        path: '/users/:id',
        redirect: _guard('user:read'),
        builder: (context, state) => UserDetailScreen(id: _id(state)),
      ),
      GoRoute(
        path: '/users/:id/edit',
        redirect: _guard('user:update'),
        builder: (context, state) => UserFormScreen(id: _id(state)),
      ),
      GoRoute(
        path: BaseRoutes.regions,
        redirect: _guard('province:read'),
        builder: (context, state) => const RegionsScreen(),
      ),
      GoRoute(
        path: BaseRoutes.roles,
        redirect: _guard('role:read'),
        builder: (context, state) => const RolesScreen(),
      ),
      GoRoute(
        path: '/roles/:id/scopes',
        redirect: _guard('role-scope:read'),
        builder: (context, state) => RoleScopesScreen(roleId: _id(state)),
      ),
      GoRoute(
        path: BaseRoutes.auditLogs,
        redirect: _guard('audit-log:read'),
        builder: (context, state) => const AuditLogsScreen(),
      ),
      GoRoute(
        path: BaseRoutes.support,
        redirect: _guard('chat:read'),
        builder: (context, state) => const SupportScreen(),
      ),
      GoRoute(
        path: BaseRoutes.attachments,
        redirect: _guard('attachment:read'),
        builder: (context, state) => const AttachmentsScreen(),
      ),
    ];
