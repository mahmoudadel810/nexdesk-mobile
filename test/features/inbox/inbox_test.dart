import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexdesk_mobile/core/api/generated/nex_desk_api.dart';
import 'package:nexdesk_mobile/core/auth/session_controller.dart';
import 'package:nexdesk_mobile/core/auth/token_store.dart';
import 'package:nexdesk_mobile/features/inbox/application/inbox_controller.dart';
import 'package:nexdesk_mobile/features/inbox/data/inbox_query.dart';

import '../../fakes.dart';

const tickets = 'GET /api/v1/tickets';

Future<ProviderContainer> signedIn(FakeApi api) async {
  api.routes['POST /api/v1/auth/mobile/login'] = (_) => json(200, authBody(access: 'a', refresh: 'r'));
  final container = fakeContainer(api, tokens: MemoryTokenStore());
  await container.read(sessionProvider.notifier).signIn('maya@brightpath.demo', 'pw');
  return container;
}

/// Waits until the list has finished its network round.
Future<InboxState> settle(ProviderContainer container, InboxQuery query) async {
  container.listen(inboxProvider(query), (_, _) {});
  for (var i = 0; i < 50; i++) {
    await Future<void>.delayed(Duration.zero);
    final state = container.read(inboxProvider(query));
    if (!state.loading && state.cachedAt == null || state.error != null) return state;
  }
  return container.read(inboxProvider(query));
}

void main() {
  test('Mine asks for my unresolved tickets, newest activity first', () async {
    final api = FakeApi()..routes[tickets] = (_) => json(200, pageJson([ticketJson(1)]));
    final container = await signedIn(api);
    addTearDown(container.dispose);

    await settle(container, InboxQuery.mine);

    final request = api.calls.last;
    final params = Uri.parse(request.uri.toString()).queryParametersAll;
    expect(params['Status'], ['New', 'Open', 'Pending', 'OnHold']);
    expect(params['AssigneeId'], ['user-maya']);
    expect(params['Sort'], ['-lastActivityAt']);
    expect(params['Page'], ['1']);
    expect(params['PageSize'], ['25']);
  });

  test('Unassigned, SLA and saved views turn into the same filters as on the web', () async {
    final api = FakeApi()..routes[tickets] = (_) => json(200, pageJson([]));
    final container = await signedIn(api);
    addTearDown(container.dispose);
    Map<String, List<String>> paramsFor(InboxQuery query) =>
        Uri.parse(api.calls.last.uri.toString()).queryParametersAll;

    await settle(container, InboxQuery.unassigned);
    expect(paramsFor(InboxQuery.unassigned)['Unassigned'], ['true']);
    expect(paramsFor(InboxQuery.unassigned).containsKey('AssigneeId'), isFalse);

    await settle(container, InboxQuery.breached);
    expect(paramsFor(InboxQuery.breached)['Sla'], ['Breached']);
    expect(paramsFor(InboxQuery.breached)['Sort'], ['due']);

    final view = InboxQuery.fromView(
      TicketViewFilter.fromJson({
        'status': ['Pending'],
        'priority': ['Urgent', 'High'],
        'assignee': 'me',
        'teamId': null,
        'tag': 'vip',
        'search': null,
        'sort': '-priority',
      }),
    );
    await settle(container, view);
    final params = paramsFor(view);
    expect(params['Status'], ['Pending']);
    expect(params['Priority'], ['Urgent', 'High']);
    expect(params['AssigneeId'], ['user-maya']);
    expect(params['Tag'], ['vip']);
    expect(params['Sort'], ['-priority']);
  });

  test('scrolling loads the next page and drops tickets that moved between pages', () async {
    final api = FakeApi()
      ..routes[tickets] = (request) => request.queryParameters['Page'] == 1
          ? json(200, pageJson([for (var n = 1; n <= 25; n++) ticketJson(n)], total: 30))
          : json(
              200,
              pageJson([ticketJson(25), for (var n = 26; n <= 30; n++) ticketJson(n)], page: 2, total: 30),
            );
    final container = await signedIn(api);
    addTearDown(container.dispose);

    final first = await settle(container, InboxQuery.all);
    expect(first.items, hasLength(25));
    expect(first.hasMore, isTrue);

    await container.read(inboxProvider(InboxQuery.all).notifier).loadMore();
    final second = container.read(inboxProvider(InboxQuery.all));
    expect(second.items.map((t) => t.number), [for (var n = 1; n <= 30; n++) n]);
    expect(second.hasMore, isFalse);
  });

  test('the cached list shows first, and offline it stays with an offline flag', () async {
    final api = FakeApi()..routes[tickets] = (_) => json(200, pageJson([ticketJson(7)]));
    final container = await signedIn(api);
    addTearDown(container.dispose);
    await settle(container, InboxQuery.mine);

    // A new launch with no network: the copy from the cache is shown, marked offline.
    api.routes[tickets] = (request) =>
        throw DioException.connectionError(requestOptions: request, reason: 'offline');
    container.invalidate(inboxProvider(InboxQuery.mine));
    final state = await settle(container, InboxQuery.mine);

    expect(state.items.single.number, 7);
    expect(state.cachedAt, isNotNull);
    expect(state.offline, isTrue);
  });

  test('a failure with nothing cached is an error, not an empty list', () async {
    final api = FakeApi()..routes[tickets] = (_) => problem(500, 'boom');
    final container = await signedIn(api);
    addTearDown(container.dispose);

    final state = await settle(container, InboxQuery.mine);

    expect(state.items, isEmpty);
    expect(state.error?.status, 500);
    expect(state.offline, isFalse);
  });

  test('search drops the status filter and keeps the text', () {
    final query = const InboxQuery().searching('  invoice ');
    expect(query.search, 'invoice');
    expect(query.status, isNull);
    expect(query, const InboxQuery().searching('invoice'));
    expect(InboxQuery.mine == InboxQuery.unassigned, isFalse);
  });
}
