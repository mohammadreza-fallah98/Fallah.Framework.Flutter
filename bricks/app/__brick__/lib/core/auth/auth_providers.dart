import 'package:fallah_api/fallah_api.dart';
import 'package:fallah_auth/fallah_auth.dart';
import 'package:fallah_network/fallah_network.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:{{project_name.snakeCase()}}/core/network/dio_provider.dart';

part 'auth_providers.g.dart';

class _FlutterSecureKeyValue implements SecureKeyValue {
  const _FlutterSecureKeyValue(this._storage);

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

@Riverpod(keepAlive: true)
TokenStore tokenStore(Ref ref) => SecureTokenStore(
      const _FlutterSecureKeyValue(FlutterSecureStorage()),
    );

/// Sign-in / sign-out / profile calls of the backend.
@Riverpod(keepAlive: true)
AuthApi authApi(Ref ref) => AuthApi(ref.watch(dioProvider));

@Riverpod(keepAlive: true)
SessionManager sessionManager(Ref ref) {
  final manager = SessionManager(
    tokenStore: ref.watch(tokenStoreProvider),
    // Read lazily: the Dio itself depends on this session manager.
    loadPermissions: () => RoleScopeRepository(ref.read(dioProvider)).myScopes(),
  );
  ref.onDispose(manager.dispose);
  return manager;
}

/// Current auth state for widgets (`ref.watch(authStateProvider)`), e.g. to
/// hide write controls: `ref.can('user:create')` (see `can.dart`).
@Riverpod(keepAlive: true)
Stream<AuthState> authState(Ref ref) async* {
  final session = ref.watch(sessionManagerProvider);
  yield session.state;
  yield* session.changes;
}
