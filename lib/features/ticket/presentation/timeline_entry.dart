import 'package:material_ui/material_ui.dart';

import '../../../core/api/generated/nex_desk_api.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../shared/mentions.dart';
import '../../../shared/ticket_badges.dart';
import '../../../shared/time_text.dart';
import '../../attachments/presentation/attachment_chip.dart';

String actorName(ActorDto actor, AppLocalizations l10n) =>
    actor.name ??
    switch (actor.type) {
      ActorTypeKnown(value: ActorTypeValue.customer) => l10n.actorCustomer,
      ActorTypeKnown(value: ActorTypeValue.system) => l10n.actorSystem,
      ActorTypeKnown(value: ActorTypeValue.apiKey) => l10n.actorApiKey,
      _ => l10n.actorStaff,
    };

/// A change on the ticket in words, with status, priority, type and SLA clock names translated as on the web.
String describeEvent(TimelineItem item, AppLocalizations l10n) {
  final actor = actorName(item.actor, l10n);
  final event = item.eventType;
  String value(String? raw) {
    if (raw == null || raw.isEmpty) return l10n.none;
    return switch (event) {
      TicketEventTypeKnown(value: TicketEventTypeValue.statusChanged) => statusLabel(
        TicketStatus.fromJson(raw),
        l10n,
      ),
      TicketEventTypeKnown(value: TicketEventTypeValue.priorityChanged) => priorityLabel(
        TicketPriority.fromJson(raw),
        l10n,
      ),
      TicketEventTypeKnown(value: TicketEventTypeValue.slaBreached) =>
        raw == 'FirstResponse' ? l10n.firstResponse : l10n.resolution,
      _ => raw,
    };
  }

  final from = value(item.oldValue);
  final to = value(item.newValue);
  return switch (event) {
    TicketEventTypeKnown(value: TicketEventTypeValue.created) => l10n.eventCreated(actor),
    TicketEventTypeKnown(value: TicketEventTypeValue.subjectChanged) => l10n.eventSubjectChanged(
      actor,
      from,
      to,
    ),
    TicketEventTypeKnown(value: TicketEventTypeValue.statusChanged) => l10n.eventStatusChanged(
      actor,
      from,
      to,
    ),
    TicketEventTypeKnown(value: TicketEventTypeValue.priorityChanged) => l10n.eventPriorityChanged(
      actor,
      from,
      to,
    ),
    TicketEventTypeKnown(value: TicketEventTypeValue.typeChanged) => l10n.eventTypeChanged(actor, from, to),
    TicketEventTypeKnown(value: TicketEventTypeValue.assigneeChanged) => l10n.eventAssigneeChanged(
      actor,
      from,
      to,
    ),
    TicketEventTypeKnown(value: TicketEventTypeValue.teamChanged) => l10n.eventTeamChanged(actor, from, to),
    TicketEventTypeKnown(value: TicketEventTypeValue.tagsChanged) => l10n.eventTagsChanged(actor, from, to),
    TicketEventTypeKnown(value: TicketEventTypeValue.customFieldChanged) => l10n.eventCustomFieldChanged(
      actor,
      item.field ?? '',
      from,
      to,
    ),
    TicketEventTypeKnown(value: TicketEventTypeValue.mergedInto) => l10n.eventMergedInto(actor, to),
    TicketEventTypeKnown(value: TicketEventTypeValue.mergedFrom) => l10n.eventMergedFrom(actor, to),
    TicketEventTypeKnown(value: TicketEventTypeValue.slaBreached) => l10n.eventSlaBreached(to),
    TicketEventTypeKnown(value: TicketEventTypeValue.csatSubmitted) => l10n.eventCsatSubmitted(actor, to),
    _ => l10n.eventOther(actor),
  };
}

class TimelineEntry extends StatelessWidget {
  const TimelineEntry({required this.item, required this.now, required this.mentionable, super.key});

  final TimelineItem item;
  final DateTime now;

  /// Names of the team, so "@Full Name" in a message is highlighted.
  final List<String> mentionable;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final when = timeAgo(item.createdAt, now, l10n);

    if (item.kind case TimelineKindKnown(value: TimelineKindValue.event)) {
      return Padding(
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: [
            Icon(Icons.history, size: 16, color: scheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                describeEvent(item, l10n),
                style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
            Text(when, style: theme.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
          ],
        ),
      );
    }

    final staff = item.actor.type == ActorType.staff;
    final (background, foreground) = item.isInternal
        ? (scheme.tertiaryContainer, scheme.onTertiaryContainer)
        : staff
        ? (scheme.surfaceContainerHigh, scheme.onSurface)
        : (scheme.surfaceContainerLowest, scheme.onSurface);

    return Container(
      key: Key('message-${item.id}'),
      margin: const EdgeInsetsDirectional.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsetsDirectional.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: item.isInternal ? null : Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  actorName(item.actor, l10n),
                  style: theme.textTheme.titleSmall?.copyWith(color: foreground),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (item.isInternal) ...[
                const SizedBox(width: 8),
                Icon(Icons.lock_outline, size: 14, color: foreground),
                const SizedBox(width: 2),
                Text(l10n.internalNote, style: theme.textTheme.labelSmall?.copyWith(color: foreground)),
              ],
              const Spacer(),
              Text(when, style: theme.textTheme.labelSmall?.copyWith(color: foreground)),
            ],
          ),
          const SizedBox(height: 6),
          Text.rich(
            TextSpan(
              style: theme.textTheme.bodyMedium?.copyWith(color: foreground),
              children: [
                for (final part in splitMentions(item.body ?? '', mentionable))
                  TextSpan(
                    text: part.text,
                    style: part.mention
                        ? TextStyle(
                            fontWeight: FontWeight.w600,
                            color: item.isInternal ? foreground : scheme.primary,
                            backgroundColor: (item.isInternal ? foreground : scheme.primary).withValues(
                              alpha: 0.12,
                            ),
                          )
                        : null,
                  ),
              ],
            ),
          ),
          if (item.attachments.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [for (final file in item.attachments) AttachmentChip(file)],
            ),
          ],
        ],
      ),
    );
  }
}
