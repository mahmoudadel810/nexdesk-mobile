import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nexdesk_mobile/app/router.dart';

import '../../fakes.dart';
import 'ticket_helpers.dart';

const creator = ['tickets.view', 'tickets.create', 'tickets.reply', 'tickets.edit'];

FakeApi createApi() {
  final api = ticketApi(permissions: creator);
  api.routes['GET /api/v1/customers'] = (_) => json(
    200,
    pageJson([
      {
        'id': 'customer-casey',
        'email': 'casey@customers.demo',
        'fullName': 'Casey Morgan',
        'createdAt': now.toIso8601String(),
      },
    ]),
  );
  api.routes['POST /api/v1/tickets'] = (_) => json(201, ticket);
  return api;
}

String path(ProviderContainer container) =>
    container.read(routerProvider).routerDelegate.currentConfiguration.uri.path;

Future<ProviderContainer> openForm(WidgetTester tester, FakeApi api, {String? language}) async {
  final container = await openTicket(tester, api);
  container.read(routerProvider).go(Routes.inbox);
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('new-ticket')));
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('without the create permission there is no New ticket button', (tester) async {
    final container = await openTicket(tester, ticketApi(permissions: agent));
    container.read(routerProvider).go(Routes.inbox);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('new-ticket')), findsNothing);
  });

  testWidgets('the form asks for the customer, subject and description before sending', (tester) async {
    final api = createApi();
    await openForm(tester, api);

    await tester.tap(find.byKey(const Key('create-ticket')));
    await tester.pumpAndSettle();

    expect(find.text('Fill this in.'), findsNWidgets(3));
    expect(api.count('POST /api/v1/tickets'), 0);
  });

  testWidgets('an existing customer picked from the search is sent by id, and the new ticket opens', (
    tester,
  ) async {
    final api = createApi();
    final container = await openForm(tester, api);

    await tester.enterText(find.byKey(const Key('requester-email')), 'case');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('customer-customer-casey')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('subject')), 'Phone call: invoice missing');
    await tester.enterText(find.byKey(const Key('description')), 'Casey called about the November invoice.');
    await tester.ensureVisible(find.byKey(const Key('create-ticket')));
    await tester.tap(find.byKey(const Key('create-ticket')));
    await tester.pumpAndSettle();

    final sent = jsonDecode(
      api.calls.singleWhere((c) => c.method == 'POST' && c.path == '/api/v1/tickets').data as String,
    ) as Map<String, Object?>;
    expect(sent['requesterId'], 'customer-casey');
    expect(sent['requesterEmail'], isNull);
    expect(sent['subject'], 'Phone call: invoice missing');
    expect(sent['priority'], 'Normal');
    expect(path(container), '/app/tickets/$ticketId');
  });

  testWidgets('a new customer is sent by email and name', (tester) async {
    final api = createApi();
    await openForm(tester, api);

    await tester.enterText(find.byKey(const Key('requester-email')), 'new.person@example.com');
    await tester.enterText(find.byKey(const Key('requester-name')), 'New Person');
    await tester.enterText(find.byKey(const Key('subject')), 'Walk-in question');
    await tester.enterText(find.byKey(const Key('description')), 'Asked about opening hours.');
    await tester.ensureVisible(find.byKey(const Key('create-ticket')));
    await tester.tap(find.byKey(const Key('create-ticket')));
    await tester.pumpAndSettle();

    final sent = jsonDecode(
      api.calls.singleWhere((c) => c.method == 'POST' && c.path == '/api/v1/tickets').data as String,
    ) as Map<String, Object?>;
    expect(sent['requesterId'], isNull);
    expect(sent['requesterEmail'], 'new.person@example.com');
    expect(sent['requesterName'], 'New Person');
  });

  testWidgets('the form in Arabic, right to left', (tester) async {
    final api = createApi();
    api.routes['POST /api/v1/auth/mobile/refresh'] = (_) {
      final body = authBody(access: 'a', refresh: 'r2', language: 'ar');
      (body['session']! as Map<String, Object?>)['permissions'] = creator;
      return json(200, body);
    };
    await openForm(tester, api);

    expect(Directionality.of(tester.element(find.byKey(const Key('subject')))), TextDirection.rtl);
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('../../goldens/create_ticket_ar.png'));
  });
}
