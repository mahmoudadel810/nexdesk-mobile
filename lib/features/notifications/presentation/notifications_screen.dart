import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../core/auth/session_controller.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../shared/time_text.dart';
import '../application/notifications_controller.dart';
import 'notification_text.dart';

/// The notification centre: newest first, unread ones in bold with a dot. Opening one marks it read.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(notificationsProvider);
    final controller = ref.read(notificationsProvider.notifier);
    final now = ref.read(clockProvider)();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notifications),
        actions: [
          TextButton(
            key: const Key('mark-all-read'),
            onPressed: state.unread == 0 ? null : controller.markAllRead,
            child: Text(l10n.markAllRead),
          ),
        ],
      ),
      body: Column(
        children: [
          if (state.error case final error?)
            MaterialBanner(
              content: Text(messageFor(error, l10n)),
              leading: const Icon(Icons.error_outline),
              actions: [TextButton(onPressed: controller.refresh, child: Text(l10n.retry))],
            ),
          Expanded(
            child: RefreshIndicator.adaptive(
              onRefresh: controller.refresh,
              child: state.loading && state.items.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : state.items.isEmpty
                  ? ListView(
                      children: [
                        Padding(
                          padding: const EdgeInsetsDirectional.all(48),
                          child: Text(l10n.notificationsEmpty, textAlign: TextAlign.center),
                        ),
                      ],
                    )
                  : NotificationListener<ScrollNotification>(
                      onNotification: (scroll) {
                        if (scroll.metrics.extentAfter < 400) controller.loadMore();
                        return false;
                      },
                      child: ListView.separated(
                        itemCount: state.items.length + (state.loadingMore ? 1 : 0),
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          if (index == state.items.length) {
                            return const Padding(
                              padding: EdgeInsetsDirectional.all(16),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          final n = state.items[index];
                          final showPreview =
                              n.preview != null && n.preview!.isNotEmpty && !isSlaNotification(n);
                          return ListTile(
                            key: Key('notification-${n.id}'),
                            leading: Icon(notificationIcon(n)),
                            title: Text(
                              notificationText(n, l10n),
                              style: n.isRead ? null : const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            subtitle: Text(
                              [if (showPreview) n.preview!, timeAgo(n.createdAt, now, l10n)].join('\n'),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            isThreeLine: showPreview,
                            trailing: n.isRead
                                ? null
                                : Icon(Icons.circle, size: 10, color: theme.colorScheme.primary),
                            onTap: () {
                              controller.markRead(n);
                              context.go('${Routes.inbox}/${n.ticketId}');
                            },
                          );
                        },
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
