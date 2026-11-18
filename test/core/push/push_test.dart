import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nexdesk_mobile/app/router.dart';
import 'package:nexdesk_mobile/core/auth/session_controller.dart';
import 'package:nexdesk_mobile/core/auth/token_store.dart';
import 'package:nexdesk_mobile/core/push/device_registration.dart';
import 'package:nexdesk_mobile/core/push/push_service.dart';

import '../../fakes.dart';
import '../../features/ticket/ticket_helpers.dart';
import '../../helpers.dart';

/// Push as Firebase would offer it, without Firebase.
class FakePushService implements PushService {
  FakePushService({this.allowed = true, this.initial});

  bool allowed;
  String? initial;
  String currentToken = 'fcm-token-1';
  final _taps = StreamController<String>.broadcast(sync: true);
  final _refreshes = StreamController<String>.broadcast(sync: true);

  void tap(String link) => _taps.add(link);

  void refreshToken(String token) => _refreshes.add(token);

  @override
  bool get available => true;

  @override
  Future<bool> requestPermission() async => allowed;

  @override
  Future<String?> token() async => currentToken;

  @override
  Stream<String> get tokenRefreshes => _refreshes.stream;

  @override
  Stream<String> get taps => _taps.stream;

  @override
  Future<String?> initialTap() async => initial;
}

void main() {
  testWidgets('once signed in, the phone registers its push token with a stable installation id', (
    tester,
  ) async {
    final api = ticketApi(permissions: agent);
    final bodies = <String, Object?>{};
    final push = FakePushService();
    final container = await openTicket(tester, api, overrides: [pushServiceProvider.overrideWithValue(push)]);
    final id = container.read(deviceRegistrationProvider).installationId;
    final put = api.calls.where((c) => c.method == 'PUT' && c.path == '/api/v1/devices/$id').toList();

    expect(put, hasLength(1));
    bodies.addAll(jsonDecode(put.single.data as String) as Map<String, Object?>);
    expect(bodies['pushToken'], 'fcm-token-1');
    expect(bodies['platform'], isNotNull);
    expect(container.read(deviceRegistrationProvider).installationId, id);

    push.refreshToken('fcm-token-2');
    await tester.pumpAndSettle();
    expect(api.calls.where((c) => c.method == 'PUT').length, 2);
  });

  testWidgets('with notifications refused, nothing is registered', (tester) async {
    final api = ticketApi(permissions: agent);
    await openTicket(
      tester,
      api,
      overrides: [pushServiceProvider.overrideWithValue(FakePushService(allowed: false))],
    );

    expect(api.calls.where((c) => c.path.startsWith('/api/v1/devices')), isEmpty);
  });

  testWidgets('a build without push never asks and never registers', (tester) async {
    final api = ticketApi(permissions: agent);
    await openTicket(tester, api);

    expect(api.calls.where((c) => c.path.startsWith('/api/v1/devices')), isEmpty);
  });

  testWidgets('signing out removes the device before the sign-in is revoked', (tester) async {
    final api = ticketApi(permissions: agent);
    api.routes['POST /api/v1/auth/mobile/logout'] = (_) => json(204, {});
    final container = await openTicket(
      tester,
      api,
      overrides: [pushServiceProvider.overrideWithValue(FakePushService())],
    );
    final id = container.read(deviceRegistrationProvider).installationId;

    unawaited(container.read(sessionProvider.notifier).signOut());
    await tester.pumpAndSettle();

    final order = [for (final c in api.calls) '${c.method} ${c.path}'];
    final removed = order.indexOf('DELETE /api/v1/devices/$id');
    expect(removed, isNot(-1));
    expect(removed, lessThan(order.indexOf('POST /api/v1/auth/mobile/logout')));
  });

  testWidgets('tapping a push while the app runs opens its ticket', (tester) async {
    final push = FakePushService();
    final container = await openTicket(
      tester,
      ticketApi(permissions: agent),
      overrides: [pushServiceProvider.overrideWithValue(push)],
    );
    container.read(routerProvider).go(Routes.inbox);
    await tester.pumpAndSettle();

    push.tap('/app/tickets/$ticketId');
    await tester.pumpAndSettle();

    expect(
      container.read(routerProvider).routerDelegate.currentConfiguration.uri.path,
      '/app/tickets/$ticketId',
    );
  });

  testWidgets('a link that arrives on the sign-in screen opens after signing in', (tester) async {
    final api = ticketApi(permissions: agent);
    api.routes['POST /api/v1/auth/mobile/login'] = (_) => json(200, authBody(access: 'a', refresh: 'r'));
    final container = await pumpApp(
      tester,
      api: api,
      overrides: [clockProvider.overrideWithValue(() => now)],
    );
    expect(container.read(routerProvider).routerDelegate.currentConfiguration.uri.path, Routes.signIn);

    container.read(routerProvider).go('/app/tickets/$ticketId');
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('email')), 'maya@brightpath.demo');
    await tester.enterText(find.byKey(const Key('password')), 'pw');
    await tester.tap(find.byKey(const Key('sign-in')));
    await tester.pumpAndSettle();

    expect(
      container.read(routerProvider).routerDelegate.currentConfiguration.uri.path,
      '/app/tickets/$ticketId',
    );
  });

  testWidgets('a push that started the app opens its ticket once signed in', (tester) async {
    final push = FakePushService(initial: '/app/tickets/$ticketId');
    final container = await pumpApp(
      tester,
      api: ticketApi(permissions: agent),
      tokens: MemoryTokenStore('r1'),
      overrides: [clockProvider.overrideWithValue(() => now), pushServiceProvider.overrideWithValue(push)],
    );
    await tester.pumpAndSettle();

    expect(
      container.read(routerProvider).routerDelegate.currentConfiguration.uri.path,
      '/app/tickets/$ticketId',
    );
  });
}
