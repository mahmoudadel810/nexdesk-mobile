import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Overridden in bootstrap with the loaded instance.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw StateError('sharedPreferencesProvider must be overridden'),
);

const supportedLanguages = ['en', 'ar'];

/// The language the person picked on this phone, or null to follow the device. Once signed in, the account's
/// language takes over (16.5).
class LanguageController extends Notifier<String?> {
  static const _key = 'nexdesk.language';

  @override
  String? build() {
    final stored = ref.watch(sharedPreferencesProvider).getString(_key);
    return supportedLanguages.contains(stored) ? stored : null;
  }

  Future<void> set(String? language) async {
    final preferences = ref.read(sharedPreferencesProvider);
    if (language == null) {
      await preferences.remove(_key);
    } else {
      await preferences.setString(_key, language);
    }
    state = language;
  }
}

final languageProvider = NotifierProvider<LanguageController, String?>(LanguageController.new);

/// Light, dark or follow the system (the default).
class ThemeModeController extends Notifier<ThemeMode> {
  static const _key = 'nexdesk.theme';

  @override
  ThemeMode build() => switch (ref.watch(sharedPreferencesProvider).getString(_key)) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };

  Future<void> set(ThemeMode mode) async {
    await ref.read(sharedPreferencesProvider).setString(_key, mode.name);
    state = mode;
  }
}

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);
