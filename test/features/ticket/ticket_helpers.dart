import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexdesk_mobile/app/router.dart';
import 'package:nexdesk_mobile/core/auth/session_controller.dart';
import 'package:nexdesk_mobile/core/auth/token_store.dart';

import '../../fakes.dart';
import '../../helpers.dart';

final now = DateTime.utc(2026, 11, 18, 12);
final ticket = jsonDecode(File('test/fixtures/ticket.json').readAsStringSync()) as Map<String, Object?>;
final timeline = jsonDecode(File('test/fixtures/timeline.json').readAsStringSync()) as List<Object?>;
final ticketId = ticket['id']! as String;
final ticketPath = '/api/v1/tickets/$ticketId';

const agent = ['tickets.view', 'tickets.reply', 'tickets.edit'];

/// The API for one real ticket (the fixtures), signed in with [permissions].
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

Future<ProviderContainer> openTicket(
  WidgetTester tester,
  FakeApi api, {
  FakeLiveHub? hub,
  List<Object> overrides = const [],
}) async {
  final container = await pumpApp(
    tester,
    api: api,
    tokens: MemoryTokenStore('r1'),
    hub: hub,
    overrides: [clockProvider.overrideWithValue(() => now), ...overrides],
  );
  container.read(routerProvider).go('/app/tickets/$ticketId');
  await tester.pumpAndSettle();
  return container;
}
