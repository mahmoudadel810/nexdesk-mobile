import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' hide LockState;
import 'package:nexdesk_mobile/app/router.dart';
import 'package:nexdesk_mobile/core/auth/session_controller.dart';
import 'package:nexdesk_mobile/core/auth/token_store.dart';
import 'package:nexdesk_mobile/core/lock/app_lock.dart';

import '../../features/ticket/ticket_helpers.dart';
import '../../helpers.dart';

/// Says yes or no instead of asking for a fingerprint, and counts the asks.
class FakeBiometrics implements Biometrics {
  FakeBiometrics({this.answer = true});

  bool answer;
  int asked = 0;

  @override
  Future<bool> available() async => true;

  @override
  Future<bool> confirm(String reason) async {
    asked++;
    return answer;
  }
}

void main() {
  late DateTime clock;

  setUp(() => clock = DateTime.utc(2026, 11, 18, 12));

  Future<(FakeBiometrics, ProviderContainer)> open(WidgetTester tester) async {
    final biometrics = FakeBiometrics();
    final container = await pumpApp(
      tester,
      api: ticketApi(permissions: agent),
      tokens: MemoryTokenStore('r1'),
      overrides: [
        biometricsProvider.overrideWithValue(biometrics),
        clockProvider.overrideWithValue(() => clock),
      ],
    );
    container.read(routerProvider).go('/app/tickets/$ticketId');
    await tester.pumpAndSettle();
    return (biometrics, container);
  }

  Future<void> lifecycle(WidgetTester tester, AppLifecycleState state) async {
    tester.binding.handleAppLifecycleStateChanged(state);
    await tester.pump();
  }

  testWidgets('leaving the app covers its content, so the app switcher shows no tickets', (tester) async {
    await open(tester);

    await lifecycle(tester, AppLifecycleState.inactive);
    expect(find.byKey(const Key('privacy-cover')), findsOneWidget);

    await lifecycle(tester, AppLifecycleState.resumed);
    expect(find.byKey(const Key('privacy-cover')), findsNothing);
  });

  testWidgets('turning the lock on asks for the fingerprint first, and a refusal leaves it off', (
    tester,
  ) async {
    final (biometrics, container) = await open(tester);
    final lock = container.read(appLockProvider.notifier);

    biometrics.answer = false;
    expect(await lock.setEnabled(true, 'unlock'), isFalse);
    expect(container.read(appLockProvider).enabled, isFalse);

    biometrics.answer = true;
    expect(await lock.setEnabled(true, 'unlock'), isTrue);
    expect(container.read(appLockProvider).enabled, isTrue);
  });

  testWidgets('with the lock on, a short trip away stays open and five minutes away asks again', (
    tester,
  ) async {
    final (biometrics, container) = await open(tester);
    await container.read(appLockProvider.notifier).setEnabled(true, 'unlock');
    final asksAfterEnabling = biometrics.asked;

    await lifecycle(tester, AppLifecycleState.inactive);
    clock = clock.add(const Duration(minutes: 4));
    await lifecycle(tester, AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('lock-screen')), findsNothing);

    await lifecycle(tester, AppLifecycleState.inactive);
    clock = clock.add(const Duration(minutes: 5));
    biometrics.answer = false;
    await lifecycle(tester, AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('lock-screen')), findsOneWidget);
    expect(biometrics.asked, asksAfterEnabling + 1, reason: 'the fingerprint prompt opens by itself');

    biometrics.answer = true;
    await tester.tap(find.byKey(const Key('unlock')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('lock-screen')), findsNothing);
  });
}
