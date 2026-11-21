import 'package:flutter_test/flutter_test.dart';
import 'package:nexdesk_mobile/core/auth/session_controller.dart';
import 'package:nexdesk_mobile/features/inbox/presentation/inbox_screen.dart';
import 'package:nexdesk_mobile/features/notifications/application/notifications_controller.dart';

import '../../fakes.dart';

const login = 'POST /api/v1/auth/mobile/login';
const notifications = 'GET /api/v1/notifications';
const unreadCount = 'GET /api/v1/notifications/unread-count';

Map<String, Object?> notification(String id) => {
  'id': id,
  'type': 'Mention',
  'ticketId': 'ticket-1',
  'ticketNumber': 271,
  'ticketSubject': 'Cannot export my data',
  'actorName': 'Tom Okafor',
  'preview': 'can you check the billing side?',
  'createdAt': DateTime.utc(2026, 11, 18, 12).toIso8601String(),
  'isRead': false,
};

void main() {
  test('the next person signing in on this phone sees nothing the last one had loaded', () async {
    final api = FakeApi();
    api.routes[login] = (_) => json(200, authBody(access: 'a1', refresh: 'r1'));
    api.routes['POST /api/v1/auth/mobile/logout'] = (_) => json(204, '');
    api.routes[notifications] = (_) => json(200, pageJson([notification('n1'), notification('n2')]));
    api.routes[unreadCount] = (_) => json(200, {'count': 2});
    final container = fakeContainer(api);
    addTearDown(container.dispose);
    final session = container.read(sessionProvider.notifier);

    await session.signIn('maya@brightpath.demo', 'pw');
    container.listen(notificationsProvider, (_, _) {});
    await pumpEventQueue();
    expect(container.read(notificationsProvider).items, hasLength(2));
    container.read(selectedTicketProvider.notifier).set('ticket-1');

    await session.signOut();
    api.routes[login] = (_) => json(200, authBody(access: 'a2', refresh: 'r2', userId: 'user-sam'));
    api.routes[notifications] = (_) => json(200, pageJson([]));
    api.routes[unreadCount] = (_) => json(200, {'count': 0});
    await session.signIn('sam@brightpath.demo', 'pw');

    // Before the new person's lists have loaded.
    expect(container.read(notificationsProvider).items, isEmpty);
    expect(container.read(notificationsProvider).unread, 0);
    expect(container.read(selectedTicketProvider), isNull);

    await pumpEventQueue();
    expect(container.read(notificationsProvider).items, isEmpty);
    expect(api.count(notifications), 2);
  });
}
