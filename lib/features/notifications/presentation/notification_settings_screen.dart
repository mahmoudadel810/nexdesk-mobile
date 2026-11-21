import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/api/api.dart';
import '../../../core/api/generated/nex_desk_api.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/push/push_service.dart';

/// The same preferences as the web's profile page: for each event, in the app, by email and on the phone.
final notificationPreferencesProvider = FutureProvider.autoDispose<List<NotificationPreferenceDto>>((
  ref,
) async {
  try {
    return await ref.watch(apiProvider).notifications.getNotificationPreferences();
  } on Object catch (error) {
    throw AppError.from(error);
  }
});

String preferenceLabel(NotificationType type, AppLocalizations l10n) => switch (type) {
  NotificationTypeKnown(value: NotificationTypeValue.ticketAssigned) => l10n.prefTicketAssigned,
  NotificationTypeKnown(value: NotificationTypeValue.ticketReply) => l10n.prefTicketReply,
  NotificationTypeKnown(value: NotificationTypeValue.ticketNote) => l10n.prefTicketNote,
  NotificationTypeKnown(value: NotificationTypeValue.slaWarning) => l10n.prefSlaWarning,
  NotificationTypeKnown(value: NotificationTypeValue.slaBreach) => l10n.prefSlaBreach,
  NotificationTypeKnown(value: NotificationTypeValue.mention) => l10n.prefMention,
  _ => l10n.prefAutomation,
};

enum _Channel { inApp, email, push }

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends ConsumerState<NotificationSettingsScreen> {
  List<NotificationPreferenceDto>? _edited;
  AppError? _saveError;

  /// Each save sends the whole set, so only the answer to the newest one says what is stored.
  int _saves = 0;

  /// Saves the whole set, as the web does; on failure the switch goes back and the reason shows.
  Future<void> _toggle(
    List<NotificationPreferenceDto> current,
    NotificationType type,
    _Channel channel,
    bool on,
  ) async {
    final next = [
      for (final p in current)
        if (p.type == type)
          NotificationPreferenceDto.fromJson({
            ...p.toJson(),
            switch (channel) {
              _Channel.inApp => 'inApp',
              _Channel.email => 'email',
              _Channel.push => 'push',
            }: on,
          })
        else
          p,
    ];
    final save = ++_saves;
    setState(() {
      _edited = next;
      _saveError = null;
    });
    try {
      final saved = await ref
          .read(apiProvider)
          .notifications
          .updateNotificationPreferences(
            body: UpdateNotificationPreferencesRequest(
              preferences: [
                for (final p in next)
                  NotificationPreferenceInput(type: p.type, inApp: p.inApp, email: p.email, push: p.push),
              ],
            ),
          );
      if (mounted && save == _saves) setState(() => _edited = saved);
    } on Object catch (error) {
      if (mounted && save == _saves) {
        setState(() {
          _edited = current;
          _saveError = AppError.from(error);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pushAvailable = ref.watch(pushServiceProvider).available;
    final loaded = ref.watch(notificationPreferencesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.notificationSettings)),
      body: switch (loaded) {
        AsyncData(:final value) => _list(context, _edited ?? value, pushAvailable, l10n),
        AsyncError(:final error) => Center(
          child: Padding(
            padding: const EdgeInsetsDirectional.all(32),
            child: Text(
              error is AppError ? messageFor(error, l10n) : l10n.errorUnexpected,
              textAlign: TextAlign.center,
            ),
          ),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }

  Widget _list(
    BuildContext context,
    List<NotificationPreferenceDto> prefs,
    bool pushAvailable,
    AppLocalizations l10n,
  ) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsetsDirectional.only(bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 8),
          child: Text(l10n.notificationSettingsSubtitle, style: theme.textTheme.bodyMedium),
        ),
        if (!pushAvailable)
          Padding(
            key: const Key('push-unavailable'),
            padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 8),
            child: Text(l10n.pushUnavailable, style: theme.textTheme.bodySmall),
          ),
        if (_saveError case final error?)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 8),
            child: Text(messageFor(error, l10n), style: TextStyle(color: theme.colorScheme.error)),
          ),
        for (final p in prefs) ...[
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 0),
            child: Text(preferenceLabel(p.type, l10n), style: theme.textTheme.titleSmall),
          ),
          SwitchListTile(
            key: Key('pref-${p.type.toJson()}-inApp'),
            dense: true,
            title: Text(l10n.channelInApp),
            value: p.inApp,
            onChanged: (on) => _toggle(prefs, p.type, _Channel.inApp, on),
          ),
          SwitchListTile(
            key: Key('pref-${p.type.toJson()}-email'),
            dense: true,
            title: Text(l10n.channelEmail),
            value: p.email,
            onChanged: (on) => _toggle(prefs, p.type, _Channel.email, on),
          ),
          SwitchListTile(
            key: Key('pref-${p.type.toJson()}-push'),
            dense: true,
            title: Text(l10n.channelPush),
            value: p.push && pushAvailable,
            onChanged: pushAvailable ? (on) => _toggle(prefs, p.type, _Channel.push, on) : null,
          ),
        ],
      ],
    );
  }
}
