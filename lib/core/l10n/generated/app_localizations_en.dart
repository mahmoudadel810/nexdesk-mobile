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
  String get signIn => 'Sign in';

  @override
  String get forgotPassword => 'Forgot your password?';

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
}
