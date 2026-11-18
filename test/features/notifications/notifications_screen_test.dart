import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nexdesk_mobile/app/router.dart';
import 'package:nexdesk_mobile/core/api/generated/nex_desk_api.dart';
import 'package:nexdesk_mobile/core/realtime/live_hub.dart';

import '../../fakes.dart';
import '../ticket/ticket_helpers.dart';

Map<String, Object?> notificationJson(
  String id, {
  String type = 'Mention',
  bool isRead = false,
  String? actor = 'Tom Okafor',
  String? preview = 'can you check the billing side?',
}) => {
  'id': id,
  'type': type,
  'ticketId': ticketId,
  'ticketNumber': 271,
  'ticketSubject': 'Cannot export my data',
  'actorName': actor,
  'preview': preview,
  'createdAt': now.subtract(const Duration(minutes: 5)).toIso8601String(),
  'isRead': isRead,
};

FakeApi notificationsApi({int unread = 2}) {
  final api = ticketApi(permissions: agent);
  api.routes['GET /api/v1/notifications'] = (_) => json(
    200,
    pageJson([
      notificationJson('n1'),
      notificationJson('n2', type: 'SlaBreach', actor: null, preview: 'Resolution'),
      notificationJson('n3', type: 'TicketAssigned', isRead: true, actor: 'Daniel Reyes'),
    ]),
  );
  api.routes['GET /api/v1/notifications/unread-count'] = (_) => json(200, {'count': unread});
  api.routes['POST /api/v1/notifications/n1/read'] = (_) => json(200, {'count': unread - 1});
  api.routes['POST /api/v1/notifications/read-all'] = (_) => json(200, {'count': 0});
  return api;
}

Future<void> openNotifications(WidgetTester tester) async {
  await tester.tap(find.text('Notifications').last);
  await tester.pumpAndSettle();
}

String _path(ProviderContainer container) =>
    container.read(routerProvider).routerDelegate.currentConfiguration.uri.path;

void main() {
  testWidgets('the badge shows the unread count and the centre says what happened, as the web does', (
    tester,
  ) async {
    final container = await openTicket(tester, notificationsApi());
    container.read(routerProvider).go(Routes.inbox);
    await tester.pumpAndSettle();

    expect(
      find.descendant(of: find.byKey(const Key('unread-badge')), matching: find.text('2')),
      findsOneWidget,
    );

    await openNotifications(tester);
    expect(find.text('Tom Okafor mentioned you on ticket #271'), findsOneWidget);
    expect(find.text('Ticket #271 missed its resolution deadline'), findsOneWidget);
    expect(find.text('Daniel Reyes assigned ticket #271 to you'), findsOneWidget);
    expect(find.textContaining('can you check the billing side?'), findsWidgets);
  });

  testWidgets('opening a notification marks it read and opens its ticket', (tester) async {
    final api = notificationsApi();
    final container = await openTicket(tester, api);
    await openNotifications(tester);

    await tester.tap(find.byKey(const Key('notification-n1')));
    await tester.pumpAndSettle();

    expect(api.count('POST /api/v1/notifications/n1/read'), 1);
    expect(_path(container), '/app/tickets/$ticketId');
    expect(
      find.descendant(of: find.byKey(const Key('unread-badge')), matching: find.text('1')),
      findsOneWidget,
    );
  });

  testWidgets('mark all as read clears the badge', (tester) async {
    final api = notificationsApi();
    await openTicket(tester, api);
    await openNotifications(tester);

    await tester.tap(find.byKey(const Key('mark-all-read')));
    await tester.pumpAndSettle();

    expect(api.count('POST /api/v1/notifications/read-all'), 1);
    expect(tester.widget<Badge>(find.byKey(const Key('unread-badge')).first).isLabelVisible, isFalse);
  });

  testWidgets('a live notification raises the badge and shows a banner that opens the ticket', (
    tester,
  ) async {
    final hub = FakeLiveHub();
    final container = await openTicket(tester, notificationsApi(unread: 0), hub: hub);
    container.read(routerProvider).go(Routes.inbox);
    await tester.pumpAndSettle();

    hub.emit(NotificationArrived(NotificationDto.fromJson(notificationJson('n9', type: 'TicketReply'))));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(
      find.descendant(of: find.byKey(const Key('unread-badge')), matching: find.text('1')),
      findsOneWidget,
    );
    expect(find.text('Tom Okafor replied on ticket #271'), findsOneWidget);

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(_path(container), '/app/tickets/$ticketId');
  });

  testWidgets("someone else's change reloads the open ticket, and so does a reconnect", (tester) async {
    final hub = FakeLiveHub();
    final api = notificationsApi();
    await openTicket(tester, api, hub: hub);
    final before = api.count('GET /api/v1/tickets/$ticketId');

    hub.emit(TicketChanged(ticketId, 'updated'));
    await tester.pumpAndSettle();
    expect(api.count('GET /api/v1/tickets/$ticketId'), before + 1);

    hub.emit(const TicketChanged('another-ticket', 'updated'));
    await tester.pumpAndSettle();
    expect(api.count('GET /api/v1/tickets/$ticketId'), before + 1);

    hub.emit(const LiveConnected());
    await tester.pumpAndSettle();
    expect(api.count('GET /api/v1/tickets/$ticketId'), before + 2);
  });
}
