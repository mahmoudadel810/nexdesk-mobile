import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nexdesk_mobile/app/router.dart';

import '../../fakes.dart';
import '../ticket/ticket_helpers.dart';

FakeApi profileApi() {
  final api = ticketApi(permissions: agent);
  final me = {
    'id': 'user-maya',
    'email': 'maya@brightpath.demo',
    'fullName': 'Maya Chen',
    'role': 'Agent',
    'isActive': true,
    'availability': 'Online',
    'emailVerified': true,
    'lastLoginAt': null,
    'createdAt': now.toIso8601String(),
  };
  api.routes['GET /api/v1/users/user-maya'] = (_) => json(200, me);
  api.routes['PUT /api/v1/users/me/availability'] = (request) {
    me['availability'] = (jsonDecode(request.data as String) as Map)['availability'];
    return json(200, me);
  };
  api.routes['PUT /api/v1/users/me/profile'] = (request) {
    final language = (jsonDecode(request.data as String) as Map)['language'] as String;
    return json(200, authBody(access: 'a', refresh: 'r', language: language)['session']!);
  };
  return api;
}

void main() {
  testWidgets('switching to Arabic saves it on the account and flips the whole app at once', (tester) async {
    final api = profileApi();
    final container = await openTicket(tester, api);
    container.read(routerProvider).go(Routes.profile);
    await tester.pumpAndSettle();

    await tester.tap(find.text('العربية'));
    await tester.pumpAndSettle();

    final saved = api.calls.singleWhere((c) => c.method == 'PUT' && c.path == '/api/v1/users/me/profile');
    expect((jsonDecode(saved.data as String) as Map)['language'], 'ar');
    expect(Directionality.of(tester.element(find.byKey(const Key('language')))), TextDirection.rtl);
    expect(find.text('الملف الشخصي'), findsWidgets);
  });

  testWidgets('availability is shown from the account and changed with one tap', (tester) async {
    final api = profileApi();
    final container = await openTicket(tester, api);
    container.read(routerProvider).go(Routes.profile);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Away'));
    await tester.pumpAndSettle();

    final sent = api.calls.singleWhere((c) => c.method == 'PUT' && c.path == '/api/v1/users/me/availability');
    expect((jsonDecode(sent.data as String) as Map)['availability'], 'Away');
  });

  testWidgets('About shows the version', (tester) async {
    final container = await openTicket(tester, profileApi());
    container.read(routerProvider).go(Routes.about);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('app-version')), findsOneWidget);
  });
}
