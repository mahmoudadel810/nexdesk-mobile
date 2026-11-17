import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nexdesk_mobile/app/router.dart';

import '../helpers.dart';

void main() {
  testWidgets('opens on sign-in, left to right in English', (tester) async {
    await pumpApp(tester, language: 'en');

    expect(find.text('Sign in to your workspace'), findsOneWidget);
    expect(Directionality.of(tester.element(find.byKey(const Key('email')))), TextDirection.ltr);
  });

  testWidgets('switching to Arabic flips the layout without a restart', (tester) async {
    await pumpApp(tester, language: 'en');

    await tester.tap(find.byKey(const Key('language-toggle')));
    await tester.pumpAndSettle();

    expect(find.text('سجّل الدخول إلى مساحة عملك'), findsOneWidget);
    expect(Directionality.of(tester.element(find.byKey(const Key('password')))), TextDirection.rtl);
    // The sign-in button sits on the start side, which is now the right.
    final button = tester.getRect(find.byKey(const Key('sign-in')));
    final field = tester.getRect(find.byKey(const Key('password')));
    expect(button.right, closeTo(field.right, 0.5));
  });

  testWidgets('the email field stays left to right inside the Arabic layout', (tester) async {
    await pumpApp(tester, language: 'ar');

    final email = tester.widget<TextField>(find.byKey(const Key('email')));
    expect(email.textDirection, TextDirection.ltr);
  });

  testWidgets('the shell has a bottom bar on phones and a rail on tablets', (tester) async {
    final container = await pumpApp(tester, language: 'en');
    container.read(routerProvider).go(Routes.inbox);
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);

    await tester.tap(find.text('Notifications').last);
    await tester.pumpAndSettle();
    expect(container.read(routerProvider).routerDelegate.currentConfiguration.uri.path, Routes.notifications);

    tester.view.physicalSize = const Size(1000, 800);
    await tester.pumpAndSettle();
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  test('routes mirror the web app paths', () {
    expect(Routes.inbox, '/app/tickets');
    expect(Routes.notifications, '/app/notifications');
    expect(Routes.profile, '/app/profile');
  });
}
