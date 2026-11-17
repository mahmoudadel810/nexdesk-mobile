import 'package:material_ui/material_ui.dart';

import '../../../core/l10n/generated/app_localizations.dart';

enum Section { inbox, notifications, profile }

/// Stands in for the tabs that later steps build (16.6 inbox, 16.9 notifications, 16.11 profile).
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({required this.section, super.key});

  final Section section;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = switch (section) {
      Section.inbox => l10n.inbox,
      Section.notifications => l10n.notifications,
      Section.profile => l10n.profile,
    };
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsetsDirectional.all(24),
          child: Text(l10n.comingSoon, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}
