import 'package:material_ui/material_ui.dart';

import '../../../core/api/generated/nex_desk_api.dart';
import '../../../core/l10n/generated/app_localizations.dart';

/// One notification in words, as the web's bell says it.
String notificationText(NotificationDto n, AppLocalizations l10n) {
  final actor = n.actorName ?? l10n.someone;
  final metric = switch (n.preview) {
    'FirstResponse' => l10n.metricFirstResponse,
    'Resolution' => l10n.metricResolution,
    _ => n.preview ?? '',
  };
  return switch (n.type) {
    NotificationTypeKnown(value: NotificationTypeValue.ticketAssigned) => l10n.notifyTicketAssigned(
      actor,
      n.ticketNumber,
    ),
    NotificationTypeKnown(value: NotificationTypeValue.ticketReply) => l10n.notifyTicketReply(
      actor,
      n.ticketNumber,
    ),
    NotificationTypeKnown(value: NotificationTypeValue.ticketNote) => l10n.notifyTicketNote(
      actor,
      n.ticketNumber,
    ),
    NotificationTypeKnown(value: NotificationTypeValue.slaWarning) => l10n.notifySlaWarning(
      n.ticketNumber,
      metric,
    ),
    NotificationTypeKnown(value: NotificationTypeValue.slaBreach) => l10n.notifySlaBreach(
      n.ticketNumber,
      metric,
    ),
    NotificationTypeKnown(value: NotificationTypeValue.mention) => l10n.notifyMention(actor, n.ticketNumber),
    _ => l10n.notifyAutomation(actor, n.ticketNumber),
  };
}

bool isSlaNotification(NotificationDto n) =>
    n.type == NotificationType.slaWarning || n.type == NotificationType.slaBreach;

IconData notificationIcon(NotificationDto n) => switch (n.type) {
  NotificationTypeKnown(value: NotificationTypeValue.ticketAssigned) => Icons.assignment_ind_outlined,
  NotificationTypeKnown(value: NotificationTypeValue.ticketReply) => Icons.reply,
  NotificationTypeKnown(value: NotificationTypeValue.ticketNote) => Icons.lock_outline,
  NotificationTypeKnown(value: NotificationTypeValue.slaWarning) => Icons.schedule,
  NotificationTypeKnown(value: NotificationTypeValue.slaBreach) => Icons.alarm_off,
  NotificationTypeKnown(value: NotificationTypeValue.mention) => Icons.alternate_email,
  _ => Icons.bolt,
};
