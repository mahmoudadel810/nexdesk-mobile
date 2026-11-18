import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/startup.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/platform/web_links.dart';

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.about)),
      body: ListView(
        padding: const EdgeInsetsDirectional.all(24),
        children: [
          Icon(Icons.support_agent, size: 64, color: theme.colorScheme.primary),
          const SizedBox(height: 12),
          Text(l10n.appName, style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
          Text(
            l10n.version(ref.watch(appVersionProvider)),
            key: const Key('app-version'),
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text(l10n.aboutText, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 24),
          if (ref.watch(webBaseUrlProvider) != null)
            OutlinedButton.icon(
              icon: const Icon(Icons.open_in_new),
              label: Text(l10n.openOnWeb),
              onPressed: () => openWeb(ref, '/app/tickets'),
            ),
        ],
      ),
    );
  }
}
