import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexdesk_mobile/core/auth/session_controller.dart';
import 'package:nexdesk_mobile/core/cache/database.dart';
import 'package:nexdesk_mobile/features/inbox/presentation/inbox_screen.dart';
import 'package:nexdesk_mobile/features/notifications/application/notifications_controller.dart';
import 'package:nexdesk_mobile/features/ticket/data/ticket_repository.dart';

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

  test("the last person's answer arriving after the next one signed in is dropped", () async {
    final api = FakeApi();
    final held = Completer<ResponseBody>();
    api.routes[login] = (_) => json(200, authBody(access: 'a1', refresh: 'r1'));
    api.routes['POST /api/v1/auth/mobile/logout'] = (_) => json(204, '');
    api.routes[notifications] = (_) => held.future;
    api.routes[unreadCount] = (_) => json(200, {'count': 2});
    final container = fakeContainer(api);
    addTearDown(container.dispose);
    final session = container.read(sessionProvider.notifier);

    await session.signIn('maya@brightpath.demo', 'pw');
    container.listen(notificationsProvider, (_, _) {});
    await pumpEventQueue();
    expect(api.count(notifications), 1, reason: "Maya's list is still on its way");

    await session.signOut();
    api.routes[login] = (_) => json(200, authBody(access: 'a2', refresh: 'r2', userId: 'user-sam'));
    api.routes[notifications] = (_) => json(200, pageJson([]));
    api.routes[unreadCount] = (_) => json(200, {'count': 0});
    await session.signIn('sam@brightpath.demo', 'pw');
    await pumpEventQueue();

    held.complete(json(200, pageJson([notification('n1'), notification('n2')])));
    await pumpEventQueue();

    expect(container.read(notificationsProvider).items, isEmpty);
    expect(container.read(notificationsProvider).unread, 0);
  });

  test("the last person's answer arriving after sign-out is not written to the phone's cache", () async {
    final api = FakeApi();
    final held = Completer<ResponseBody>();
    api.routes[login] = (_) => json(200, authBody(access: 'a1', refresh: 'r1'));
    api.routes['POST /api/v1/auth/mobile/logout'] = (_) => json(204, '');
    api.routes['GET /api/v1/users'] = (_) => held.future;
    final container = fakeContainer(api);
    addTearDown(container.dispose);
    final session = container.read(sessionProvider.notifier);

    await session.signIn('maya@brightpath.demo', 'pw');
    final team = container.read(ticketRepositoryProvider).people();
    await pumpEventQueue();
    await session.signOut();

    held.complete(
      json(
        200,
        pageJson([
          {
            'id': 'user-tom',
            'email': 'tom@brightpath.demo',
            'fullName': 'Tom Okafor',
            'role': 'Agent',
            'isActive': true,
            'availability': 'Online',
            'emailVerified': true,
            'lastLoginAt': null,
            'createdAt': '2026-11-01T09:00:00Z',
          },
        ]),
      ),
    );
    await team;
    await pumpEventQueue();

    expect(await container.read(databaseProvider).read('people'), isNull);
  });
}
