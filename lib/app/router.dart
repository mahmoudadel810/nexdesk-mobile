import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../core/auth/session.dart';
import '../core/auth/session_controller.dart';
import '../features/auth/presentation/blocked_screen.dart';
import '../features/auth/presentation/sign_in_screen.dart';
import '../features/auth/presentation/splash_screen.dart';
import '../features/inbox/presentation/inbox_screen.dart';
import '../features/inbox/presentation/search_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/shell/presentation/app_shell.dart';
import '../features/shell/presentation/placeholder_screen.dart';
import '../features/ticket/presentation/ticket_screen.dart';

/// The same paths as the web app, so a link from an email or a push opens the same place.
abstract final class Routes {
  static const splash = '/';
  static const signIn = '/login';
  static const blocked = '/blocked';
  static const inbox = '/app/tickets';
  static const notifications = '/app/notifications';
  static const profile = '/app/profile';
}

/// Where the session state says the app must be, or null to stay. A link that arrives while signed out is
/// kept in `from` and opened after sign-in.
String? redirectFor(SessionState state, Uri location) {
  final path = location.path;
  return switch (state) {
    SessionLoading() => path == Routes.splash ? null : Routes.splash,
    Blocked() => path == Routes.blocked ? null : Routes.blocked,
    SignedOut() when path == Routes.signIn => null,
    SignedOut() when path.startsWith('/app/') => Uri(
      path: Routes.signIn,
      queryParameters: {'from': '$location'},
    ).toString(),
    SignedOut() => Routes.signIn,
    SignedIn() when path == Routes.signIn => _safe(location.queryParameters['from']) ?? Routes.inbox,
    SignedIn() when path == Routes.splash || path == Routes.blocked => Routes.inbox,
    SignedIn() => null,
  };
}

/// Only links inside the app are followed after sign-in.
String? _safe(String? from) => from != null && from.startsWith('/app/') ? from : null;

final routerProvider = Provider<GoRouter>((ref) {
  final changes = ValueNotifier<SessionState>(ref.read(sessionProvider));
  ref.listen<SessionState>(sessionProvider, (_, next) => changes.value = next);

  final router = GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: changes,
    redirect: (_, state) => redirectFor(ref.read(sessionProvider), state.uri),
    routes: [
      GoRoute(path: Routes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(path: Routes.signIn, builder: (_, _) => const SignInScreen()),
      GoRoute(path: Routes.blocked, builder: (_, _) => const BlockedScreen()),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.inbox,
                builder: (_, _) => const InboxScreen(),
                routes: [
                  GoRoute(path: 'search', builder: (_, _) => const SearchScreen()),
                  GoRoute(
                    path: ':id',
                    builder: (_, state) => TicketScreen(ticketId: state.pathParameters['id']!),
                  ),
                ],
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
            routes: [GoRoute(path: Routes.profile, builder: (_, _) => const ProfileScreen())],
          ),
        ],
      ),
    ],
  );
  ref.onDispose(() {
    router.dispose();
    changes.dispose();
  });
  return router;
});
