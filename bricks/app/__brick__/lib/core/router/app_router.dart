import 'dart:async';

import 'package:fallah_auth/fallah_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:{{project_name.snakeCase()}}/core/auth/auth_providers.dart';
import 'package:{{project_name.snakeCase()}}/core/router/app_routes.dart';
import 'package:{{project_name.snakeCase()}}/features/auth/presentation/screens/login_screen.dart';
import 'package:{{project_name.snakeCase()}}/features/auth/presentation/screens/splash_screen.dart';
import 'package:{{project_name.snakeCase()}}/features/home/presentation/screens/home_screen.dart';
// fallah:imports

part 'app_router.g.dart';

/// Re-runs the router `redirect` whenever the session changes.
class _SessionRefresh extends ChangeNotifier {
  _SessionRefresh(Stream<AuthState> changes) {
    _subscription = changes.listen((_) => notifyListeners());
  }

  late final StreamSubscription<AuthState> _subscription;

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}

@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  final session = ref.watch(sessionManagerProvider);
  final refresh = _SessionRefresh(session.changes);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refresh,
    redirect: (context, state) => authRedirect(
      status: session.state.status,
      location: state.matchedLocation,
      loginPath: AppRoutes.login,
      homePath: AppRoutes.home,
      splashPath: AppRoutes.splash,
    ),
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      // fallah:routes
    ],
  );
}
