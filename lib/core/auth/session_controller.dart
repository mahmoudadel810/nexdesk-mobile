import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api.dart';
import '../api/generated/nex_desk_api.dart';
import '../cache/database.dart';
import '../cache/file_cache.dart';
import '../errors/app_error.dart';
import 'session.dart';
import 'token_store.dart';

final tokenStoreProvider = Provider<TokenStore>((ref) => SecureTokenStore());

/// "Now", so tests can move time.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Owns the sign-in. Refreshing goes through one in-flight request at a time: the API treats a refresh token
/// presented twice as stolen and ends the whole sign-in, so two overlapping refreshes would sign the phone out.
class SessionController extends Notifier<SessionState> {
  Future<Session>? _refreshing;

  AuthMobileClient get _auth => ref.read(authApiProvider).authMobile;

  TokenStore get _tokens => ref.read(tokenStoreProvider);

  @override
  SessionState build() => const SessionLoading();

  Session? get current => switch (state) {
    SignedIn(:final session) => session,
    _ => null,
  };

  /// On launch: use the stored refresh token if there is one.
  Future<void> restore() async {
    final stored = await _tokens.read();
    if (stored == null) {
      state = const SignedOut();
      return;
    }

    try {
      await refresh();
    } on AppError catch (error) {
      // Offline at launch: stay signed out of the network but keep the token for the next try.
      if (error.isNetwork) {
        state = const SignedOut();
      }
    }
  }

  /// Signs in with email and password. Throws [AppError] for the sign-in form to show.
  Future<void> signIn(String email, String password) async {
    final response = await _call(
      () => _auth.mobileLogin(
        body: MobileLoginRequest(email: email.trim(), password: password, deviceName: _deviceName()),
      ),
    );

    // The app is for workspace teams; the platform console stays on the web.
    if (response.session.user.isPlatformAdmin) {
      await _revoke(response.refreshToken);
      state = const Blocked(BlockedReason.platformAdmin);
      return;
    }

    await _tokens.write(response.refreshToken);
    state = SignedIn(Session.from(response));
  }

  /// A valid access token, refreshed first when it is about to expire.
  Future<String> accessToken() async {
    final session = current;
    final now = ref.read(clockProvider)();
    if (session != null && !session.expiresWithin(const Duration(seconds: 60), now)) {
      return session.accessToken;
    }

    return (await refresh()).accessToken;
  }

  /// Rotates the refresh token. Concurrent callers share one request.
  Future<Session> refresh() => _refreshing ??= _refresh().whenComplete(() => _refreshing = null);

  Future<Session> _refresh() async {
    final stored = await _tokens.read();
    if (stored == null) {
      state = const SignedOut(SignedOutReason.sessionEnded);
      throw const AppError(kind: AppErrorKind.problem, status: 401, code: ErrorCodes.invalidRefreshToken);
    }

    final MobileAuthResponse response;
    try {
      response = await _call(
        () => _auth.mobileRefreshSession(body: MobileRefreshRequest(refreshToken: stored)),
      );
    } on AppError catch (error) {
      switch (error.code) {
        case ErrorCodes.invalidRefreshToken:
          await _wipe();
          state = const SignedOut(SignedOutReason.sessionEnded);
        case ErrorCodes.tenantSuspended:
          await _wipe();
          state = const Blocked(BlockedReason.tenantSuspended);
        case ErrorCodes.accountDisabled:
          await _wipe();
          state = const Blocked(BlockedReason.accountDisabled);
      }
      rethrow;
    }

    // The old token is spent the moment the server answers, so the new one is saved before anything uses it.
    await _tokens.write(response.refreshToken);
    final session = Session.from(response);
    state = SignedIn(session);
    return session;
  }

  /// Ends the sign-in on the server (best effort) and removes everything this person left on the phone.
  Future<void> signOut() async {
    final stored = await _tokens.read();
    if (stored != null) {
      await _revoke(stored);
    }

    await _wipe();
    state = const SignedOut();
  }

  /// Back to the sign-in screen from a blocked state.
  void startOver() => state = const SignedOut();

  /// For the minimum-version check at launch.
  void block(BlockedReason reason) => state = Blocked(reason);

  Future<void> _revoke(String refreshToken) async {
    try {
      await _auth.mobileLogout(body: MobileRefreshRequest(refreshToken: refreshToken));
    } on Object {
      // Offline or already revoked: the local wipe still signs this phone out.
    }
  }

  Future<void> _wipe() async {
    await _tokens.clear();
    await ref.read(databaseProvider).wipe();
    try {
      await ref.read(fileCacheProvider).wipe();
    } on Object {
      // The OS may already have cleared it.
    }
  }

  static String _deviceName() {
    try {
      return Platform.isIOS ? 'iPhone' : 'Android phone';
    } on Object {
      return 'Phone';
    }
  }

  static Future<T> _call<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on Object catch (error) {
      throw AppError.from(error);
    }
  }
}

final sessionProvider = NotifierProvider<SessionController, SessionState>(SessionController.new);
