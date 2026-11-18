import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/auth/session.dart';
import '../../../core/auth/session_controller.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/platform/web_links.dart';

/// When the app cannot be used: a suspended workspace, a deactivated account, a platform admin, or a build the
/// API no longer supports. Each says why and offers the way out.
class BlockedScreen extends ConsumerWidget {
  const BlockedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final reason = switch (ref.watch(sessionProvider)) {
      Blocked(:final reason) => reason,
      _ => BlockedReason.accountDisabled,
    };
    final (icon, title, body) = switch (reason) {
      BlockedReason.tenantSuspended => (
        Icons.pause_circle_outline,
        l10n.blockedSuspendedTitle,
        l10n.blockedSuspendedBody,
      ),
      BlockedReason.accountDisabled => (
        Icons.person_off_outlined,
        l10n.blockedDisabledTitle,
        l10n.blockedDisabledBody,
      ),
      BlockedReason.platformAdmin => (
        Icons.admin_panel_settings_outlined,
        l10n.blockedAdminTitle,
        l10n.blockedAdminBody,
      ),
      BlockedReason.updateRequired => (Icons.system_update, l10n.blockedUpdateTitle, l10n.blockedUpdateBody),
    };

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsetsDirectional.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 64, color: theme.colorScheme.primary),
                const SizedBox(height: 16),
                Text(
                  title,
                  key: const Key('blocked-title'),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(body, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                if (reason == BlockedReason.platformAdmin)
                  FilledButton(onPressed: () => openWeb(ref, '/auth/login'), child: Text(l10n.openWeb)),
                if (reason != BlockedReason.updateRequired)
                  TextButton(
                    onPressed: () => ref.read(sessionProvider.notifier).startOver(),
                    child: Text(l10n.signInAnother),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
