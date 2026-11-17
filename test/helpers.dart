import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nexdesk_mobile/app/app.dart';
import 'package:nexdesk_mobile/app/preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pumps the whole app with in-memory preferences, optionally with a language already picked.
Future<ProviderContainer> pumpApp(
  WidgetTester tester, {
  String? language,
  Size size = const Size(400, 860),
}) async {
  SharedPreferences.setMockInitialValues({'nexdesk.language': ?language});
  final preferences = await SharedPreferences.getInstance();
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final container = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(preferences)]);
  addTearDown(container.dispose);
  await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const NexDeskApp()));
  await tester.pumpAndSettle();
  return container;
}
