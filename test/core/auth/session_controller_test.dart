import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nexdesk_mobile/core/auth/session.dart';
import 'package:nexdesk_mobile/core/auth/session_controller.dart';
import 'package:nexdesk_mobile/core/auth/token_store.dart';
import 'package:nexdesk_mobile/core/cache/database.dart';
import 'package:nexdesk_mobile/core/errors/app_error.dart';

import '../../fakes.dart';

const login = 'POST /api/v1/auth/mobile/login';
const refresh = 'POST /api/v1/auth/mobile/refresh';
const logout = 'POST /api/v1/auth/mobile/logout';

void main() {
  late FakeApi api;
  late MemoryTokenStore tokens;

  setUp(() {
    api = FakeApi();
    tokens = MemoryTokenStore();
  });

  test('signing in keeps the refresh token in secure storage and the access token in memory', () async {
    api.routes[login] = (_) => json(200, authBody(access: 'access-1', refresh: 'refresh-1'));
    final container = fakeContainer(api, tokens: tokens);
    addTearDown(container.dispose);

    await container.read(sessionProvider.notifier).signIn(' maya@brightpath.demo ', 'pw');

    expect(tokens.value, 'refresh-1');
    final state = container.read(sessionProvider);
    expect(state, isA<SignedIn>());
    expect((state as SignedIn).session.accessToken, 'access-1');
    final body = jsonDecode(api.calls.single.data as String) as Map<String, Object?>;
    expect(body['email'], 'maya@brightpath.demo');
  });

  test('a wrong password throws the API code and stores nothing', () async {
    api.routes[login] = (_) => problem(401, ErrorCodes.invalidCredentials);
    final container = fakeContainer(api, tokens: tokens);
    addTearDown(container.dispose);

    await expectLater(
      container.read(sessionProvider.notifier).signIn('maya@brightpath.demo', 'nope'),
      throwsA(isA<AppError>().having((e) => e.code, 'code', ErrorCodes.invalidCredentials)),
    );
    expect(tokens.value, isNull);
  });

  test('a platform admin is turned away and their new sign-in is revoked', () async {
    api.routes[login] = (_) =>
        json(200, authBody(access: 'a', refresh: 'admin-refresh', platformAdmin: true));
    api.routes[logout] = (_) => json(204, '');
    final container = fakeContainer(api, tokens: tokens);
    addTearDown(container.dispose);

    await container.read(sessionProvider.notifier).signIn('admin@nexdesk.demo', 'pw');

    expect(container.read(sessionProvider), isA<Blocked>());
    expect((container.read(sessionProvider) as Blocked).reason, BlockedReason.platformAdmin);
    expect(tokens.value, isNull);
    expect(jsonDecode(api.calls.last.data as String), {'refreshToken': 'admin-refresh'});
  });

  test('ten requests with an expiring token cause exactly one refresh', () async {
    tokens.value = 'refresh-0';
    final gate = Completer<void>();
    api.routes[refresh] = (_) async {
      await gate.future;
      return json(200, authBody(access: 'access-2', refresh: 'refresh-2'));
    };
    final container = fakeContainer(api, tokens: tokens);
    addTearDown(container.dispose);
    final session = container.read(sessionProvider.notifier);

    final pending = [for (var i = 0; i < 10; i++) session.accessToken()];
    gate.complete();
    final results = await Future.wait(pending);

    expect(api.count(refresh), 1);
    expect(results, everyElement('access-2'));
    expect(tokens.value, 'refresh-2');
  });

  test('a token far from expiry is used without refreshing', () async {
    api.routes[login] = (_) => json(200, authBody(access: 'fresh', refresh: 'r'));
    final container = fakeContainer(api, tokens: tokens);
    addTearDown(container.dispose);
    await container.read(sessionProvider.notifier).signIn('maya@brightpath.demo', 'pw');

    expect(await container.read(sessionProvider.notifier).accessToken(), 'fresh');
    expect(api.count(refresh), 0);
  });

  test('the new refresh token is saved before the new session is used', () async {
    tokens.value = 'refresh-0';
    api.routes[refresh] = (_) => json(200, authBody(access: 'access-2', refresh: 'refresh-2'));
    final container = fakeContainer(api, tokens: tokens);
    addTearDown(container.dispose);
    String? storedWhenSignedIn;
    container.listen(sessionProvider, (_, next) {
      if (next is SignedIn) storedWhenSignedIn = tokens.value;
    });

    await container.read(sessionProvider.notifier).refresh();

    expect(storedWhenSignedIn, 'refresh-2');
  });

  test('an ended session signs out quietly and wipes the phone', () async {
    tokens.value = 'stolen-or-expired';
    api.routes[refresh] = (_) => problem(401, ErrorCodes.invalidRefreshToken);
    final container = fakeContainer(api, tokens: tokens);
    addTearDown(container.dispose);
    final database = container.read(databaseProvider);
    await database.put('session', '{}', DateTime.now());

    await container.read(sessionProvider.notifier).restore();

    final state = container.read(sessionProvider);
    expect(state, isA<SignedOut>());
    expect((state as SignedOut).reason, SignedOutReason.sessionEnded);
    expect(tokens.value, isNull);
    expect(await database.read('session'), isNull);
  });

  for (final (code, reason) in [
    (ErrorCodes.tenantSuspended, BlockedReason.tenantSuspended),
    (ErrorCodes.accountDisabled, BlockedReason.accountDisabled),
  ]) {
    test('$code on refresh blocks the app', () async {
      tokens.value = 'refresh-0';
      api.routes[refresh] = (_) => problem(403, code);
      final container = fakeContainer(api, tokens: tokens);
      addTearDown(container.dispose);

      await container.read(sessionProvider.notifier).restore();

      expect((container.read(sessionProvider) as Blocked).reason, reason);
      expect(tokens.value, isNull);
    });
  }

  test('being offline at launch keeps the stored sign-in for later', () async {
    tokens.value = 'refresh-0';
    api.routes[refresh] = (request) => throw Exception('no network');
    final container = fakeContainer(api, tokens: tokens);
    addTearDown(container.dispose);

    await container.read(sessionProvider.notifier).restore();

    expect(container.read(sessionProvider), isA<SignedOut>());
    expect(tokens.value, 'refresh-0');
  });

  test('without a stored token the app starts signed out', () async {
    final container = fakeContainer(api, tokens: tokens);
    addTearDown(container.dispose);

    await container.read(sessionProvider.notifier).restore();

    expect(container.read(sessionProvider), isA<SignedOut>());
    expect(api.calls, isEmpty);
  });

  test('signing out revokes the sign-in and leaves nothing behind, even offline', () async {
    api.routes[login] = (_) => json(200, authBody(access: 'a', refresh: 'refresh-1'));
    api.routes[logout] = (_) => throw Exception('offline');
    final container = fakeContainer(api, tokens: tokens);
    addTearDown(container.dispose);
    final database = container.read(databaseProvider);
    await container.read(sessionProvider.notifier).signIn('maya@brightpath.demo', 'pw');
    await database.put('tickets', '[]', DateTime.now());

    await container.read(sessionProvider.notifier).signOut();

    expect(api.count(logout), 1);
    expect(tokens.value, isNull);
    expect(await database.read('tickets'), isNull);
    expect(container.read(sessionProvider), isA<SignedOut>());
  });
}
