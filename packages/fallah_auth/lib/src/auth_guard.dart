import 'auth_state.dart';

/// Router-agnostic redirect rule. Returns the path to redirect to, or `null`
/// to stay. Use it inside go_router's `redirect`:
///
/// ```dart
/// redirect: (context, state) => authRedirect(
///   status: session.state.status,
///   location: state.matchedLocation,
///   loginPath: AppRoutes.login,
///   homePath: AppRoutes.home,
///   splashPath: AppRoutes.splash,
/// ),
/// ```
///
/// While the session is being restored ([AuthStatus.unknown]) the user is
/// held on [splashPath] (if given) and sent on once it resolves.
String? authRedirect({
  required AuthStatus status,
  required String location,
  required String loginPath,
  required String homePath,
  String? splashPath,
  Set<String> publicPaths = const {},
}) {
  switch (status) {
    case AuthStatus.unknown:
      return splashPath != null && location != splashPath ? splashPath : null;
    case AuthStatus.unauthenticated:
      final isPublic = location == loginPath || publicPaths.contains(location);
      return isPublic ? null : loginPath;
    case AuthStatus.authenticated:
      return location == loginPath || location == splashPath ? homePath : null;
  }
}

/// Permission gate for a route: returns [fallbackPath] when the user lacks
/// [permission], otherwise `null`.
String? permissionRedirect({
  required AuthState state,
  required String permission,
  required String fallbackPath,
}) =>
    state.can(permission) ? null : fallbackPath;
