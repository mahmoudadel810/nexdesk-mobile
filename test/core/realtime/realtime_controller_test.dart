import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexdesk_mobile/core/auth/session.dart';
import 'package:nexdesk_mobile/core/auth/session_controller.dart';
import 'package:nexdesk_mobile/core/auth/token_store.dart';
import 'package:nexdesk_mobile/core/realtime/live_hub.dart';
import 'package:nexdesk_mobile/core/realtime/realtime_controller.dart';

import '../../fakes.dart';

/// A signed-in container with the realtime controller running, all on a fake clock.
(ProviderContainer, FakeLiveHub) signedIn(FakeAsync async, {bool connects = true}) {
  final api = FakeApi();
  api.routes['POST /api/v1/auth/mobile/refresh'] = (_) => json(200, authBody(access: 'a', refresh: 'r2'));
  api.routes['POST /api/v1/auth/mobile/logout'] = (_) => json(204, {});
  final hub = FakeLiveHub()..connects = connects;
  final container = fakeContainer(api, tokens: MemoryTokenStore('r1'), hub: hub);
  container.read(sessionProvider.notifier).restore();
  // Signing in goes through Dio, which needs its timers to run; the realtime controller does not exist yet.
  async.elapse(const Duration(seconds: 1));
  expect(container.read(sessionProvider), isA<SignedIn>());
  container.listen(realtimeProvider, (_, _) {});
  async.flushMicrotasks();
  return (container, hub);
}

void main() {
  test('connects once when someone is signed in and the app is open', () {
    fakeAsync((async) {
      final (container, hub) = signedIn(async);

      expect(hub.starts, 1);
      expect(container.read(realtimeProvider), LiveStatus.connected);
      container.dispose();
    });
  });

  test('closes 30 seconds after the app leaves the screen, and opens again on return', () {
    fakeAsync((async) {
      final (container, hub) = signedIn(async);
      final live = container.read(realtimeProvider.notifier);

      live.appPaused();
      async.elapse(const Duration(seconds: 29));
      expect(hub.stops, 0);
      async.elapse(const Duration(seconds: 1));
      expect(hub.stops, 1);
      expect(container.read(realtimeProvider), LiveStatus.off);

      live.appResumed();
      async.flushMicrotasks();
      expect(hub.starts, 2);
      expect(container.read(realtimeProvider), LiveStatus.connected);
      container.dispose();
    });
  });

  test('a quick trip away keeps the connection', () {
    fakeAsync((async) {
      final (container, hub) = signedIn(async);
      final live = container.read(realtimeProvider.notifier);

      live.appPaused();
      async.elapse(const Duration(seconds: 10));
      live.appResumed();
      async.elapse(const Duration(minutes: 2));

      expect(hub.stops, 0);
      expect(hub.starts, 1);
      container.dispose();
    });
  });

  test('a first connect that fails is retried with growing waits until it works', () {
    fakeAsync((async) {
      final (container, hub) = signedIn(async, connects: false);
      expect(hub.starts, 1);
      expect(container.read(realtimeProvider), LiveStatus.connecting);

      async.elapse(Duration.zero);
      expect(hub.starts, 2);
      async.elapse(const Duration(seconds: 2));
      expect(hub.starts, 3);
      async.elapse(const Duration(seconds: 4));
      expect(hub.starts, 3, reason: 'the third wait is 5 seconds');
      hub.connects = true;
      async.elapse(const Duration(seconds: 1));

      expect(hub.starts, 4);
      expect(container.read(realtimeProvider), LiveStatus.connected);
      container.dispose();
    });
  });

  test('a dropped connection shows as reconnecting until the library is back', () {
    fakeAsync((async) {
      final (container, hub) = signedIn(async);

      hub.emit(const LiveDisconnected());
      expect(container.read(realtimeProvider), LiveStatus.connecting);
      hub.emit(const LiveConnected());
      expect(container.read(realtimeProvider), LiveStatus.connected);
      container.dispose();
    });
  });

  test('a drop while in the background ends the connection instead of retrying, and return reconnects', () {
    fakeAsync((async) {
      final (container, hub) = signedIn(async);
      final live = container.read(realtimeProvider.notifier);

      live.appPaused();
      async.elapse(const Duration(seconds: 6));
      hub.emit(const LiveDisconnected());
      expect(container.read(realtimeProvider), LiveStatus.off);
      expect(hub.stops, 1);

      async.elapse(const Duration(minutes: 1));
      live.appResumed();
      async.flushMicrotasks();
      expect(hub.starts, 2);
      expect(container.read(realtimeProvider), LiveStatus.connected);
      container.dispose();
    });
  });

  test('signing out closes the connection', () {
    fakeAsync((async) {
      final (container, hub) = signedIn(async);

      container.read(sessionProvider.notifier).signOut();
      async.elapse(const Duration(seconds: 1));

      expect(hub.stops, 1);
      expect(container.read(realtimeProvider), LiveStatus.off);
      container.dispose();
    });
  });
}
