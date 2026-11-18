import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/preferences.dart';
import '../../../app/router.dart';
import '../../../core/api/generated/nex_desk_api.dart';
import '../../../core/auth/session.dart';
import '../../../core/auth/session_controller.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/lock/app_lock.dart';
import '../data/profile_repository.dart';

final _lockAvailableProvider = FutureProvider.autoDispose<bool>(
  (ref) => ref.watch(biometricsProvider).available(),
);

/// Who is signed in, how they appear to the team, how the app looks, the app lock, and signing out.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(sessionProvider);
    if (state is! SignedIn) return const SizedBox.shrink();
    final session = state.session;
    final theme = Theme.of(context);
    final me = ref.watch(myUserProvider);
    final lock = ref.watch(appLockProvider);
    final lockAvailable = ref.watch(_lockAvailableProvider).value ?? false;

    void showError(Object error) {
      final message = error is AppError ? messageFor(error, l10n) : l10n.errorUnexpected;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }

    Future<void> signOut() async {
      final confirmed = await showAdaptiveDialog<bool>(
        context: context,
        builder: (context) => AlertDialog.adaptive(
          content: Text(l10n.signOutConfirm),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
            TextButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.signOut)),
          ],
        ),
      );
      if (confirmed ?? false) await ref.read(sessionProvider.notifier).signOut();
    }

    Widget section(String title, Widget child, {Key? key}) => Padding(
      key: key,
      padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profile)),
      body: ListView(
        padding: const EdgeInsetsDirectional.only(bottom: 24),
        children: [
          ListTile(
            leading: CircleAvatar(child: Text(session.user.fullName.characters.first.toUpperCase())),
            title: Text(session.user.fullName),
            subtitle: Text(session.user.email, textDirection: TextDirection.ltr),
          ),
          if (session.tenant case final tenant?)
            ListTile(
              leading: const Icon(Icons.business),
              title: Text(l10n.workspace),
              subtitle: Text(tenant.name),
            ),
          if (session.user.role case final role?)
            ListTile(leading: const Icon(Icons.badge_outlined), title: Text(l10n.role), subtitle: Text(role)),
          const Divider(),
          if (me.value case final user?)
            section(
              l10n.availability,
              SegmentedButton<Availability>(
                key: const Key('availability'),
                segments: [
                  ButtonSegment(value: Availability.online, label: Text(l10n.availabilityOnline)),
                  ButtonSegment(value: Availability.away, label: Text(l10n.availabilityAway)),
                  ButtonSegment(value: Availability.offline, label: Text(l10n.availabilityOffline)),
                ],
                selected: {user.availability},
                onSelectionChanged: (value) async {
                  try {
                    await ref.read(profileRepositoryProvider).setAvailability(value.single);
                    ref.invalidate(myUserProvider);
                  } on Object catch (error) {
                    showError(error);
                  }
                },
              ),
            ),
          section(
            l10n.language,
            SegmentedButton<String>(
              key: const Key('language'),
              segments: [
                ButtonSegment(value: 'en', label: Text(l10n.languageEnglish)),
                ButtonSegment(value: 'ar', label: Text(l10n.languageArabic)),
              ],
              selected: {session.user.language},
              onSelectionChanged: (value) async {
                try {
                  await ref.read(profileRepositoryProvider).setLanguage(value.single);
                } on Object catch (error) {
                  showError(error);
                }
              },
            ),
          ),
          section(
            l10n.theme,
            SegmentedButton<ThemeMode>(
              key: const Key('theme'),
              segments: [
                ButtonSegment(value: ThemeMode.system, label: Text(l10n.themeSystem)),
                ButtonSegment(value: ThemeMode.light, label: Text(l10n.themeLight)),
                ButtonSegment(value: ThemeMode.dark, label: Text(l10n.themeDark)),
              ],
              selected: {ref.watch(themeModeProvider)},
              onSelectionChanged: (value) => ref.read(themeModeProvider.notifier).set(value.single),
            ),
          ),
          SwitchListTile(
            key: const Key('app-lock'),
            secondary: const Icon(Icons.fingerprint),
            title: Text(l10n.appLock),
            subtitle: Text(lockAvailable ? l10n.appLockHint : l10n.appLockUnavailable),
            value: lock.enabled,
            onChanged: lockAvailable || lock.enabled
                ? (on) => ref.read(appLockProvider.notifier).setEnabled(on, l10n.unlockReason)
                : null,
          ),
          const Divider(),
          ListTile(
            key: const Key('notification-settings'),
            leading: const Icon(Icons.notifications_active_outlined),
            title: Text(l10n.notificationSettings),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(Routes.notificationSettings),
          ),
          ListTile(
            key: const Key('about'),
            leading: const Icon(Icons.info_outline),
            title: Text(l10n.about),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(Routes.about),
          ),
          const Divider(),
          ListTile(
            key: const Key('sign-out'),
            leading: const Icon(Icons.logout),
            title: Text(l10n.signOut),
            onTap: signOut,
          ),
        ],
      ),
    );
  }
}
