import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../core/auth/session.dart';
import '../../../core/auth/session_controller.dart';
import '../../../core/l10n/generated/app_localizations.dart';

/// Who is signed in, and signing out. 16.11 adds availability, language, theme and the app lock.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(sessionProvider);
    if (state is! SignedIn) return const SizedBox.shrink();
    final session = state.session;

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

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profile)),
      body: ListView(
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
          ListTile(
            key: const Key('notification-settings'),
            leading: const Icon(Icons.notifications_active_outlined),
            title: Text(l10n.notificationSettings),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(Routes.notificationSettings),
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
