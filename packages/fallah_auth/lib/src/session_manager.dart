import 'dart:async';

import 'package:fallah_core/fallah_core.dart';
import 'package:fallah_network/fallah_network.dart';

import 'auth_state.dart';

/// Loads the user's `entity:action` permissions (e.g. `GET role-scopes/my-scopes`).
typedef PermissionsLoader = Future<Result<Set<String>>> Function();

/// Owns the current [AuthState]. Wire [expire] as `onSessionExpired` of
/// `createDio` and expose [changes] to the router (`refreshListenable`).
class SessionManager {
  SessionManager({
    required TokenStore tokenStore,
    PermissionsLoader? loadPermissions,
  })  : _tokenStore = tokenStore,
        _loadPermissions = loadPermissions;

  final TokenStore _tokenStore;
  final PermissionsLoader? _loadPermissions;
  final _controller = StreamController<AuthState>.broadcast();

  AuthState _state = const AuthState.unknown();

  AuthState get state => _state;
  Stream<AuthState> get changes => _controller.stream;

  /// Call once at startup. Never throws: an unreadable token store (known
  /// secure-storage corruption after reinstall) means "signed out".
  Future<void> restore() async {
    try {
      final tokens = await _tokenStore.read();
      if (tokens == null) return _emit(const AuthState.unauthenticated());
    } on Object {
      await _safeClear();
      return _emit(const AuthState.unauthenticated());
    }
    await _authenticate();
  }

  /// Persist a fresh token pair after login / OTP verification.
  Future<void> signIn(AuthTokens tokens) async {
    await _tokenStore.save(tokens);
    await _authenticate();
  }

  Future<void> signOut() async {
    await _safeClear();
    _emit(const AuthState.unauthenticated());
  }

  /// Refresh was rejected; tokens are already cleared by the interceptor.
  Future<void> expire() async => _emit(const AuthState.unauthenticated());

  /// Retry loading permissions, e.g. after connectivity returns when the first
  /// load failed offline. No-op unless signed in.
  Future<void> reloadPermissions() async {
    if (_state.isAuthenticated) await _authenticate();
  }

  Future<void> dispose() => _controller.close();

  Future<void> _authenticate() async {
    var permissions = <String>{};
    final loader = _loadPermissions;
    if (loader != null) {
      final result = await loader();
      switch (result) {
        case Success(:final value):
          permissions = value;
        case Error(:final failure):
          if (failure is UnauthorizedFailure) {
            await _safeClear();
            return _emit(const AuthState.unauthenticated());
          }
        // Other failures (offline, 5xx): keep the session, no permissions yet.
      }
    }
    _emit(AuthState(AuthStatus.authenticated, permissions: permissions));
  }

  Future<void> _safeClear() async {
    try {
      await _tokenStore.clear();
    } on Object {
      // Nothing more can be done; the state still becomes unauthenticated.
    }
  }

  void _emit(AuthState next) {
    _state = next;
    if (!_controller.isClosed) _controller.add(next);
  }
}
