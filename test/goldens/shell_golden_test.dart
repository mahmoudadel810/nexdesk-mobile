import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers.dart';

/// The empty shell in both directions. Text renders as boxes in tests (no real fonts), so these catch layout and
/// mirroring changes, not wording. Update with `flutter test --update-goldens test/goldens`.
void main() {
  for (final language in ['en', 'ar']) {
    testWidgets('sign-in screen, $language', (tester) async {
      await pumpApp(tester, language: language);
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('sign_in_$language.png'));
    });
  }
}
