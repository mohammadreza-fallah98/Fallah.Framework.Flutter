import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:{{package.snakeCase()}}/core/auth/auth_providers.dart';
import 'package:{{package.snakeCase()}}/core/router/app_routes.dart';
import 'package:fallah_auth/fallah_auth.dart';

import 'screens/{{name.snakeCase()}}_detail_screen.dart';
import 'screens/{{name.snakeCase()}}_form_screen.dart';
import 'screens/{{name.snakeCase()}}_list_screen.dart';

/// Paths of this feature. `create` must stay registered before `detail`
/// (`/new` would otherwise match `:id`).
abstract final class {{name.pascalCase()}}Routes {
  static const list = '/{{plural.paramCase()}}';
  static const create = '/{{plural.paramCase()}}/new';
  static String detail(int id) => '/{{plural.paramCase()}}/$id';
  static String edit(int id) => '/{{plural.paramCase()}}/$id/edit';
}

/// Sends users without `permission` to the home page.
GoRouterRedirect _guard(String permission) => (context, state) {
      final session = ProviderScope.containerOf(context)
          .read(sessionManagerProvider)
          .state;
      return permissionRedirect(
        state: session,
        permission: permission,
        fallbackPath: AppRoutes.home,
      );
    };

/// Spread into `GoRouter.routes` (the generator does this for you).
List<RouteBase> {{name.camelCase()}}Routes() => [
      GoRoute(
        path: {{name.pascalCase()}}Routes.list,
        redirect: _guard('{{name.paramCase()}}:read'),
        builder: (context, state) => const {{name.pascalCase()}}ListScreen(),
      ),
      GoRoute(
        path: {{name.pascalCase()}}Routes.create,
        redirect: _guard('{{name.paramCase()}}:create'),
        builder: (context, state) => const {{name.pascalCase()}}FormScreen(),
      ),
      GoRoute(
        path: '/{{plural.paramCase()}}/:id',
        redirect: _guard('{{name.paramCase()}}:read'),
        builder: (context, state) => {{name.pascalCase()}}DetailScreen(
          id: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/{{plural.paramCase()}}/:id/edit',
        redirect: _guard('{{name.paramCase()}}:update'),
        builder: (context, state) => {{name.pascalCase()}}FormScreen(
          id: int.parse(state.pathParameters['id']!),
        ),
      ),
    ];
