import 'package:fallah_core/fallah_core.dart';

import 'error_mapper.dart';

/// Wraps a datasource call so repositories never throw:
///
/// ```dart
/// Future<Result<User>> getUser(int id) =>
///     apiCall(() async => (await _remote.getUser(id)).toEntity());
/// ```
Future<Result<T>> apiCall<T>(Future<T> Function() action) =>
    Result.guard(action, onError: (e, _) => ErrorMapper.map(e));
