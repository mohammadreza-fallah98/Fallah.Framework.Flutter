import 'package:fallah_auth/fallah_auth.dart';
import 'package:fallah_core/fallah_core.dart';
import 'package:fallah_network/fallah_network.dart';
import 'package:test/test.dart';

class MemoryKv implements SecureKeyValue {
  final data = <String, String>{};
  @override
  Future<String?> read(String key) async => data[key];
  @override
  Future<void> write(String key, String value) async => data[key] = value;
  @override
  Future<void> delete(String key) async => data.remove(key);
}

class _ThrowingStore implements TokenStore {
  @override
  Future<AuthTokens?> read() async => throw StateError('keystore corrupted');
  @override
  Future<void> save(AuthTokens tokens) async {}
  @override
  Future<void> clear() async => throw StateError('keystore corrupted');
}

const tokens = AuthTokens(accessToken: 'a', refreshToken: 'r');

void main() {
  group('SecureTokenStore', () {
    test('round-trips and clears', () async {
      final store = SecureTokenStore(MemoryKv());
      expect(await store.read(), isNull);
      await store.save(tokens);
      expect((await store.read())!.refreshToken, 'r');
      await store.clear();
      expect(await store.read(), isNull);
    });
  });

  group('SecureTokenStore robustness', () {
    test('corrupted JSON reads as signed out', () async {
      final kv = MemoryKv()..data[SecureTokenStore.tokensKey] = '{not json';
      expect(await SecureTokenStore(kv).read(), isNull);
    });

    test('read is cached after first load', () async {
      final kv = MemoryKv();
      final store = SecureTokenStore(kv);
      await store.save(tokens);
      kv.data.clear();
      expect((await store.read())!.accessToken, 'a');
    });
  });

  group('SessionManager', () {
    test('restore survives an unreadable token store', () async {
      final s = SessionManager(tokenStore: _ThrowingStore());
      await s.restore();
      expect(s.state.status, AuthStatus.unauthenticated);
    });

    test('reloadPermissions fills permissions after an offline start',
        () async {
      var online = false;
      final s = SessionManager(
        tokenStore: SecureTokenStore(MemoryKv()),
        loadPermissions: () async => online
            ? const Result.success({'user:read'})
            : const Result.error(NetworkFailure('offline')),
      );
      await s.signIn(tokens);
      expect(s.state.can('user:read'), isFalse);
      online = true;
      await s.reloadPermissions();
      expect(s.state.can('user:read'), isTrue);
    });

    test('restore without tokens -> unauthenticated', () async {
      final s = SessionManager(tokenStore: SecureTokenStore(MemoryKv()));
      expect(s.state.status, AuthStatus.unknown);
      await s.restore();
      expect(s.state.status, AuthStatus.unauthenticated);
    });

    test('signIn loads permissions', () async {
      final s = SessionManager(
        tokenStore: SecureTokenStore(MemoryKv()),
        loadPermissions: () async => const Result.success({'user:create'}),
      );
      await s.signIn(tokens);
      expect(s.state.isAuthenticated, isTrue);
      expect(s.state.can('user:create'), isTrue);
      expect(s.state.can('user:delete'), isFalse);
    });

    test('offline permission load keeps session', () async {
      final s = SessionManager(
        tokenStore: SecureTokenStore(MemoryKv()),
        loadPermissions: () async =>
            const Result.error(NetworkFailure('offline')),
      );
      await s.signIn(tokens);
      expect(s.state.isAuthenticated, isTrue);
      expect(s.state.permissions, isEmpty);
    });

    test('401 on permission load clears session', () async {
      final kv = MemoryKv();
      final s = SessionManager(
        tokenStore: SecureTokenStore(kv),
        loadPermissions: () async => const Result.error(UnauthorizedFailure()),
      );
      await s.signIn(tokens);
      expect(s.state.status, AuthStatus.unauthenticated);
      expect(kv.data, isEmpty);
    });

    test('signOut and expire emit unauthenticated on stream', () async {
      final s = SessionManager(tokenStore: SecureTokenStore(MemoryKv()));
      await s.signIn(tokens);
      final emitted = expectLater(
        s.changes.map((e) => e.status),
        emitsInOrder([AuthStatus.unauthenticated, AuthStatus.unauthenticated]),
      );
      await s.signOut();
      await s.expire();
      await emitted;
    });
  });

  group('authRedirect', () {
    String? r(AuthStatus st, String loc, {Set<String> pub = const {}}) =>
        authRedirect(
          status: st,
          location: loc,
          loginPath: '/login',
          homePath: '/home',
          publicPaths: pub,
        );

    test('unknown never redirects without a splash', () {
      expect(r(AuthStatus.unknown, '/x'), isNull);
    });
    test('splash holds unknown and releases when resolved', () {
      String? s(AuthStatus st, String loc) => authRedirect(
            status: st,
            location: loc,
            loginPath: '/login',
            homePath: '/home',
            splashPath: '/splash',
          );
      expect(s(AuthStatus.unknown, '/users'), '/splash');
      expect(s(AuthStatus.unknown, '/splash'), isNull);
      expect(s(AuthStatus.authenticated, '/splash'), '/home');
      expect(s(AuthStatus.unauthenticated, '/splash'), '/login');
    });
    test('unauthenticated goes to login', () {
      expect(r(AuthStatus.unauthenticated, '/users'), '/login');
      expect(r(AuthStatus.unauthenticated, '/login'), isNull);
      expect(r(AuthStatus.unauthenticated, '/terms', pub: {'/terms'}), isNull);
    });
    test('authenticated leaves login', () {
      expect(r(AuthStatus.authenticated, '/login'), '/home');
      expect(r(AuthStatus.authenticated, '/users'), isNull);
    });
  });

  test('permissionRedirect', () {
    const st = AuthState(AuthStatus.authenticated, permissions: {'a:b'});
    expect(
      permissionRedirect(state: st, permission: 'a:b', fallbackPath: '/403'),
      isNull,
    );
    expect(
      permissionRedirect(state: st, permission: 'x:y', fallbackPath: '/403'),
      '/403',
    );
  });
}
