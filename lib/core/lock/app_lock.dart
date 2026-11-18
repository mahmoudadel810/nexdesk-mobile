import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../../app/preferences.dart';
import '../auth/session.dart';
import '../auth/session_controller.dart';

/// The phone's fingerprint, face or screen lock. Widget tests replace it.
abstract interface class Biometrics {
  /// Whether the phone has any lock that can confirm it is the owner.
  Future<bool> available();

  Future<bool> confirm(String reason);
}

class LocalBiometrics implements Biometrics {
  final _auth = LocalAuthentication();

  @override
  Future<bool> available() async {
    try {
      return await _auth.isDeviceSupported();
    } on Object {
      return false;
    }
  }

  @override
  Future<bool> confirm(String reason) async {
    try {
      // The screen lock (PIN, pattern) is accepted too, so someone whose fingerprint fails is not shut out.
      return await _auth.authenticate(localizedReason: reason, persistAcrossBackgrounding: true);
    } on Object {
      return false;
    }
  }
}

final biometricsProvider = Provider<Biometrics>((ref) => LocalBiometrics());

class AppLockState {
  const AppLockState({required this.enabled, this.locked = false, this.obscured = false});

  /// The person turned the lock on in their profile.
  final bool enabled;

  /// The lock screen is up: the app was away for [AppLockController.relockAfter] or was just started.
  final bool locked;

  /// The app is not in front: its content is covered, so the app switcher shows no tickets.
  final bool obscured;

  AppLockState copyWith({bool? enabled, bool? locked, bool? obscured}) => AppLockState(
    enabled: enabled ?? this.enabled,
    locked: locked ?? this.locked,
    obscured: obscured ?? this.obscured,
  );
}

/// The app lock and the privacy cover. Both apply only while someone is signed in.
class AppLockController extends Notifier<AppLockState> {
  static const relockAfter = Duration(minutes: 5);
  static const _key = 'nexdesk.app-lock';

  DateTime? _leftAt;

  bool get _signedIn => ref.read(sessionProvider) is SignedIn;

  @override
  AppLockState build() {
    final enabled = ref.read(sharedPreferencesProvider).getBool(_key) ?? false;
    // Opening the app fresh with the lock on asks first.
    ref.listen(sessionProvider, (previous, next) {
      if (previous is! SignedIn && next is SignedIn && state.enabled && previous is SessionLoading) {
        state = state.copyWith(locked: true);
      }
      if (next is! SignedIn) state = state.copyWith(locked: false, obscured: false);
    });
    return AppLockState(enabled: enabled);
  }

  Future<bool> setEnabled(bool on, String reason) async {
    // Turning it on proves the lock works on this phone first, so nobody locks themselves out.
    if (on && !await ref.read(biometricsProvider).confirm(reason)) return false;
    await ref.read(sharedPreferencesProvider).setBool(_key, on);
    state = state.copyWith(enabled: on, locked: false);
    return true;
  }

  void appHidden() {
    if (!_signedIn) return;
    _leftAt ??= ref.read(clockProvider)();
    state = state.copyWith(obscured: true);
  }

  void appShown() {
    final leftAt = _leftAt;
    _leftAt = null;
    final away = leftAt == null ? Duration.zero : ref.read(clockProvider)().difference(leftAt);
    state = state.copyWith(
      obscured: false,
      locked: state.locked || (state.enabled && _signedIn && away >= relockAfter),
    );
  }

  Future<void> unlock(String reason) async {
    if (await ref.read(biometricsProvider).confirm(reason)) state = state.copyWith(locked: false);
  }
}

final appLockProvider = NotifierProvider<AppLockController, AppLockState>(AppLockController.new);
