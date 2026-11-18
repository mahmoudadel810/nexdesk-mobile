import 'package:material_ui/material_ui.dart';

import '../core/api/generated/nex_desk_api.dart';
import '../core/l10n/generated/app_localizations.dart';
import 'time_text.dart';

String statusLabel(TicketStatus status, AppLocalizations l10n) => switch (status) {
  TicketStatusKnown(value: TicketStatusValue.new2) => l10n.statusNew,
  TicketStatusKnown(value: TicketStatusValue.open) => l10n.statusOpen,
  TicketStatusKnown(value: TicketStatusValue.pending) => l10n.statusPending,
  TicketStatusKnown(value: TicketStatusValue.onHold) => l10n.statusOnHold,
  TicketStatusKnown(value: TicketStatusValue.solved) => l10n.statusSolved,
  TicketStatusKnown(value: TicketStatusValue.closed) => l10n.statusClosed,
  TicketStatusUnknown(:final rawValue) => '$rawValue',
};

String priorityLabel(TicketPriority priority, AppLocalizations l10n) => switch (priority) {
  TicketPriorityKnown(value: TicketPriorityValue.low) => l10n.priorityLow,
  TicketPriorityKnown(value: TicketPriorityValue.normal) => l10n.priorityNormal,
  TicketPriorityKnown(value: TicketPriorityValue.high) => l10n.priorityHigh,
  TicketPriorityKnown(value: TicketPriorityValue.urgent) => l10n.priorityUrgent,
  TicketPriorityUnknown(:final rawValue) => '$rawValue',
};

class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});

  final TicketStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (background, foreground) = switch (status) {
      TicketStatusKnown(value: TicketStatusValue.new2) => (scheme.primary, scheme.onPrimary),
      TicketStatusKnown(value: TicketStatusValue.open) => (
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
      ),
      TicketStatusKnown(value: TicketStatusValue.pending || TicketStatusValue.onHold) => (
        scheme.tertiaryContainer,
        scheme.onTertiaryContainer,
      ),
      _ => (scheme.surfaceContainerHighest, scheme.onSurfaceVariant),
    };
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(8)),
      child: Text(
        statusLabel(status, AppLocalizations.of(context)),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: foreground),
      ),
    );
  }
}

/// High and urgent get an icon as well as a word, so priority never depends on colour alone.
class PriorityMark extends StatelessWidget {
  const PriorityMark(this.priority, {super.key});

  final TicketPriority priority;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = priorityLabel(priority, AppLocalizations.of(context));
    final (icon, color) = switch (priority) {
      TicketPriorityKnown(value: TicketPriorityValue.urgent) => (Icons.priority_high, scheme.error),
      TicketPriorityKnown(value: TicketPriorityValue.high) => (
        Icons.keyboard_double_arrow_up,
        scheme.tertiary,
      ),
      _ => (null, scheme.onSurfaceVariant),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) Icon(icon, size: 16, color: color),
        Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color)),
      ],
    );
  }
}

enum SlaTone { breached, soon, ok, paused, met }

/// The deadline that matters next: an overdue one first, then the nearest open one.
({SlaTone tone, String text, String spoken})? slaSummary(
  TicketSlaDto sla,
  DateTime now,
  AppLocalizations l10n,
) {
  if (sla.isPaused) return (tone: SlaTone.paused, text: l10n.slaPaused, spoken: l10n.slaPaused);

  final firstOpen = !sla.firstResponseMet && sla.firstResponseDueAt != null;
  final candidates = <(DateTime, bool)>[
    if (firstOpen) (sla.firstResponseDueAt!, true),
    if (sla.resolutionDueAt != null) (sla.resolutionDueAt!, false),
  ]..sort((a, b) => a.$1.compareTo(b.$1));
  if (candidates.isEmpty) {
    return sla.firstResponseMet ? (tone: SlaTone.met, text: l10n.slaMet, spoken: l10n.slaMet) : null;
  }

  final (due, firstResponse) = candidates.first;
  final left = due.difference(now);
  final time = shortDuration(left, l10n);
  if (left.isNegative || sla.resolutionBreached || (firstResponse && sla.firstResponseBreached)) {
    return (
      tone: SlaTone.breached,
      text: l10n.slaOverdue(time),
      spoken: firstResponse ? l10n.slaFirstResponseOverdue(time) : l10n.slaResolutionOverdue(time),
    );
  }

  return (
    tone: left < const Duration(hours: 1) ? SlaTone.soon : SlaTone.ok,
    text: l10n.slaDueIn(time),
    spoken: firstResponse ? l10n.slaFirstResponseDue(time) : l10n.slaResolutionDue(time),
  );
}

class SlaChip extends StatelessWidget {
  const SlaChip(this.sla, {required this.now, super.key});

  final TicketSlaDto sla;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final summary = slaSummary(sla, now, AppLocalizations.of(context));
    if (summary == null) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final (icon, color) = switch (summary.tone) {
      SlaTone.breached => (Icons.error, scheme.error),
      SlaTone.soon => (Icons.timer, scheme.tertiary),
      SlaTone.ok => (Icons.schedule, scheme.onSurfaceVariant),
      SlaTone.paused => (Icons.pause_circle_outline, scheme.onSurfaceVariant),
      SlaTone.met => (Icons.check_circle_outline, scheme.onSurfaceVariant),
    };
    return Semantics(
      label: summary.spoken,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(summary.text, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color)),
        ],
      ),
    );
  }
}
