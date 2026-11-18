import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/preferences.dart';
import '../../app/startup.dart';
import '../api/api.dart';
import '../api/generated/nex_desk_api.dart';
import '../auth/session_controller.dart';
import 'push_service.dart';

/// Tells the API where this phone receives pushes (`PUT /devices/{installationId}`), and forgets it on sign-out
/// (`DELETE`). The installation id is made once and kept, so reinstalling the token replaces the same row.
/// Everything here is best effort: a phone without push still works fully.
class DeviceRegistration {
  DeviceRegistration(this._ref);

  static const _idKey = 'nexdesk.installation-id';

  final Ref _ref;
  StreamSubscription<String>? _refreshes;

  PushService get _push => _ref.read(pushServiceProvider);

  String get installationId {
    final preferences = _ref.read(sharedPreferencesProvider);
    final stored = preferences.getString(_idKey);
    if (stored != null) return stored;
    final random = Random.secure();
    final id = List.generate(16, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
    unawaited(preferences.setString(_idKey, id));
    return id;
  }

  /// Asks for permission (the system shows the prompt only the first time) and registers the token. Called when
  /// the person first reaches their inbox, never on the splash screen.
  Future<void> registerIfAllowed() async {
    if (!_push.available) return;
    try {
      if (!await _push.requestPermission()) return;
      // Listening first: a later token must reach the API even if this first registration fails.
      _refreshes ??= _push.tokenRefreshes.listen((token) => unawaited(_register(token).catchError((_) {})));
      final token = await _push.token();
      if (token == null) return;
      await _register(token);
    } on Object {
      // Registration is tried again on the next launch.
    }
  }

  Future<void> unregister() async {
    unawaited(_refreshes?.cancel());
    _refreshes = null;
    if (!_push.available) return;
    try {
      await _ref.read(apiProvider).devices.removeDevice(installationId: installationId);
    } on Object {
      // Offline or already signed out on the server; the API drops the device with the sign-in anyway.
    }
  }

  Future<void> _register(String token) async {
    final session = _ref.read(sessionProvider.notifier).current;
    await _ref
        .read(apiProvider)
        .devices
        .registerDevice(
          installationId: installationId,
          body: RegisterDeviceRequest(
            platform: Platform.isIOS ? DevicePlatform.ios : DevicePlatform.android,
            pushToken: token,
            appVersion: _ref.read(appVersionProvider),
            locale: session?.user.language ?? 'en',
          ),
        );
  }
}

final deviceRegistrationProvider = Provider<DeviceRegistration>(DeviceRegistration.new);
