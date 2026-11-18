import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/auth/session.dart';
import '../../../core/auth/session_controller.dart';
import '../../../core/l10n/generated/app_localizations.dart';

enum Section { inbox, notifications }

/// Stands in for the tabs that later steps build (16.6 inbox, 16.9 notifications).
class PlaceholderScreen extends ConsumerWidget {
  const PlaceholderScreen({required this.section, super.key});

  final Section section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final title = switch (section) {
      Section.inbox => l10n.inbox,
      Section.notifications => l10n.notifications,
    };
    final name = switch (ref.watch(sessionProvider)) {
      SignedIn(:final session) => session.user.fullName,
      _ => null,
    };
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsetsDirectional.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (section == Section.inbox && name != null)
                Text(
                  l10n.greeting(name),
                  key: const Key('greeting'),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              const SizedBox(height: 8),
              Text(l10n.comingSoon, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
