import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/auth/session_controller.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../shared/time_text.dart';
import '../application/inbox_controller.dart';
import '../data/inbox_query.dart';
import 'ticket_tile.dart';

/// Ticks once a minute so countdowns and "5 minutes ago" stay true while the list is open.
final minuteProvider = StreamProvider<DateTime>((ref) {
  final clock = ref.watch(clockProvider);
  final controller = StreamController<DateTime>();
  controller.add(clock());
  final timer = Timer.periodic(const Duration(minutes: 1), (_) => controller.add(clock()));
  ref.onDispose(() {
    timer.cancel();
    unawaited(controller.close());
  });
  return controller.stream;
});

class TicketList extends ConsumerWidget {
  const TicketList({required this.query, required this.onOpen, this.selectedId, this.emptyText, super.key});

  final InboxQuery query;
  final void Function(String ticketId) onOpen;
  final String? selectedId;
  final String? emptyText;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(inboxProvider(query));
    final controller = ref.read(inboxProvider(query).notifier);
    final now = ref.watch(minuteProvider).value ?? ref.read(clockProvider)();

    if (state.loading) return const Center(child: CircularProgressIndicator());

    if (state.items.isEmpty && state.error != null) {
      return _Message(
        icon: state.error!.isNetwork ? Icons.cloud_off : Icons.error_outline,
        text: messageFor(state.error!, l10n),
        action: FilledButton.tonal(onPressed: controller.refresh, child: Text(l10n.retry)),
      );
    }

    return RefreshIndicator.adaptive(
      onRefresh: controller.refresh,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.extentAfter < 400) unawaited(controller.loadMore());
          return false;
        },
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: state.items.length + 2,
          separatorBuilder: (_, index) =>
              index == 0 ? const SizedBox.shrink() : const Divider(height: 1, indent: 16),
          itemBuilder: (context, index) {
            if (index == 0) {
              return state.offline
                  ? _OfflineBanner(text: l10n.offlineSince(timeAgo(state.cachedAt ?? now, now, l10n)))
                  : const SizedBox.shrink();
            }
            if (index == state.items.length + 1) {
              if (state.items.isEmpty) {
                return _Message(icon: Icons.inbox_outlined, text: emptyText ?? l10n.emptyList);
              }
              return state.hasMore
                  ? const Padding(
                      padding: EdgeInsetsDirectional.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : const SizedBox(height: 24);
            }
            final ticket = state.items[index - 1];
            return TicketTile(
              ticket: ticket,
              now: now,
              selected: ticket.id == selectedId,
              onTap: () => onOpen(ticket.id),
            );
          },
        ),
      ),
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Container(
        key: const Key('offline-banner'),
        color: scheme.secondaryContainer,
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(Icons.cloud_off, size: 18, color: scheme.onSecondaryContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(text, style: TextStyle(color: scheme.onSecondaryContainer)),
            ),
          ],
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text, this.action});

  final IconData icon;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.symmetric(horizontal: 32, vertical: 64),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(height: 12),
        Text(text, textAlign: TextAlign.center),
        if (action != null) ...[const SizedBox(height: 16), action!],
      ],
    ),
  );
}
