import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/sign_in_screen.dart';
import '../features/shell/presentation/app_shell.dart';
import '../features/shell/presentation/placeholder_screen.dart';

/// The same paths as the web app, so a link from an email or a push opens the same place.
abstract final class Routes {
  static const signIn = '/login';
  static const inbox = '/app/tickets';
  static const notifications = '/app/notifications';
  static const profile = '/app/profile';
}

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: Routes.signIn,
    routes: [
      GoRoute(path: '/', redirect: (_, _) => Routes.signIn),
      GoRoute(path: Routes.signIn, builder: (_, _) => const SignInScreen()),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.inbox,
                builder: (_, _) => const PlaceholderScreen(section: Section.inbox),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.notifications,
                builder: (_, _) => const PlaceholderScreen(section: Section.notifications),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.profile,
                builder: (_, _) => const PlaceholderScreen(section: Section.profile),
              ),
            ],
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
