import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'push_link.dart';

/// The phone's push channel (FCM on Android and iOS). Builds without a Firebase config get [NoopPushService]:
/// no prompt, no registration, and the settings say push is not set up.
abstract interface class PushService {
  bool get available;

  /// Asks the person, once, whether the app may notify them. Returns whether it may.
  Future<bool> requestPermission();

  /// The token the API sends pushes to, or null when there is none.
  Future<String?> token();

  Stream<String> get tokenRefreshes;

  /// Screens to open: one for each tapped notification while the app runs.
  Stream<String> get taps;

  /// The screen to open when a tapped notification started the app.
  Future<String?> initialTap();
}

class NoopPushService implements PushService {
  const NoopPushService();

  @override
  bool get available => false;

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<String?> token() async => null;

  @override
  Stream<String> get tokenRefreshes => const Stream.empty();

  @override
  Stream<String> get taps => const Stream.empty();

  @override
  Future<String?> initialTap() async => null;
}

class FirebasePushService implements PushService {
  FirebasePushService._();

  /// Null when the build has no Firebase config (see `scripts/firebase-config.sh`).
  static Future<FirebasePushService?> tryStart() async {
    try {
      await Firebase.initializeApp();
      // In the foreground the live connection shows its own banner, so the system stays quiet.
      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions();
      return FirebasePushService._();
    } on Object catch (error) {
      debugPrint('Push is not set up in this build: $error');
      return null;
    }
  }

  FirebaseMessaging get _messaging => FirebaseMessaging.instance;

  @override
  bool get available => true;

  @override
  Future<bool> requestPermission() async {
    final settings = await _messaging.requestPermission();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  // The replacement (register/onRegistered) yields an installation id for FCM's direct send. The API's
  // FcmPushSender sends to registration tokens, so these stay until the sender moves to direct send.
  @override
  // ignore: deprecated_member_use
  Future<String?> token() => _messaging.getToken();

  @override
  // ignore: deprecated_member_use
  Stream<String> get tokenRefreshes => _messaging.onTokenRefresh;

  @override
  Stream<String> get taps => FirebaseMessaging.onMessageOpenedApp
      .map((message) => pushLink(message.data))
      .where((link) => link != null)
      .cast<String>();

  @override
  Future<String?> initialTap() async {
    final message = await _messaging.getInitialMessage();
    return message == null ? null : pushLink(message.data);
  }
}

/// Set in `bootstrap` once Firebase has (or has not) started.
final pushServiceProvider = Provider<PushService>((ref) => const NoopPushService());
