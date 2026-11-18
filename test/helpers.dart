import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nexdesk_mobile/app/app.dart';
import 'package:nexdesk_mobile/app/preferences.dart';
import 'package:nexdesk_mobile/core/auth/token_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

/// Pumps the whole app against a fake API, with in-memory preferences and secure storage. Without a stored
/// token it settles on the sign-in screen.
Future<ProviderContainer> pumpApp(
  WidgetTester tester, {
  String? language,
  FakeApi? api,
  MemoryTokenStore? tokens,
  Size size = const Size(400, 860),
}) async {
  SharedPreferences.setMockInitialValues({'nexdesk.language': ?language});
  final preferences = await SharedPreferences.getInstance();
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final fake = api ?? FakeApi();
  fake.routes.putIfAbsent(
    'GET /api/v1/mobile/config',
    () =>
        (_) => json(200, {
          'minimumBuild': {'android': 1, 'ios': 1},
          'webBaseUrl': 'https://web.test',
        }),
  );
  final container = fakeContainer(
    fake,
    tokens: tokens,
    extra: [sharedPreferencesProvider.overrideWithValue(preferences)],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const NexDeskApp()));
  await tester.pumpAndSettle();
  return container;
}
