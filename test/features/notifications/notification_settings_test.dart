import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nexdesk_mobile/app/router.dart';
import 'package:nexdesk_mobile/core/push/push_service.dart';

import '../../core/push/push_test.dart' show FakePushService;
import '../../fakes.dart';
import '../ticket/ticket_helpers.dart';

List<Map<String, Object?>> prefs({bool push = true}) => [
  {'type': 'TicketAssigned', 'inApp': true, 'email': true, 'push': push},
  {'type': 'Mention', 'inApp': true, 'email': false, 'push': push},
];

FakeApi settingsApi() {
  final api = ticketApi(permissions: agent);
  api.routes['GET /api/v1/notifications/preferences'] = (_) => json(200, prefs());
  api.routes['PUT /api/v1/notifications/preferences'] = (request) {
    final body = jsonDecode(request.data as String) as Map<String, Object?>;
    return json(200, body['preferences']!);
  };
  return api;
}

void main() {
  testWidgets('a build without push says so and keeps the phone column off', (tester) async {
    final container = await openTicket(tester, settingsApi());
    container.read(routerProvider).go(Routes.notificationSettings);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('push-unavailable')), findsOneWidget);
    final push = tester.widget<SwitchListTile>(find.byKey(const Key('pref-TicketAssigned-push')));
    expect(push.value, isFalse);
    expect(push.onChanged, isNull);
  });

  testWidgets('turning push off for one event saves the whole set, as the web does', (tester) async {
    final api = settingsApi();
    final container = await openTicket(
      tester,
      api,
      overrides: [pushServiceProvider.overrideWithValue(FakePushService())],
    );
    container.read(routerProvider).go(Routes.notificationSettings);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('push-unavailable')), findsNothing);

    await tester.tap(find.byKey(const Key('pref-Mention-push')));
    await tester.pumpAndSettle();

    final saved = api.calls.singleWhere((c) => c.method == 'PUT' && c.path.endsWith('/preferences'));
    final sent = (jsonDecode(saved.data as String) as Map<String, Object?>)['preferences']! as List<Object?>;
    expect(sent, hasLength(2));
    expect((sent[1]! as Map)['push'], isFalse);
    expect((sent[0]! as Map)['push'], isTrue);
    expect(tester.widget<SwitchListTile>(find.byKey(const Key('pref-Mention-push'))).value, isFalse);
  });

  testWidgets('a slow save answering after a newer one does not undo the newer switch', (tester) async {
    final api = settingsApi();
    final firstSave = Completer<void>();
    var saves = 0;
    api.routes['PUT /api/v1/notifications/preferences'] = (request) async {
      final body = jsonDecode(request.data as String) as Map<String, Object?>;
      if (++saves == 1) await firstSave.future;
      return json(200, body['preferences']!);
    };
    final container = await openTicket(
      tester,
      api,
      overrides: [pushServiceProvider.overrideWithValue(FakePushService())],
    );
    container.read(routerProvider).go(Routes.notificationSettings);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('pref-Mention-push')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('pref-TicketAssigned-push')));
    await tester.pumpAndSettle();
    firstSave.complete();
    await tester.pumpAndSettle();

    expect(saves, 2);
    expect(tester.widget<SwitchListTile>(find.byKey(const Key('pref-Mention-push'))).value, isFalse);
    expect(tester.widget<SwitchListTile>(find.byKey(const Key('pref-TicketAssigned-push'))).value, isFalse);
  });
}
