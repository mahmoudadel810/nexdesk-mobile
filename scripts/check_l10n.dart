// Fails when the English and Arabic message files do not have the same keys.
import 'dart:convert';
import 'dart:io';

void main() {
  Set<String> keys(String path) => (jsonDecode(File(path).readAsStringSync()) as Map<String, Object?>).keys
      .where((key) => !key.startsWith('@'))
      .toSet();

  final english = keys('lib/core/l10n/app_en.arb');
  final arabic = keys('lib/core/l10n/app_ar.arb');
  final missingInArabic = english.difference(arabic);
  final missingInEnglish = arabic.difference(english);
  if (missingInArabic.isEmpty && missingInEnglish.isEmpty) {
    stdout.writeln('Localizations: ${english.length} keys in both languages.');
    return;
  }

  if (missingInArabic.isNotEmpty) stderr.writeln('Missing in app_ar.arb: ${missingInArabic.join(', ')}');
  if (missingInEnglish.isNotEmpty) stderr.writeln('Missing in app_en.arb: ${missingInEnglish.join(', ')}');
  exit(1);
}
