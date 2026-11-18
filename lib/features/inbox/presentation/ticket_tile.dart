import 'package:material_ui/material_ui.dart';

import '../../../core/api/generated/nex_desk_api.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../shared/ticket_badges.dart';
import '../../../shared/time_text.dart';
import '../data/inbox_query.dart';

class TicketTile extends StatelessWidget {
  const TicketTile({
    required this.ticket,
    required this.now,
    required this.onTap,
    this.selected = false,
    super.key,
  });

  final TicketListItem ticket;
  final DateTime now;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return ListTile(
      key: Key('ticket-${ticket.number}'),
      selected: selected,
      onTap: onTap,
      isThreeLine: true,
      title: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '#${ticket.number}  ',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
            TextSpan(text: ticket.subject),
          ],
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Padding(
        padding: const EdgeInsetsDirectional.only(top: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${ticket.requester.name} · ${ticket.assignee?.name ?? l10n.unassignedPerson}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                StatusChip(ticket.status),
                PriorityMark(ticket.priority),
                // A solved or closed ticket has no deadline left to watch.
                if (unresolved.contains(ticket.status)) SlaChip(ticket.sla, now: now),
              ],
            ),
          ],
        ),
      ),
      trailing: Text(timeAgo(ticket.lastActivityAt, now, l10n), style: theme.textTheme.labelSmall),
    );
  }
}
