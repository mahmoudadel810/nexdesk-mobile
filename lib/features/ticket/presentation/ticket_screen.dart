import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/api/generated/nex_desk_api.dart';
import '../../../core/auth/session.dart';
import '../../../core/auth/session_controller.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../shared/ticket_badges.dart';
import '../../../shared/time_text.dart';
import '../../inbox/data/inbox_query.dart';
import '../../inbox/presentation/ticket_list.dart';
import '../application/ticket_controller.dart';
import 'actions_sheet.dart';
import 'composer.dart';
import 'timeline_entry.dart';

class TicketScreen extends ConsumerStatefulWidget {
  const TicketScreen({required this.ticketId, super.key});

  final String ticketId;

  @override
  ConsumerState<TicketScreen> createState() => _TicketScreenState();
}

class _TicketScreenState extends ConsumerState<TicketScreen> {
  final _scroll = ScrollController();

  String get ticketId => widget.ticketId;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// New entries arrive at the end of the timeline, so the person sees what they just sent.
  void _followNewEntries(TicketState? previous, TicketState next) {
    final before = previous?.view?.timeline.length;
    final after = next.view?.timeline.length;
    if (before == null || after == null || after <= before) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      unawaited(
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    ref.listen(ticketProvider(ticketId), _followNewEntries);
    final state = ref.watch(ticketProvider(ticketId));
    final controller = ref.read(ticketProvider(ticketId).notifier);
    final session = switch (ref.watch(sessionProvider)) {
      SignedIn(:final session) => session,
      _ => null,
    };
    final canReply = session?.can('tickets.reply') ?? false;
    final canEdit = session?.can('tickets.edit') ?? false;
    final now = ref.watch(minuteProvider).value ?? ref.read(clockProvider)();
    final ticket = state.ticket;

    if (ticket == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: state.loading
              ? const CircularProgressIndicator()
              : Padding(
                  padding: const EdgeInsetsDirectional.all(32),
                  child: Text(
                    state.error?.code == 'ticket-not-found'
                        ? l10n.noLongerAvailable
                        : messageFor(state.error!, l10n),
                    textAlign: TextAlign.center,
                  ),
                ),
        ),
      );
    }

    final people = ref.watch(peopleProvider).value ?? const <UserDto>[];
    final closed = ticket.status == TicketStatus.closed;

    return Scaffold(
      appBar: AppBar(
        title: Text('#${ticket.number}'),
        actions: [
          IconButton(
            key: const Key('watch'),
            tooltip: ticket.isWatching ? l10n.stopWatching : l10n.watch,
            icon: Icon(ticket.isWatching ? Icons.visibility : Icons.visibility_outlined),
            onPressed: state.busy ? null : controller.toggleWatching,
          ),
          if (canEdit)
            IconButton(
              key: const Key('ticket-actions'),
              tooltip: l10n.ticketActions,
              icon: const Icon(Icons.tune),
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                showDragHandle: true,
                isScrollControlled: true,
                builder: (_) => ActionsSheet(ticketId: ticketId),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          if (state.stale)
            MaterialBanner(
              key: const Key('stale-banner'),
              content: Text(l10n.staleTicket),
              leading: const Icon(Icons.sync_problem),
              actions: [
                TextButton(onPressed: controller.dismissStale, child: Text(l10n.dismiss)),
                TextButton(onPressed: controller.applyAgain, child: Text(l10n.applyAgain)),
              ],
            ),
          if (state.error case final error? when !state.stale)
            MaterialBanner(
              content: Text(messageFor(error, l10n)),
              leading: const Icon(Icons.error_outline),
              actions: [TextButton(onPressed: controller.refresh, child: Text(l10n.retry))],
            ),
          Expanded(
            child: RefreshIndicator.adaptive(
              onRefresh: controller.refresh,
              child: ListView(
                controller: _scroll,
                padding: const EdgeInsetsDirectional.only(bottom: 16),
                children: [
                  _Header(ticket: ticket, now: now),
                  const Divider(height: 1),
                  for (final item in state.view!.timeline)
                    TimelineEntry(item: item, now: now, mentionable: [for (final p in people) p.fullName]),
                ],
              ),
            ),
          ),
          if (canReply && !closed)
            Composer(ticket: ticket)
          else
            Material(
              color: Theme.of(context).colorScheme.surfaceContainer,
              child: SafeArea(
                top: false,
                child: Padding(
                  key: const Key('read-only'),
                  padding: const EdgeInsetsDirectional.all(16),
                  child: Text(closed ? l10n.closedNotice : l10n.readOnly, textAlign: TextAlign.center),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.ticket, required this.now});

  final TicketDetailDto ticket;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final labels = ref.watch(fieldLabelsProvider).value ?? const <String, String>{};
    final open = unresolved.contains(ticket.status);

    Widget row(String label, String value, {Key? key}) => Padding(
      padding: const EdgeInsetsDirectional.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          Expanded(child: Text(value, key: key)),
        ],
      ),
    );

    String? clock(DateTime? due, bool met, bool breached) {
      if (met) return l10n.slaDone;
      if (due == null) return null;
      final left = due.difference(now);
      final time = shortDuration(left, l10n);
      return left.isNegative || breached ? l10n.slaOverdue(time) : l10n.slaDueIn(time);
    }

    final firstResponse = clock(
      ticket.sla.firstResponseDueAt,
      ticket.sla.firstResponseMet,
      ticket.sla.firstResponseBreached,
    );
    final resolution = clock(
      ticket.sla.resolutionDueAt,
      ticket.solvedAt != null,
      ticket.sla.resolutionBreached,
    );

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(ticket.subject, key: const Key('ticket-subject'), style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              StatusChip(ticket.status, key: const Key('ticket-status')),
              PriorityMark(ticket.priority),
              if (open) SlaChip(ticket.sla, now: now),
            ],
          ),
          const SizedBox(height: 12),
          row(l10n.requester, ticket.requester.name),
          row(
            l10n.assignee,
            ticket.assignee?.name ?? l10n.unassignedPerson,
            key: const Key('ticket-assignee'),
          ),
          if (ticket.team case final team?) row(l10n.team, team.name),
          if (ticket.tags.isNotEmpty) row(l10n.tags, ticket.tags.join(', ')),
          if (open && firstResponse != null) row(l10n.firstResponse, firstResponse),
          if (open && resolution != null) row(l10n.resolution, resolution),
          for (final entry in ticket.customFields.entries)
            if (entry.value.isNotEmpty) row(labels[entry.key] ?? entry.key, entry.value),
          if (ticket.watchers.isNotEmpty) row(l10n.watchers, ticket.watchers.map((w) => w.name).join(', ')),
        ],
      ),
    );
  }
}
