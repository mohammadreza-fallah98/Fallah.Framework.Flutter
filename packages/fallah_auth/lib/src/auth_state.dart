enum AuthStatus {
  /// Session not restored yet (app start). Show a splash, don't redirect.
  unknown,
  authenticated,
  unauthenticated,
}

/// Immutable snapshot of the current session.
class AuthState {
  const AuthState(this.status, {this.permissions = const {}});

  const AuthState.unknown() : this(AuthStatus.unknown);
  const AuthState.unauthenticated() : this(AuthStatus.unauthenticated);

  final AuthStatus status;

  /// `entity:action` strings, e.g. `user:create`.
  final Set<String> permissions;

  bool get isAuthenticated => status == AuthStatus.authenticated;

  bool can(String permission) => permissions.contains(permission);
  bool canAny(Iterable<String> any) => any.any(permissions.contains);
  bool canAll(Iterable<String> all) => all.every(permissions.contains);
}
