import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/preferences.dart';
import '../../../core/auth/session.dart';
import '../../../core/auth/session_controller.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/platform/web_links.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _showPassword = false;
  AppError? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(sessionProvider.notifier).signIn(_email.text, _password.text);
    } on AppError catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    final sessionEnded = switch (ref.watch(sessionProvider)) {
      SignedOut(reason: SignedOutReason.sessionEnded) => true,
      _ => false,
    };

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
              child: AutofillGroup(
                child: Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(Icons.support_agent, size: 56, color: theme.colorScheme.primary),
                      const SizedBox(height: 12),
                      Text(l10n.appName, textAlign: TextAlign.center, style: theme.textTheme.headlineMedium),
                      Text(l10n.tagline, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
                      const SizedBox(height: 32),
                      if (sessionEnded && _error == null) ...[
                        _Notice(key: const Key('session-ended'), text: l10n.sessionEnded),
                        const SizedBox(height: 16),
                      ],
                      Text(l10n.signInTitle, style: theme.textTheme.titleLarge),
                      const SizedBox(height: 4),
                      Text(l10n.signInSubtitle, style: theme.textTheme.bodyMedium),
                      const SizedBox(height: 24),
                      TextFormField(
                        key: const Key('email'),
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        autocorrect: false,
                        textDirection: TextDirection.ltr,
                        decoration: InputDecoration(labelText: l10n.email),
                        validator: (value) {
                          final email = value?.trim() ?? '';
                          if (email.isEmpty) return l10n.emailRequired;
                          return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)
                              ? null
                              : l10n.emailInvalid;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        key: const Key('password'),
                        controller: _password,
                        obscureText: !_showPassword,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        onFieldSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          labelText: l10n.password,
                          suffixIcon: IconButton(
                            tooltip: _showPassword ? l10n.hidePassword : l10n.showPassword,
                            icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => _showPassword = !_showPassword),
                          ),
                        ),
                        validator: (value) => (value ?? '').isEmpty ? l10n.passwordRequired : null,
                      ),
                      if (_error case final error?) ...[
                        const SizedBox(height: 16),
                        _Notice(key: const Key('sign-in-error'), text: messageFor(error, l10n), error: true),
                        if (error.code == ErrorCodes.emailNotVerified)
                          TextButton(
                            onPressed: () => openWeb(ref, '/auth/login'),
                            child: Text(l10n.openEmailVerification),
                          ),
                      ],
                      const SizedBox(height: 24),
                      FilledButton(
                        key: const Key('sign-in'),
                        onPressed: _busy ? null : _submit,
                        child: _busy
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(l10n.signIn),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => openWeb(ref, '/auth/forgot-password'),
                        child: Text(l10n.forgotPassword),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text, this.error = false, super.key});

  final String text;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsetsDirectional.all(12),
        decoration: BoxDecoration(
          color: error ? scheme.errorContainer : scheme.secondaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              error ? Icons.error_outline : Icons.info_outline,
              color: error ? scheme.onErrorContainer : scheme.onSecondaryContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(color: error ? scheme.onErrorContainer : scheme.onSecondaryContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
