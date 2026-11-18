import '../api/generated/nex_desk_api.dart';

/// Who is signed in, and the short-lived access token that proves it. Kept in memory only.
class Session {
  const Session({required this.accessToken, required this.expiresAt, required this.details});

  factory Session.from(MobileAuthResponse response) =>
      Session(accessToken: response.accessToken, expiresAt: response.expiresAt, details: response.session);

  final String accessToken;
  final DateTime expiresAt;
  final SessionDto details;

  SessionUser get user => details.user;

  SessionTenant? get tenant => details.tenant;

  bool can(String permission) => details.permissions.contains(permission);

  bool expiresWithin(Duration margin, DateTime now) => !expiresAt.isAfter(now.add(margin));
}

/// Why the app cannot be used right now. Each has its own screen with a way out.
enum BlockedReason { tenantSuspended, accountDisabled, platformAdmin, updateRequired }

/// Why the person was signed out, when it was not their own choice.
enum SignedOutReason { sessionEnded }

sealed class SessionState {
  const SessionState();
}

/// Starting up: checking the minimum version and any stored sign-in.
final class SessionLoading extends SessionState {
  const SessionLoading();
}

final class SignedOut extends SessionState {
  const SignedOut([this.reason]);

  final SignedOutReason? reason;
}

final class SignedIn extends SessionState {
  const SignedIn(this.session);

  final Session session;
}

final class Blocked extends SessionState {
  const Blocked(this.reason);

  final BlockedReason reason;
}
