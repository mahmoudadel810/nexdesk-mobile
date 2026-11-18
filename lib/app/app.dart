import 'package:cupertino_ui/cupertino_ui.dart' show GlobalCupertinoLocalizations;
import 'package:flutter_localizations/flutter_localizations.dart' show GlobalWidgetsLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../core/l10n/generated/app_localizations.dart';
import 'lock_gate.dart';
import 'preferences.dart';
import 'push_routing.dart';
import 'router.dart';
import 'startup.dart';
import 'theme.dart';

class NexDeskApp extends ConsumerWidget {
  const NexDeskApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(accountEffectsProvider);
    ref.watch(pushRoutingProvider);
    final language = ref.watch(languageProvider);
    final seed = ref.watch(brandColorProvider) ?? nexDeskSeed;
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appName,
      debugShowCheckedModeBanner: false,
      routerConfig: ref.watch(routerProvider),
      builder: (_, child) => LockGate(child: child ?? const SizedBox.shrink()),
      theme: buildTheme(seed, Brightness.light),
      darkTheme: buildTheme(seed, Brightness.dark),
      themeMode: ref.watch(themeModeProvider),
      // Null follows the device; Directionality flips with the locale, with no restart.
      locale: language == null ? null : Locale(language),
      supportedLocales: AppLocalizations.supportedLocales,
      // Flutter 3.50 moved the Material and Cupertino strings into their own packages; the delegates the l10n
      // generator lists still point at the old ones, which leave Arabic without them.
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
    );
  }
}
