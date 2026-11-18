import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nexdesk_mobile/app/preferences.dart';
import 'package:nexdesk_mobile/app/router.dart';
import 'package:nexdesk_mobile/core/auth/session_controller.dart';
import 'package:nexdesk_mobile/core/auth/token_store.dart';
import 'package:nexdesk_mobile/features/ticket/presentation/ticket_screen.dart';

import '../../fakes.dart';
import '../../helpers.dart';

final now = DateTime.utc(2026, 11, 18, 12);

FakeApi inboxApi({String language = 'en'}) {
  final api = FakeApi();
  api.routes['POST /api/v1/auth/mobile/refresh'] = (_) =>
      json(200, authBody(access: 'a', refresh: 'r2', language: language));
  api.routes['GET /api/v1/tickets'] = (_) => json(
    200,
    pageJson([
      ticketJson(
        271,
        status: 'New',
        priority: 'Urgent',
        lastActivity: now.subtract(const Duration(hours: 1)),
        resolutionDue: now.add(const Duration(minutes: 40)),
      ),
      ticketJson(
        261,
        status: 'Pending',
        priority: 'Low',
        lastActivity: now.subtract(const Duration(hours: 11)),
        paused: true,
      ),
      ticketJson(
        250,
        priority: 'High',
        lastActivity: now.subtract(const Duration(days: 5)),
        resolutionDue: now.subtract(const Duration(hours: 2)),
        breached: true,
      ),
    ]),
  );
  return api;
}

Future<ProviderContainer> pumpInbox(
  WidgetTester tester, {
  String language = 'en',
  FakeApi? api,
  Size size = const Size(400, 860),
  List<Object> overrides = const [],
}) => pumpApp(
  tester,
  language: language,
  api: api ?? inboxApi(language: language),
  tokens: MemoryTokenStore('r1'),
  size: size,
  overrides: [clockProvider.overrideWithValue(() => now), ...overrides],
);

String _path(ProviderContainer container) =>
    container.read(routerProvider).routerDelegate.currentConfiguration.uri.path;

void main() {
  testWidgets('lists my tickets with status, priority, deadline and age', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpInbox(tester);

    expect(find.text('Mine'), findsOneWidget);
    expect(find.textContaining('Subject 271', findRichText: true), findsOneWidget);
    expect(find.text('New'), findsOneWidget);
    expect(find.text('Urgent'), findsOneWidget);
    expect(find.text('Due in 40 min'), findsOneWidget);
    expect(find.text('Paused'), findsOneWidget);
    expect(find.text('Overdue 2 h'), findsOneWidget);
    expect(find.text('1 hour ago'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Resolution overdue by 2 h')), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('tapping a ticket opens it', (tester) async {
    final container = await pumpInbox(tester);

    await tester.tap(find.textContaining('Subject 261', findRichText: true));
    await tester.pumpAndSettle();

    expect(_path(container), '/app/tickets/ticket-261');
    expect(find.byType(TicketScreen), findsOneWidget);
  });

  testWidgets('on a tablet the ticket opens beside the list', (tester) async {
    final container = await pumpInbox(tester, size: const Size(1200, 800));
    expect(find.text('Choose a ticket to see it here.'), findsOneWidget);

    await tester.tap(find.textContaining('Subject 250', findRichText: true));
    await tester.pumpAndSettle();

    expect(_path(container), Routes.inbox);
    expect(find.byType(TicketScreen), findsOneWidget);
  });

  testWidgets('offline, the cached list stays with a banner', (tester) async {
    final api = inboxApi();
    final container = await pumpInbox(tester, api: api);
    api.routes['GET /api/v1/tickets'] = (request) =>
        throw DioException.connectionError(requestOptions: request, reason: 'offline');

    await tester.drag(find.textContaining('Subject 271', findRichText: true), const Offset(0, 400));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('offline-banner')), findsOneWidget);
    expect(find.textContaining('Subject 271', findRichText: true), findsOneWidget);
    expect(container, isNotNull);
  });

  testWidgets('a saved view from the web replaces the tabs until cleared', (tester) async {
    final api = inboxApi()
      ..routes['GET /api/v1/views'] = (_) => json(200, [
        {
          'id': 'v1',
          'name': 'Urgent and open',
          'isShared': true,
          'isMine': false,
          'filter': {
            'status': ['New', 'Open'],
            'priority': ['Urgent'],
            'assignee': null,
            'teamId': null,
            'tag': null,
            'search': null,
            'sort': '-priority',
          },
        },
      ]);
    await pumpInbox(tester, api: api);

    await tester.tap(find.byKey(const Key('views')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Urgent and open'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Urgent and open'), findsOneWidget);
    expect(find.text('Mine'), findsNothing);
    final params = Uri.parse(api.calls.last.uri.toString()).queryParametersAll;
    expect(params['Priority'], ['Urgent']);

    await tester.tap(find.byTooltip('Back to the inbox'));
    await tester.pumpAndSettle();
    expect(find.text('Mine'), findsOneWidget);
  });

  testWidgets('in Arabic the tabs and badges read in Arabic, right to left', (tester) async {
    await pumpInbox(tester, language: 'ar');

    expect(find.text('تذاكري'), findsOneWidget);
    expect(find.text('جديدة'), findsOneWidget);
    expect(find.text('عاجلة'), findsOneWidget);
    expect(Directionality.of(tester.element(find.text('تذاكري'))), TextDirection.rtl);
  });

  for (final (language, mode) in [('en', ThemeMode.light), ('ar', ThemeMode.dark)]) {
    testWidgets('golden: inbox, $language, ${mode.name}', (tester) async {
      final preferencesMode = mode == ThemeMode.dark ? 'dark' : 'light';
      final container = await pumpInbox(tester, language: language);
      await container
          .read(themeModeProvider.notifier)
          .set(preferencesMode == 'dark' ? ThemeMode.dark : ThemeMode.light);
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('../../goldens/inbox_${language}_${mode.name}.png'),
      );
    });
  }
}
