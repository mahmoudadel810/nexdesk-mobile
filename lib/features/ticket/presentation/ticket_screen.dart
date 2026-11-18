import 'package:material_ui/material_ui.dart';

import '../../../core/l10n/generated/app_localizations.dart';

/// The ticket page. 16.7 builds the header, timeline and composer; for now it confirms which ticket opened.
class TicketScreen extends StatelessWidget {
  const TicketScreen({required this.ticketId, super.key});

  final String ticketId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.ticketTitle(ticketId.substring(0, 8)))),
      body: Center(child: Text(l10n.comingSoon, textAlign: TextAlign.center)),
    );
  }
}
