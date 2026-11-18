import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexdesk_mobile/app/router.dart';

import '../fakes.dart';
import '../features/notifications/notifications_screen_test.dart' show notificationsApi;
import '../features/ticket/create_ticket_test.dart' show creator;
import '../features/ticket/ticket_helpers.dart';

/// Every main screen at 200% text size (an overflow fails the test) and against Flutter's accessibility
/// guidelines: tap targets of at least 48 dp, a label on everything tappable, and readable contrast.
const screens = {
  'inbox': Routes.inbox,
  'ticket': '/app/tickets/01a1eb4a-f7f9-7578-8884-e487165a1768',
  'notifications': Routes.notifications,
  'profile': Routes.profile,
  'new ticket': Routes.newTicket,
  'notification settings': Routes.notificationSettings,
};

FakeApi everythingApi() {
  final api = notificationsApi();
  api.routes['POST /api/v1/auth/mobile/refresh'] = (_) {
    final body = authBody(access: 'a', refresh: 'r2');
    (body['session']! as Map<String, Object?>)['permissions'] = creator;
    return json(200, body);
  };
  api.routes['GET /api/v1/tickets'] = (_) => json(200, pageJson([ticketJson(271), ticketJson(262)]));
  api.routes['GET /api/v1/notifications/preferences'] = (_) => json(200, [
    {'type': 'TicketAssigned', 'inApp': true, 'email': true, 'push': true},
  ]);
  return api;
}

Future<ProviderContainer> show(WidgetTester tester, String path, {double textScale = 1}) async {
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  final container = await openTicket(tester, everythingApi());
  container.read(routerProvider).go(path);
  await tester.pumpAndSettle();
  return container;
}

void main() {
  for (final MapEntry(key: name, value: path) in screens.entries) {
    testWidgets('$name fits at 200% text size', (tester) async {
      await show(tester, path, textScale: 2);
      expect(tester.takeException(), isNull);
    });

    testWidgets('$name meets the tap target, label and contrast guidelines', (tester) async {
      final semantics = tester.ensureSemantics();
      await show(tester, path);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      semantics.dispose();
    });
  }
}
