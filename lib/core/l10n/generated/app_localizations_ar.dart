// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'NexDesk';

  @override
  String get tagline => 'مكتب الدعم في جيبك.';

  @override
  String get signInTitle => 'سجّل الدخول إلى مساحة عملك';

  @override
  String get signInSubtitle => 'استخدم البريد الإلكتروني وكلمة المرور نفسيهما على الويب.';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get password => 'كلمة المرور';

  @override
  String get signIn => 'تسجيل الدخول';

  @override
  String get forgotPassword => 'نسيت كلمة المرور؟';

  @override
  String get language => 'اللغة';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'العربية';

  @override
  String get comingSoon => 'هذا الجزء من التطبيق قادم قريبًا.';

  @override
  String get inbox => 'الوارد';

  @override
  String get notifications => 'الإشعارات';

  @override
  String get profile => 'الملف الشخصي';
}
