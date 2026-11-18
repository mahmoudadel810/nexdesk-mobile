import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../core/auth/session.dart';
import '../core/auth/session_controller.dart';
import '../core/push/push_link.dart';
import '../features/auth/presentation/blocked_screen.dart';
import '../features/auth/presentation/sign_in_screen.dart';
import '../features/auth/presentation/splash_screen.dart';
import '../features/inbox/presentation/inbox_screen.dart';
import '../features/inbox/presentation/search_screen.dart';
import '../features/notifications/presentation/notification_settings_screen.dart';
import '../features/notifications/presentation/notifications_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/shell/presentation/app_shell.dart';
import '../features/ticket/presentation/ticket_screen.dart';
import 'config.dart';

/// The same paths as the web app, so a link from an email or a push opens the same place.
abstract final class Routes {
  static const splash = '/';
  static const signIn = '/login';
  static const blocked = '/blocked';
  static const inbox = '/app/tickets';
  static const notifications = '/app/notifications';
  static const profile = '/app/profile';
  static const notificationSettings = '/app/profile/notifications';
  static const simulatePush = '/simulate-push';
}

/// Where the session state says the app must be, or null to stay. A link that arrives while signed out is
/// kept in `from` and opened after sign-in.
String? redirectFor(SessionState state, Uri location) {
  final path = location.path;
  // A link from outside arrives whole (`https://<web host>/app/tickets/…`, `nexdesk://open/app/…`); only the
  // part inside the app is kept.
  final inApp = Uri(path: path, query: location.hasQuery ? location.query : null).toString();
  return switch (state) {
    SessionLoading() when path.startsWith('/app/') => Uri(
      path: Routes.splash,
      queryParameters: {'from': inApp},
    ).toString(),
    SessionLoading() => path == Routes.splash ? null : Routes.splash,
    // Still starting with a link in hand: carry it on to sign-in, or straight to it once signed in.
    SignedOut() when path == Routes.splash && _safe(location.queryParameters['from']) != null => Uri(
      path: Routes.signIn,
      queryParameters: {'from': location.queryParameters['from']},
    ).toString(),
    SignedIn() when path == Routes.splash => _safe(location.queryParameters['from']) ?? Routes.inbox,
    Blocked() => path == Routes.blocked ? null : Routes.blocked,
    SignedOut() when path == Routes.signIn => null,
    SignedOut() when path.startsWith('/app/') => Uri(
      path: Routes.signIn,
      queryParameters: {'from': inApp},
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
    redirect: (_, state) {
      // Development builds only: `nexdesk://open/simulate-push?type=…&ticketId=…` goes through the same parsing
      // as tapping a real push, so the Maestro flows can exercise it without Firebase.
      if (state.uri.path == Routes.simulatePush) {
        return ref.read(appConfigProvider).flavor == Flavor.dev
            ? pushLink(state.uri.queryParameters) ?? Routes.inbox
            : Routes.inbox;
      }
      return redirectFor(ref.read(sessionProvider), state.uri);
    },
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
            routes: [GoRoute(path: Routes.notifications, builder: (_, _) => const NotificationsScreen())],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.profile,
                builder: (_, _) => const ProfileScreen(),
                routes: [
                  GoRoute(path: 'notifications', builder: (_, _) => const NotificationSettingsScreen()),
                ],
              ),
            ],
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
