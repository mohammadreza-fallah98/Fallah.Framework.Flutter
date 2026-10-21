import 'dart:convert';

import 'package:fallah_network/fallah_network.dart';

/// Minimal key/value contract so this package stays pure Dart. In the app,
/// adapt `FlutterSecureStorage`:
///
/// ```dart
/// class FlutterSecureKeyValue implements SecureKeyValue {
///   const FlutterSecureKeyValue(this._s);
///   final FlutterSecureStorage _s;
///   Future<String?> read(String k) => _s.read(key: k);
///   Future<void> write(String k, String v) => _s.write(key: k, value: v);
///   Future<void> delete(String k) => _s.delete(key: k);
/// }
/// ```
abstract interface class SecureKeyValue {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

/// [TokenStore] on top of a [SecureKeyValue]. Both tokens live under one key
/// (written atomically) and are cached in memory, so the interceptor does not
/// hit secure storage on every request.
class SecureTokenStore implements TokenStore {
  SecureTokenStore(this._storage);

  static const tokensKey = 'fallah.tokens';

  final SecureKeyValue _storage;
  AuthTokens? _cache;
  bool _loaded = false;

  @override
  Future<AuthTokens?> read() async {
    if (_loaded) return _cache;
    final raw = await _storage.read(tokensKey);
    _cache = _decode(raw);
    _loaded = true;
    return _cache;
  }

  @override
  Future<void> save(AuthTokens tokens) async {
    await _storage.write(
      tokensKey,
      jsonEncode({
        'accessToken': tokens.accessToken,
        'refreshToken': tokens.refreshToken,
      }),
    );
    _cache = tokens;
    _loaded = true;
  }

  @override
  Future<void> clear() async {
    _cache = null;
    _loaded = true;
    await _storage.delete(tokensKey);
  }

  AuthTokens? _decode(String? raw) {
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final access = map['accessToken'];
      final refresh = map['refreshToken'];
      if (access is String && refresh is String) {
        return AuthTokens(accessToken: access, refreshToken: refresh);
      }
    } on FormatException {
      // Corrupted value: treat as signed out.
    }
    return null;
  }
}
