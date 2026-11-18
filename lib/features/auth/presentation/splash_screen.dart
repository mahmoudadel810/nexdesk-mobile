import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/startup.dart';
import '../../../core/l10n/generated/app_localizations.dart';

/// Shown while the app checks its version and any stored sign-in. After five seconds it explains the wait,
/// because the hosted API sleeps when idle and takes up to a minute to wake.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  Timer? _slow;
  bool _waking = false;

  @override
  void initState() {
    super.initState();
    _slow = Timer(const Duration(seconds: 5), () => setState(() => _waking = true));
    ref.read(startupProvider);
  }

  @override
  void dispose() {
    _slow?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsetsDirectional.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.support_agent, size: 64, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text(l10n.appName, style: theme.textTheme.headlineMedium),
              const SizedBox(height: 32),
              const CircularProgressIndicator(),
              if (_waking) ...[
                const SizedBox(height: 16),
                Text(l10n.wakingServer, textAlign: TextAlign.center),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
