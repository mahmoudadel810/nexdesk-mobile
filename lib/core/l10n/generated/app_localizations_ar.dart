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
  String get inbox => 'الوارد';

  @override
  String get notifications => 'الإشعارات';

  @override
  String get profile => 'الملف الشخصي';

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

  @override
  String get tabMine => 'تذاكري';

  @override
  String get tabUnassigned => 'غير مسندة';

  @override
  String get tabSla => 'مستوى الخدمة';

  @override
  String get tabAll => 'الكل';

  @override
  String get slaBreached => 'متجاوزة';

  @override
  String get slaAtRisk => 'معرّضة للتجاوز';

  @override
  String get searchTickets => 'بحث في التذاكر';

  @override
  String get searchHint => 'الموضوع أو الرسالة أو العميل أو رقم التذكرة';

  @override
  String get savedViews => 'العروض المحفوظة';

  @override
  String get noSavedViews => 'لا توجد عروض محفوظة بعد. احفظ عرضًا على الويب وسيظهر هنا.';

  @override
  String get sharedView => 'مشترك';

  @override
  String get clearView => 'العودة إلى الوارد';

  @override
  String get emptyMine => 'لا شيء مسند إليك. استمتع بالهدوء.';

  @override
  String get emptyList => 'لا توجد تذاكر هنا.';

  @override
  String get emptySearch => 'لا توجد تذاكر مطابقة.';

  @override
  String get retry => 'حاول مرة أخرى';

  @override
  String offlineSince(String time) {
    return 'لا يوجد اتصال. تُعرض التذاكر كما كانت $time.';
  }

  @override
  String ticketCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count تذكرة',
      many: '$count تذكرة',
      few: '$count تذاكر',
      two: 'تذكرتان',
      one: 'تذكرة واحدة',
      zero: 'لا توجد تذاكر',
    );
    return '$_temp0';
  }

  @override
  String get unassignedPerson => 'غير مسندة';

  @override
  String get statusNew => 'جديدة';

  @override
  String get statusOpen => 'مفتوحة';

  @override
  String get statusPending => 'بانتظار العميل';

  @override
  String get statusOnHold => 'معلّقة';

  @override
  String get statusSolved => 'محلولة';

  @override
  String get statusClosed => 'مغلقة';

  @override
  String get priorityLow => 'منخفضة';

  @override
  String get priorityNormal => 'عادية';

  @override
  String get priorityHigh => 'مرتفعة';

  @override
  String get priorityUrgent => 'عاجلة';

  @override
  String minutesShort(int count) {
    return '$count د';
  }

  @override
  String hoursShort(int count) {
    return '$count س';
  }

  @override
  String daysShort(int count) {
    return '$count ي';
  }

  @override
  String slaDueIn(String time) {
    return 'خلال $time';
  }

  @override
  String slaOverdue(String time) {
    return 'متأخرة $time';
  }

  @override
  String get slaPaused => 'متوقف';

  @override
  String get slaMet => 'في الوقت';

  @override
  String slaFirstResponseDue(String time) {
    return 'الرد الأول مطلوب خلال $time';
  }

  @override
  String slaResolutionDue(String time) {
    return 'الحل مطلوب خلال $time';
  }

  @override
  String slaFirstResponseOverdue(String time) {
    return 'الرد الأول متأخر $time';
  }

  @override
  String slaResolutionOverdue(String time) {
    return 'الحل متأخر $time';
  }

  @override
  String get justNow => 'الآن';

  @override
  String agoMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'قبل $count دقيقة',
      few: 'قبل $count دقائق',
      two: 'قبل دقيقتين',
      one: 'قبل دقيقة',
    );
    return '$_temp0';
  }

  @override
  String agoHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'قبل $count ساعة',
      few: 'قبل $count ساعات',
      two: 'قبل ساعتين',
      one: 'قبل ساعة',
    );
    return '$_temp0';
  }

  @override
  String agoDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'قبل $count يومًا',
      few: 'قبل $count أيام',
      two: 'قبل يومين',
      one: 'أمس',
    );
    return '$_temp0';
  }

  @override
  String ticketTitle(String number) {
    return 'التذكرة رقم $number';
  }

  @override
  String get selectTicket => 'اختر تذكرة لعرضها هنا.';

  @override
  String get reply => 'رد';

  @override
  String get note => 'ملاحظة داخلية';

  @override
  String replyHint(String name) {
    return 'الرد على $name';
  }

  @override
  String get noteHint => 'ملاحظة لفريقك. لن يراها العميل.';

  @override
  String get send => 'إرسال';

  @override
  String sendAndSet(String status) {
    return 'إرسال وتغيير الحالة إلى $status';
  }

  @override
  String get addNote => 'إضافة ملاحظة';

  @override
  String get internalNote => 'ملاحظة داخلية';

  @override
  String get ticketActions => 'إجراءات التذكرة';

  @override
  String get status => 'الحالة';

  @override
  String get priority => 'الأولوية';

  @override
  String get tags => 'الوسوم';

  @override
  String get assignee => 'المُسنَد إليه';

  @override
  String get team => 'الفريق';

  @override
  String get requester => 'العميل';

  @override
  String get assignToMe => 'إسناد إليّ';

  @override
  String get assignTo => 'إسناد إلى…';

  @override
  String get unassign => 'إلغاء الإسناد';

  @override
  String get watch => 'متابعة';

  @override
  String get stopWatching => 'إيقاف المتابعة';

  @override
  String get watchers => 'المتابعون';

  @override
  String get addTag => 'إضافة وسم';

  @override
  String get save => 'حفظ';

  @override
  String get firstResponse => 'الرد الأول';

  @override
  String get resolution => 'الحل';

  @override
  String get slaDone => 'تم';

  @override
  String get customFields => 'التفاصيل';

  @override
  String get noLongerAvailable => 'هذه التذكرة لم تعد متاحة.';

  @override
  String get closedNotice => 'هذه التذكرة مغلقة. الردود تفتح محادثة جديدة على الويب.';

  @override
  String get staleTicket => 'غيّر شخص آخر هذه التذكرة. أُعيد تحميلها بتغييره.';

  @override
  String get applyAgain => 'تطبيق تغييري مجددًا';

  @override
  String get dismiss => 'تجاهل';

  @override
  String get mentionSuggestions => 'أشخاص للإشارة إليهم';

  @override
  String get readOnly => 'يمكنك قراءة التذاكر دون تعديلها.';

  @override
  String eventCreated(String actor) {
    return 'أنشأ $actor التذكرة';
  }

  @override
  String eventSubjectChanged(String actor, String from, String to) {
    return 'غيّر $actor الموضوع من «$from» إلى «$to»';
  }

  @override
  String eventStatusChanged(String actor, String from, String to) {
    return 'غيّر $actor الحالة من $from إلى $to';
  }

  @override
  String eventPriorityChanged(String actor, String from, String to) {
    return 'غيّر $actor الأولوية من $from إلى $to';
  }

  @override
  String eventTypeChanged(String actor, String from, String to) {
    return 'غيّر $actor النوع من $from إلى $to';
  }

  @override
  String eventAssigneeChanged(String actor, String from, String to) {
    return 'غيّر $actor المُسنَد إليه من $from إلى $to';
  }

  @override
  String eventTeamChanged(String actor, String from, String to) {
    return 'غيّر $actor الفريق من $from إلى $to';
  }

  @override
  String eventTagsChanged(String actor, String from, String to) {
    return 'غيّر $actor الوسوم من $from إلى $to';
  }

  @override
  String eventCustomFieldChanged(String actor, String field, String from, String to) {
    return 'غيّر $actor الحقل $field من $from إلى $to';
  }

  @override
  String eventMergedInto(String actor, String to) {
    return 'دمج $actor هذه التذكرة في $to';
  }

  @override
  String eventMergedFrom(String actor, String to) {
    return 'دمج $actor التذكرة $to في هذه التذكرة';
  }

  @override
  String eventSlaBreached(String to) {
    return 'تم تجاوز موعد $to';
  }

  @override
  String eventCsatSubmitted(String actor, String to) {
    return 'قيّم $actor الدعم بـ $to من 5';
  }

  @override
  String eventOther(String actor) {
    return 'حدّث $actor التذكرة';
  }

  @override
  String get actorStaff => 'موظف دعم';

  @override
  String get actorCustomer => 'العميل';

  @override
  String get actorSystem => 'NexDesk';

  @override
  String get actorApiKey => 'تكامل خارجي';

  @override
  String get none => 'لا شيء';

  @override
  String get attach => 'إرفاق ملف';

  @override
  String get takePhoto => 'التقاط صورة';

  @override
  String get choosePhoto => 'اختيار صورة';

  @override
  String get chooseFile => 'اختيار ملف';

  @override
  String fileTooLarge(String limit) {
    return 'يتجاوز الحد المسموح ($limit)';
  }

  @override
  String get fileTypeBlocked => 'لا يمكن إرسال هذا النوع من الملفات';

  @override
  String get invalidAttachment => 'ارفع هذا الملف مرة أخرى';

  @override
  String get fileNoLongerAvailable => 'الملف لم يعد متاحًا';

  @override
  String get cannotOpenFile => 'لا يوجد تطبيق على هذا الهاتف يمكنه فتح هذا الملف.';

  @override
  String removeAttachment(String name) {
    return 'إزالة $name';
  }

  @override
  String get markAllRead => 'تعليم الكل كمقروء';

  @override
  String get metricFirstResponse => 'أول رد';

  @override
  String get metricResolution => 'الحل';

  @override
  String get notificationsEmpty => 'لا جديد لديك.';

  @override
  String get someone => 'شخص ما';

  @override
  String get open => 'فتح';

  @override
  String notificationsUnread(int count) {
    return 'الإشعارات، $count غير مقروءة';
  }

  @override
  String notifyTicketAssigned(String actor, int number) {
    return 'أسند $actor إليك التذكرة رقم $number';
  }

  @override
  String notifyTicketReply(String actor, int number) {
    return 'ردّ $actor على التذكرة رقم $number';
  }

  @override
  String notifyTicketNote(String actor, int number) {
    return 'أضاف $actor ملاحظة على التذكرة رقم $number';
  }

  @override
  String notifySlaWarning(int number, String metric) {
    return 'التذكرة رقم $number تقترب من موعد $metric';
  }

  @override
  String notifySlaBreach(int number, String metric) {
    return 'التذكرة رقم $number تجاوزت موعد $metric';
  }

  @override
  String notifyAutomation(String actor, int number) {
    return '$actor: التذكرة رقم $number';
  }

  @override
  String notifyMention(String actor, int number) {
    return 'أشار إليك $actor في التذكرة رقم $number';
  }

  @override
  String uploading(int percent) {
    return 'جارٍ الرفع، $percent٪';
  }
}
