import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nexdesk_mobile/app/router.dart';
import 'package:nexdesk_mobile/features/ticket/application/ticket_controller.dart';
import 'package:nexdesk_mobile/features/ticket/presentation/ticket_screen.dart';

import '../../fakes.dart';
import 'ticket_helpers.dart';

void main() {
  testWidgets('someone who may reply but not edit gets the composer and no ticket actions', (tester) async {
    await openTicket(tester, ticketApi(permissions: ['tickets.view', 'tickets.reply']));

    expect(find.byKey(const Key('composer')), findsOneWidget);
    expect(find.byKey(const Key('read-only')), findsNothing);
    expect(find.byKey(const Key('ticket-actions')), findsNothing);
  });

  testWidgets('a viewer reads the ticket but gets a read-only notice instead of the composer', (
    tester,
  ) async {
    await openTicket(tester, ticketApi(permissions: ['tickets.view']));

    expect(find.byKey(const Key('ticket-subject')), findsOneWidget);
    expect(find.byKey(const Key('read-only')), findsOneWidget);
    expect(find.byKey(const Key('composer')), findsNothing);
    expect(find.byKey(const Key('ticket-actions')), findsNothing);
  });

  testWidgets('a change refused as stale shows the banner, and Apply again sends it to the new version', (
    tester,
  ) async {
    final api = ticketApi(permissions: agent);
    var updates = 0;
    api.routes['PATCH $ticketPath'] = (_) =>
        ++updates == 1 ? problem(409, 'stale-ticket') : json(200, ticket);
    await openTicket(tester, api);

    await tester.tap(find.byKey(const Key('ticket-actions')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('status-Pending')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('stale-banner')), findsOneWidget);
    expect(updates, 1);

    await tester.tap(find.text('Apply mine again'));
    await tester.pumpAndSettle();

    expect(updates, 2);
    expect(find.byKey(const Key('stale-banner')), findsNothing);
  });

  testWidgets('Assign to says why when the team cannot be loaded', (tester) async {
    final api = ticketApi(permissions: agent);
    api.routes['GET /api/v1/users'] = (_) => problem(500, 'internal-error');
    await openTicket(tester, api);

    await tester.tap(find.byKey(const Key('ticket-actions')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Assign to…'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Something went wrong'), findsOneWidget);
  });

  testWidgets('what is typed in the composer comes back after leaving the ticket', (tester) async {
    final container = await openTicket(tester, ticketApi(permissions: agent));

    await tester.enterText(find.byKey(const Key('composer')), 'Checking the export logs now');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    container.read(routerProvider).go('/app/tickets');
    await tester.pumpAndSettle();
    expect(find.byType(TicketScreen), findsNothing);

    container.read(routerProvider).go('/app/tickets/$ticketId');
    await tester.pumpAndSettle();

    expect(find.text('Checking the export logs now'), findsOneWidget);
  });

  testWidgets('after sending, the timeline scrolls to the new message', (tester) async {
    Map<String, Object?> message(int n) => {
      ...timeline[0]! as Map<String, Object?>,
      'id': 'message-$n',
      'body': 'Earlier message $n',
    };
    final long = [for (var n = 0; n < 20; n++) message(n)];
    final api = ticketApi(permissions: agent);
    api.routes['GET $ticketPath/timeline'] = (_) => json(200, long);
    api.routes['POST $ticketPath/messages'] = (_) {
      long.add({...message(99), 'body': 'Sent from the phone'});
      return json(200, ticket);
    };
    await openTicket(tester, api);

    await tester.enterText(find.byKey(const Key('composer')), 'Sent from the phone');
    await tester.tap(find.byKey(const Key('send')));
    await tester.pumpAndSettle();

    expect(find.text('Sent from the phone', findRichText: true).hitTestable(), findsOneWidget);
  });

  testWidgets('someone reading older history is not moved when new entries arrive', (tester) async {
    Map<String, Object?> message(int n) => {
      ...timeline[0]! as Map<String, Object?>,
      'id': 'message-$n',
      'body': 'Earlier message $n',
    };
    final long = [for (var n = 0; n < 20; n++) message(n)];
    final api = ticketApi(permissions: agent);
    api.routes['GET $ticketPath/timeline'] = (_) => json(200, long);
    final container = await openTicket(tester, api);
    expect(find.text('Earlier message 0', findRichText: true).hitTestable(), findsOneWidget);

    long.add({...message(99), 'body': 'From the web'});
    unawaited(container.read(ticketProvider(ticketId).notifier).refresh());
    await tester.pumpAndSettle();
    expect(container.read(ticketProvider(ticketId)).view!.timeline, hasLength(21));

    expect(find.text('Earlier message 0', findRichText: true).hitTestable(), findsOneWidget);
  });
}
