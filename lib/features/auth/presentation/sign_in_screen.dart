import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/preferences.dart';
import '../../../core/l10n/generated/app_localizations.dart';

/// The sign-in form. 16.5 wires it to the API; for now it shows the layout in both directions.
class SignInScreen extends ConsumerWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    return Scaffold(
      appBar: AppBar(
        actions: [
          TextButton.icon(
            key: const Key('language-toggle'),
            onPressed: () => ref.read(languageProvider.notifier).set(arabic ? 'en' : 'ar'),
            icon: const Icon(Icons.translate),
            label: Text(arabic ? l10n.languageEnglish : l10n.languageArabic),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.support_agent, size: 56, color: theme.colorScheme.primary),
                  const SizedBox(height: 12),
                  Text(l10n.appName, textAlign: TextAlign.center, style: theme.textTheme.headlineMedium),
                  Text(l10n.tagline, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 32),
                  Text(l10n.signInTitle, style: theme.textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(l10n.signInSubtitle, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 24),
                  TextField(
                    key: const Key('email'),
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    textDirection: TextDirection.ltr,
                    decoration: InputDecoration(labelText: l10n.email),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    key: const Key('password'),
                    obscureText: true,
                    autofillHints: const [AutofillHints.password],
                    decoration: InputDecoration(labelText: l10n.password),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(key: const Key('sign-in'), onPressed: null, child: Text(l10n.signIn)),
                  const SizedBox(height: 8),
                  TextButton(onPressed: null, child: Text(l10n.forgotPassword)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
