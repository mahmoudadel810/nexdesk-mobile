import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api/api.dart';
import 'app.dart';
import 'config.dart';
import 'preferences.dart';
import 'startup.dart';

Future<void> bootstrap(AppConfig config) async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  final package = await PackageInfo.fromPlatform();
  runApp(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(config),
        sharedPreferencesProvider.overrideWithValue(preferences),
        buildNumberProvider.overrideWithValue(int.tryParse(package.buildNumber) ?? 1),
        clientHeaderProvider.overrideWithValue(clientHeader(package.version, package.buildNumber)),
      ],
      child: const NexDeskApp(),
    ),
  );
}
