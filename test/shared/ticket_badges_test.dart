import 'package:flutter_test/flutter_test.dart';
import 'package:nexdesk_mobile/core/api/generated/nex_desk_api.dart';
import 'package:nexdesk_mobile/core/l10n/generated/app_localizations_ar.dart';
import 'package:nexdesk_mobile/core/l10n/generated/app_localizations_en.dart';
import 'package:nexdesk_mobile/shared/ticket_badges.dart';
import 'package:nexdesk_mobile/shared/time_text.dart';

final now = DateTime.utc(2026, 11, 18, 12);
final en = AppLocalizationsEn();
final ar = AppLocalizationsAr();

TicketSlaDto sla({
  DateTime? firstDue,
  bool firstMet = false,
  bool firstBreached = false,
  DateTime? resolutionDue,
  bool resolutionBreached = false,
  bool paused = false,
}) => TicketSlaDto(
  firstResponseDueAt: firstDue,
  firstResponseBreached: firstBreached,
  firstResponseMet: firstMet,
  resolutionDueAt: resolutionDue,
  resolutionBreached: resolutionBreached,
  isPaused: paused,
  isEscalated: false,
);

void main() {
  test('the nearest open deadline is shown, and read out in full', () {
    final summary = slaSummary(
      sla(firstDue: now.add(const Duration(minutes: 25)), resolutionDue: now.add(const Duration(days: 2))),
      now,
      en,
    )!;
    expect(summary.tone, SlaTone.soon);
    expect(summary.text, 'Due in 25 min');
    expect(summary.spoken, 'First response due in 25 min');
  });

  test('a met first response leaves the resolution clock', () {
    final summary = slaSummary(
      sla(firstDue: now, firstMet: true, resolutionDue: now.add(const Duration(hours: 5))),
      now,
      en,
    )!;
    expect((summary.tone, summary.text, summary.spoken), (SlaTone.ok, 'Due in 5 h', 'Resolution due in 5 h'));
  });

  test('overdue, paused and done each have their own wording', () {
    expect(
      slaSummary(
        sla(resolutionDue: now.subtract(const Duration(days: 3)), resolutionBreached: true),
        now,
        en,
      )!.spoken,
      'Resolution overdue by 3 d',
    );
    expect(slaSummary(sla(paused: true), now, en)!.text, 'Paused');
    expect(slaSummary(sla(firstMet: true), now, en)!.tone, SlaTone.met);
    expect(slaSummary(sla(), now, en), isNull);
  });

  test('Arabic gets its own units', () {
    expect(slaSummary(sla(resolutionDue: now.add(const Duration(minutes: 90))), now, ar)!.text, 'خلال 1 س');
  });

  test('time ago uses each language plural forms', () {
    expect(timeAgo(now.subtract(const Duration(seconds: 20)), now, en), 'just now');
    expect(timeAgo(now.subtract(const Duration(minutes: 1)), now, en), '1 minute ago');
    expect(timeAgo(now.subtract(const Duration(hours: 3)), now, en), '3 hours ago');
    expect(timeAgo(now.subtract(const Duration(days: 1)), now, en), 'yesterday');
    expect(timeAgo(now.subtract(const Duration(minutes: 2)), now, ar), 'قبل دقيقتين');
    expect(timeAgo(now.subtract(const Duration(hours: 5)), now, ar), 'قبل 5 ساعات');
    expect(timeAgo(now.subtract(const Duration(days: 11)), now, ar), 'قبل 11 يومًا');
  });

  test('status and priority names, with unknown values passed through', () {
    expect(statusLabel(TicketStatus.onHold, en), 'On hold');
    expect(statusLabel(TicketStatus.pending, ar), 'بانتظار العميل');
    expect(statusLabel(TicketStatus.fromJson('Escalated'), en), 'Escalated');
    expect(priorityLabel(TicketPriority.urgent, ar), 'عاجلة');
  });
}
