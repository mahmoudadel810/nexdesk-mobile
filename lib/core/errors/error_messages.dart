import '../l10n/generated/app_localizations.dart';
import 'app_error.dart';

/// The sentence to show for an error. Known codes get the app's own wording in the person's language; anything
/// else falls back to the API's title, or a generic message with the request id for support.
String messageFor(AppError error, AppLocalizations l10n) {
  if (error.isNetwork) return l10n.errorNetwork;
  return switch (error.code) {
    ErrorCodes.invalidCredentials => l10n.errorInvalidCredentials,
    ErrorCodes.accountLocked => l10n.errorAccountLocked,
    ErrorCodes.emailNotVerified => l10n.errorEmailNotVerified,
    ErrorCodes.invalidRefreshToken => l10n.sessionEnded,
    ErrorCodes.tenantSuspended => l10n.blockedSuspendedTitle,
    ErrorCodes.accountDisabled => l10n.blockedDisabledTitle,
    _ when (error.status ?? 0) >= 500 || error.kind == AppErrorKind.unexpected =>
      error.requestId == null
          ? l10n.errorUnexpected
          : '${l10n.errorUnexpected} ${l10n.errorReference(error.requestId!)}',
    _ => error.title ?? l10n.errorUnexpected,
  };
}
