import 'package:material_ui/material_ui.dart';

import '../../../core/l10n/generated/app_localizations.dart';

enum Section { notifications }

/// Stands in for the tabs that later steps build (16.9 notifications).
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({required this.section, super.key});

  final Section section;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.notifications)),
      body: Center(
        child: Padding(
          padding: const EdgeInsetsDirectional.all(24),
          child: Text(l10n.comingSoon, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}
