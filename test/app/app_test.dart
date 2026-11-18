import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nexdesk_mobile/app/router.dart';
import 'package:nexdesk_mobile/app/startup.dart';
import 'package:nexdesk_mobile/app/theme.dart';
import 'package:nexdesk_mobile/core/auth/session.dart';
import 'package:nexdesk_mobile/core/auth/session_controller.dart';
import 'package:nexdesk_mobile/core/auth/token_store.dart';

import '../fakes.dart';
import '../helpers.dart';

const login = 'POST /api/v1/auth/mobile/login';

FakeApi _apiWithBrand() => FakeApi()
  ..routes['GET /api/v1/portal/brightpath'] = ((_) => json(200, {
    'name': 'BrightPath Software',
    'slug': 'brightpath',
    'defaultLanguage': 'en',
    'brandColor': '#1e6091',
  }));

String _path(ProviderContainer container) =>
    container.read(routerProvider).routerDelegate.currentConfiguration.uri.path;

Future<void> _signIn(WidgetTester tester, String email, String password) async {
  await tester.enterText(find.byKey(const Key('email')), email);
  await tester.enterText(find.byKey(const Key('password')), password);
  await tester.tap(find.byKey(const Key('sign-in')));
  await tester.pumpAndSettle();
}

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
  });

  testWidgets('the email field stays left to right inside the Arabic layout', (tester) async {
    await pumpApp(tester, language: 'ar');

    final email = tester.widget<EditableText>(
      find.descendant(of: find.byKey(const Key('email')), matching: find.byType(EditableText)),
    );
    expect(email.textDirection, TextDirection.ltr);
  });

  testWidgets('the form checks the fields before calling the API', (tester) async {
    final api = FakeApi();
    await pumpApp(tester, language: 'en', api: api);

    await _signIn(tester, 'not-an-email', '');

    expect(find.text('Enter a valid email address.'), findsOneWidget);
    expect(find.text('Enter your password.'), findsOneWidget);
    expect(api.count(login), 0);
  });

  testWidgets('a wrong password shows the API reason under the form', (tester) async {
    final api = FakeApi()..routes[login] = (_) => problem(401, 'invalid-credentials');
    await pumpApp(tester, language: 'en', api: api);

    await _signIn(tester, 'maya@brightpath.demo', 'wrong');

    expect(find.text('The email or password is incorrect.'), findsOneWidget);
  });

  testWidgets('a locked account says to wait, in Arabic too', (tester) async {
    final api = FakeApi()..routes[login] = (_) => problem(403, 'account-locked');
    await pumpApp(tester, language: 'ar', api: api);

    await _signIn(tester, 'maya@brightpath.demo', 'x');

    expect(find.text('محاولات كثيرة. حاول مرة أخرى بعد دقائق.'), findsOneWidget);
  });

  testWidgets('signing in lands on the inbox in the workspace colour and the account language', (
    tester,
  ) async {
    final api = _apiWithBrand()
      ..routes[login] = (_) => json(200, authBody(access: 'a', refresh: 'r', language: 'ar'));
    final container = await pumpApp(tester, language: 'en', api: api);

    await _signIn(tester, 'maya@brightpath.demo', 'pw');

    expect(_path(container), Routes.inbox);
    expect(find.byKey(const Key('greeting')), findsOneWidget);
    expect(container.read(brandColorProvider), const Color(0xFF1E6091));
    expect(Directionality.of(tester.element(find.byKey(const Key('greeting')))), TextDirection.rtl);
  });

  testWidgets('a stored sign-in survives a relaunch', (tester) async {
    final api = _apiWithBrand()
      ..routes['POST /api/v1/auth/mobile/refresh'] = (_) => json(200, authBody(access: 'a2', refresh: 'r2'));
    final tokens = MemoryTokenStore('r1');
    final container = await pumpApp(tester, language: 'en', api: api, tokens: tokens);

    expect(_path(container), Routes.inbox);
    expect(tokens.value, 'r2');
  });

  testWidgets('a suspended workspace shows the blocked screen with a way back', (tester) async {
    final api = FakeApi()..routes[login] = (_) => json(200, authBody(access: 'a', refresh: 'r'));
    api.routes['POST /api/v1/auth/mobile/refresh'] = (_) => problem(403, 'tenant-suspended');
    final tokens = MemoryTokenStore('r1');
    final container = await pumpApp(tester, language: 'en', api: api, tokens: tokens);

    expect(_path(container), Routes.blocked);
    expect(find.text('This workspace is suspended'), findsOneWidget);
    await tester.tap(find.text('Sign in with another account'));
    await tester.pumpAndSettle();
    expect(_path(container), Routes.signIn);
  });

  testWidgets('an app older than the minimum build asks for an update', (tester) async {
    final api = FakeApi()
      ..routes['GET /api/v1/mobile/config'] = (_) => json(200, {
        'minimumBuild': {'android': 99, 'ios': 99},
        'webBaseUrl': 'https://web.test',
      });
    final container = await pumpApp(tester, language: 'en', api: api);

    expect(container.read(sessionProvider), isA<Blocked>());
    expect(find.text('Update NexDesk'), findsOneWidget);
    expect(container.read(webBaseUrlProvider), 'https://web.test');
  });

  testWidgets('signing out from the profile goes back to sign-in and forgets everything', (tester) async {
    final api = _apiWithBrand();
    api.routes[login] = (_) => json(200, authBody(access: 'a', refresh: 'r'));
    api.routes['POST /api/v1/auth/mobile/logout'] = (_) => json(204, '');
    final tokens = MemoryTokenStore();
    final container = await pumpApp(tester, language: 'en', api: api, tokens: tokens);
    await _signIn(tester, 'maya@brightpath.demo', 'pw');

    await tester.tap(find.text('Profile').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('sign-out')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign out').last);
    await tester.pumpAndSettle();

    expect(_path(container), Routes.signIn);
    expect(tokens.value, isNull);
    expect(container.read(brandColorProvider), isNull);
    expect(container.read(sessionProvider), isA<SignedOut>());
  });

  testWidgets('the shell has a bottom bar on phones and a rail on tablets', (tester) async {
    final api = _apiWithBrand()..routes[login] = (_) => json(200, authBody(access: 'a', refresh: 'r'));
    await pumpApp(tester, language: 'en', api: api);
    await _signIn(tester, 'maya@brightpath.demo', 'pw');
    expect(find.byType(NavigationBar), findsOneWidget);

    tester.view.physicalSize = const Size(1000, 800);
    await tester.pumpAndSettle();
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  test('blocked reasons cover every way in', () {
    expect(BlockedReason.values, hasLength(4));
  });
}
