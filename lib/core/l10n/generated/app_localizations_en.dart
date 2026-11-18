// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'NexDesk';

  @override
  String get tagline => 'Your help desk, in your pocket.';

  @override
  String get signInTitle => 'Sign in to your workspace';

  @override
  String get signInSubtitle => 'Use the email and password you use on the web.';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get signIn => 'Sign in';

  @override
  String get forgotPassword => 'Forgot your password?';

  @override
  String get emailRequired => 'Enter your email address.';

  @override
  String get emailInvalid => 'Enter a valid email address.';

  @override
  String get passwordRequired => 'Enter your password.';

  @override
  String get errorInvalidCredentials => 'The email or password is incorrect.';

  @override
  String get errorAccountLocked => 'Too many attempts. Try again in a few minutes.';

  @override
  String get errorEmailNotVerified => 'Confirm your email address first, using the link we sent you.';

  @override
  String get openEmailVerification => 'Resend the link on the web';

  @override
  String get errorNetwork => 'Can\'t reach NexDesk. Check your connection and try again.';

  @override
  String get errorUnexpected => 'Something went wrong. Try again.';

  @override
  String errorReference(String id) {
    return 'Reference: $id';
  }

  @override
  String get sessionEnded => 'Your session ended. Sign in again.';

  @override
  String get wakingServer => 'Waking the server, this can take up to a minute…';

  @override
  String get blockedSuspendedTitle => 'This workspace is suspended';

  @override
  String get blockedSuspendedBody =>
      'Ask your workspace owner to sort out the account on the web, then sign in again.';

  @override
  String get blockedDisabledTitle => 'Your account is deactivated';

  @override
  String get blockedDisabledBody => 'An admin of your workspace can reactivate it.';

  @override
  String get blockedAdminTitle => 'The platform console is on the web';

  @override
  String get blockedAdminBody => 'The app is for support teams. Platform admins sign in on the web.';

  @override
  String get blockedUpdateTitle => 'Update NexDesk';

  @override
  String get blockedUpdateBody =>
      'This version no longer works with NexDesk. Install the latest version to carry on.';

  @override
  String get signInAnother => 'Sign in with another account';

  @override
  String get openWeb => 'Open NexDesk on the web';

  @override
  String get language => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'العربية';

  @override
  String get comingSoon => 'This part of the app is on its way.';

  @override
  String get inbox => 'Inbox';

  @override
  String get notifications => 'Notifications';

  @override
  String get profile => 'Profile';

  @override
  String greeting(String name) {
    return 'Hello, $name';
  }

  @override
  String get workspace => 'Workspace';

  @override
  String get role => 'Role';

  @override
  String get signOut => 'Sign out';

  @override
  String get signOutConfirm => 'Sign out of NexDesk on this phone?';

  @override
  String get cancel => 'Cancel';
}
