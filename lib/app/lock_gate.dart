import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../core/l10n/generated/app_localizations.dart';
import '../core/lock/app_lock.dart';

/// Covers the app while it is out of view (so the app switcher shows no ticket content) and shows the lock
/// screen when the app lock asks for a fingerprint.
class LockGate extends ConsumerStatefulWidget {
  const LockGate({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<LockGate> createState() => _LockGateState();
}

class _LockGateState extends ConsumerState<LockGate> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onInactive: () => ref.read(appLockProvider.notifier).appHidden(),
      onResume: () => ref.read(appLockProvider.notifier).appShown(),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lock = ref.watch(appLockProvider);
    ref.listen(appLockProvider.select((s) => s.locked && !s.obscured), (was, now) {
      if (now && !(was ?? false)) unawaited(_unlock());
    });
    return Stack(
      children: [widget.child, if (lock.locked) const _LockScreen() else if (lock.obscured) const _Cover()],
    );
  }

  Future<void> _unlock() async {
    if (!mounted) return;
    await ref.read(appLockProvider.notifier).unlock(AppLocalizations.of(context).unlockReason);
  }
}

class _Cover extends StatelessWidget {
  const _Cover();

  @override
  Widget build(BuildContext context) => Positioned.fill(
    key: const Key('privacy-cover'),
    child: ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: Center(child: Icon(Icons.support_agent, size: 72, color: Theme.of(context).colorScheme.primary)),
    ),
  );
}

class _LockScreen extends ConsumerWidget {
  const _LockScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Positioned.fill(
      key: const Key('lock-screen'),
      child: Material(
        color: theme.colorScheme.surface,
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline, size: 64, color: theme.colorScheme.primary),
                const SizedBox(height: 16),
                Text(l10n.lockedTitle, style: theme.textTheme.titleLarge),
                const SizedBox(height: 24),
                FilledButton.icon(
                  key: const Key('unlock'),
                  icon: const Icon(Icons.fingerprint),
                  label: Text(l10n.unlock),
                  onPressed: () => ref.read(appLockProvider.notifier).unlock(l10n.unlockReason),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
