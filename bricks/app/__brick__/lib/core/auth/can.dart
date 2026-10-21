import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:{{project_name.snakeCase()}}/core/auth/auth_providers.dart';

extension CanRef on WidgetRef {
  /// Whether the signed-in user holds `permission` (`entity:action`, e.g.
  /// `user:create`). Rebuilds the widget when the session changes. Use it to
  /// hide write controls the user may not use.
  bool can(String permission) =>
      watch(authStateProvider).value?.can(permission) ?? false;
}
