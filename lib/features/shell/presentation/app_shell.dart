import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/realtime/live_hub.dart';
import '../../../core/realtime/realtime_controller.dart';
import '../../notifications/application/notifications_controller.dart';
import '../../notifications/presentation/notification_text.dart';

/// Bottom navigation on phones; a navigation rail from 840 dp. While it is on screen the live connection
/// follows the app's lifecycle, the Notifications tab carries the unread badge, and a notification that
/// arrives shows as a banner with a way to open its ticket.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({required this.shell, super.key});

  final StatefulNavigationShell shell;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  late final AppLifecycleListener _lifecycle;
  StreamSubscription<LiveEvent>? _events;

  static const _notificationsBranch = 1;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () => ref.read(realtimeProvider.notifier).appResumed(),
      onPause: () => ref.read(realtimeProvider.notifier).appPaused(),
    );
    _events = ref.read(liveEventsProvider).listen(_onEvent);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    unawaited(_events?.cancel());
    super.dispose();
  }

  void _onEvent(LiveEvent event) {
    if (event is! NotificationArrived || !mounted) return;
    if (widget.shell.currentIndex == _notificationsBranch) return;
    final l10n = AppLocalizations.of(context);
    final n = event.notification;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          key: const Key('notification-banner'),
          content: Text(notificationText(n, l10n)),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: l10n.open,
            onPressed: () {
              unawaited(ref.read(notificationsProvider.notifier).markRead(n));
              context.go('${Routes.inbox}/${n.ticketId}');
            },
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(realtimeProvider);
    final unread = ref.watch(notificationsProvider.select((s) => s.unread));
    final l10n = AppLocalizations.of(context);
    final shell = widget.shell;

    Widget bell(IconData icon) => Semantics(
      label: unread > 0 ? l10n.notificationsUnread(unread) : null,
      child: Badge(
        key: const Key('unread-badge'),
        isLabelVisible: unread > 0,
        label: Text(unread > 99 ? '99+' : '$unread'),
        child: Icon(icon),
      ),
    );

    final destinations = [
      (const Icon(Icons.inbox_outlined), const Icon(Icons.inbox), l10n.inbox),
      (bell(Icons.notifications_outlined), bell(Icons.notifications), l10n.notifications),
      (const Icon(Icons.person_outline), const Icon(Icons.person), l10n.profile),
    ];
    void go(int index) => shell.goBranch(index, initialLocation: index == shell.currentIndex);

    if (MediaQuery.sizeOf(context).width >= 840) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: shell.currentIndex,
              onDestinationSelected: go,
              labelType: NavigationRailLabelType.all,
              destinations: [
                for (final (icon, selected, label) in destinations)
                  NavigationRailDestination(icon: icon, selectedIcon: selected, label: Text(label)),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: shell),
          ],
        ),
      );
    }

    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: go,
        destinations: [
          for (final (icon, selected, label) in destinations)
            NavigationDestination(icon: icon, selectedIcon: selected, label: label),
        ],
      ),
    );
  }
}
