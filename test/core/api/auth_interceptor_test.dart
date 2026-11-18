import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexdesk_mobile/core/api/api.dart';
import 'package:nexdesk_mobile/core/auth/session.dart';
import 'package:nexdesk_mobile/core/auth/session_controller.dart';
import 'package:nexdesk_mobile/core/auth/token_store.dart';

import '../../fakes.dart';

void main() {
  late FakeApi api;
  late MemoryTokenStore tokens;

  setUp(() {
    api = FakeApi();
    tokens = MemoryTokenStore();
    api.routes['POST /api/v1/auth/mobile/login'] = (_) => json(200, authBody(access: 'old', refresh: 'r1'));
  });

  test('sends the bearer token', () async {
    api.routes['GET /api/v1/auth/me'] = (request) => json(200, {'auth': request.headers['Authorization']});
    final container = fakeContainer(api, tokens: tokens);
    addTearDown(container.dispose);
    await container.read(sessionProvider.notifier).signIn('maya@brightpath.demo', 'pw');

    final response = await container.read(dioProvider).get<Map<String, Object?>>('/api/v1/auth/me');

    expect(response.data!['auth'], 'Bearer old');
  });

  test('a 401 refreshes once and replays the request with the new token', () async {
    api.routes['POST /api/v1/auth/mobile/refresh'] = (_) => json(200, authBody(access: 'new', refresh: 'r2'));
    api.routes['GET /api/v1/tickets'] = (request) => request.headers['Authorization'] == 'Bearer new'
        ? json(200, {'ok': true})
        : json(401, {'title': 'Unauthorized', 'status': 401});
    final container = fakeContainer(api, tokens: tokens);
    addTearDown(container.dispose);
    await container.read(sessionProvider.notifier).signIn('maya@brightpath.demo', 'pw');

    final response = await container.read(dioProvider).get<Map<String, Object?>>('/api/v1/tickets');

    expect(response.data, {'ok': true});
    expect(api.count('POST /api/v1/auth/mobile/refresh'), 1);
    expect(tokens.value, 'r2');
  });

  test('a second 401 after refreshing signs the phone out', () async {
    api.routes['POST /api/v1/auth/mobile/refresh'] = (_) => json(200, authBody(access: 'new', refresh: 'r2'));
    api.routes['POST /api/v1/auth/mobile/logout'] = (_) => json(204, '');
    api.routes['GET /api/v1/tickets'] = (_) => json(401, {'title': 'Unauthorized', 'status': 401});
    final container = fakeContainer(api, tokens: tokens);
    addTearDown(container.dispose);
    await container.read(sessionProvider.notifier).signIn('maya@brightpath.demo', 'pw');

    await expectLater(
      container.read(dioProvider).get<Object?>('/api/v1/tickets'),
      throwsA(isA<DioException>()),
    );

    expect(container.read(sessionProvider), isA<SignedOut>());
    expect(tokens.value, isNull);
  });

  test('a throttled read waits and tries again once; a throttled write does not', () async {
    var reads = 0;
    api.routes['GET /api/v1/tickets'] = (_) => ++reads == 1
        ? json(
            429,
            {'title': 'Too many', 'status': 429, 'code': 'too-many-requests'},
            headers: {
              'retry-after': ['0'],
            },
          )
        : json(200, {'ok': true});
    api.routes['POST /api/v1/tickets'] = (_) => json(429, {'title': 'Too many', 'status': 429});
    final container = fakeContainer(api, tokens: tokens);
    addTearDown(container.dispose);
    await container.read(sessionProvider.notifier).signIn('maya@brightpath.demo', 'pw');

    expect((await container.read(dioProvider).get<Map<String, Object?>>('/api/v1/tickets')).data, {
      'ok': true,
    });
    await expectLater(
      container.read(dioProvider).post<Object?>('/api/v1/tickets'),
      throwsA(isA<DioException>()),
    );
    expect(api.count('POST /api/v1/tickets'), 1);
  });

  test('client header format', () {
    expect(clientHeader('1.0.0', '7'), matches(RegExp(r'^mobile/1\.0\.0\+7 \(\w+\)$')));
    expect(const Blocked(BlockedReason.updateRequired).reason, BlockedReason.updateRequired);
  });
}
