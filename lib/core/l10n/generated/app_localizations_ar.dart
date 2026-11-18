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
  String get showPassword => 'إظهار كلمة المرور';

  @override
  String get hidePassword => 'إخفاء كلمة المرور';

  @override
  String get signIn => 'تسجيل الدخول';

  @override
  String get forgotPassword => 'نسيت كلمة المرور؟';

  @override
  String get emailRequired => 'أدخل بريدك الإلكتروني.';

  @override
  String get emailInvalid => 'أدخل بريدًا إلكترونيًا صحيحًا.';

  @override
  String get passwordRequired => 'أدخل كلمة المرور.';

  @override
  String get errorInvalidCredentials => 'البريد الإلكتروني أو كلمة المرور غير صحيحة.';

  @override
  String get errorAccountLocked => 'محاولات كثيرة. حاول مرة أخرى بعد دقائق.';

  @override
  String get errorEmailNotVerified => 'أكّد بريدك الإلكتروني أولًا من الرابط الذي أرسلناه إليك.';

  @override
  String get openEmailVerification => 'إعادة إرسال الرابط على الويب';

  @override
  String get errorNetwork => 'تعذّر الوصول إلى NexDesk. تحقق من اتصالك وحاول مرة أخرى.';

  @override
  String get errorUnexpected => 'حدث خطأ ما. حاول مرة أخرى.';

  @override
  String errorReference(String id) {
    return 'المرجع: $id';
  }

  @override
  String get sessionEnded => 'انتهت جلستك. سجّل الدخول مرة أخرى.';

  @override
  String get wakingServer => 'جارٍ تشغيل الخادم، قد يستغرق ذلك دقيقة…';

  @override
  String get blockedSuspendedTitle => 'مساحة العمل هذه موقوفة';

  @override
  String get blockedSuspendedBody =>
      'اطلب من مالك مساحة العمل معالجة الحساب على الويب، ثم سجّل الدخول مرة أخرى.';

  @override
  String get blockedDisabledTitle => 'حسابك معطّل';

  @override
  String get blockedDisabledBody => 'يمكن لأحد مشرفي مساحة عملك إعادة تفعيله.';

  @override
  String get blockedAdminTitle => 'لوحة إدارة المنصة على الويب';

  @override
  String get blockedAdminBody => 'التطبيق مخصص لفرق الدعم. يسجّل مشرفو المنصة الدخول على الويب.';

  @override
  String get blockedUpdateTitle => 'حدّث NexDesk';

  @override
  String get blockedUpdateBody => 'هذا الإصدار لم يعد يعمل مع NexDesk. ثبّت أحدث إصدار للمتابعة.';

  @override
  String get signInAnother => 'تسجيل الدخول بحساب آخر';

  @override
  String get openWeb => 'فتح NexDesk على الويب';

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

  @override
  String greeting(String name) {
    return 'مرحبًا، $name';
  }

  @override
  String get workspace => 'مساحة العمل';

  @override
  String get role => 'الدور';

  @override
  String get signOut => 'تسجيل الخروج';

  @override
  String get signOutConfirm => 'تسجيل الخروج من NexDesk على هذا الجوال؟';

  @override
  String get cancel => 'إلغاء';
}
