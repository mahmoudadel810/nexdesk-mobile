import '../core/l10n/generated/app_localizations.dart';

/// "25 min", "3 h", "2 d": the largest whole unit, at least one minute.
String shortDuration(Duration duration, AppLocalizations l10n) {
  final minutes = duration.inMinutes.abs();
  if (minutes < 60) return l10n.minutesShort(minutes < 1 ? 1 : minutes);
  if (minutes < 60 * 48) return l10n.hoursShort(minutes ~/ 60);
  return l10n.daysShort(minutes ~/ (60 * 24));
}

/// "just now", "5 minutes ago", "yesterday", with each language's plural forms.
String timeAgo(DateTime at, DateTime now, AppLocalizations l10n) {
  final elapsed = now.difference(at);
  if (elapsed.inMinutes < 1) return l10n.justNow;
  if (elapsed.inHours < 1) return l10n.agoMinutes(elapsed.inMinutes);
  if (elapsed.inDays < 1) return l10n.agoHours(elapsed.inHours);
  return l10n.agoDays(elapsed.inDays);
}
