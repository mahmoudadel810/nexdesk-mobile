import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nexdesk_mobile/app/router.dart';
import 'package:nexdesk_mobile/core/auth/session_controller.dart';
import 'package:nexdesk_mobile/core/auth/token_store.dart';
import 'package:nexdesk_mobile/features/ticket/presentation/ticket_screen.dart';

import '../../fakes.dart';
import '../../helpers.dart';

final now = DateTime.utc(2026, 11, 18, 12);
final ticket = jsonDecode(File('test/fixtures/ticket.json').readAsStringSync()) as Map<String, Object?>;
final timeline = jsonDecode(File('test/fixtures/timeline.json').readAsStringSync()) as List<Object?>;
final ticketId = ticket['id']! as String;
final ticketPath = '/api/v1/tickets/$ticketId';

FakeApi ticketApi({required List<String> permissions}) {
  final auth = authBody(access: 'a', refresh: 'r2');
  (auth['session']! as Map<String, Object?>)['permissions'] = permissions;
  final api = FakeApi();
  api.routes['POST /api/v1/auth/mobile/refresh'] = (_) => json(200, auth);
  api.routes['GET /api/v1/tickets'] = (_) => json(200, pageJson([]));
  api.routes['GET $ticketPath'] = (_) => json(200, ticket);
  api.routes['GET $ticketPath/timeline'] = (_) => json(200, timeline);
  api.routes['GET /api/v1/users'] = (_) => json(200, pageJson([]));
  api.routes['GET /api/v1/custom-fields'] = (_) => json(200, []);
  return api;
}

Future<ProviderContainer> openTicket(WidgetTester tester, FakeApi api) async {
  final container = await pumpApp(
    tester,
    api: api,
    tokens: MemoryTokenStore('r1'),
    overrides: [clockProvider.overrideWithValue(() => now)],
  );
  container.read(routerProvider).go('/app/tickets/$ticketId');
  await tester.pumpAndSettle();
  return container;
}

const agent = ['tickets.view', 'tickets.reply', 'tickets.edit'];

void main() {
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
}
