import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('ar'), Locale('en')];

  /// The product name.
  ///
  /// In en, this message translates to:
  /// **'NexDesk'**
  String get appName;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Your help desk, in your pocket.'**
  String get tagline;

  /// No description provided for @signInTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to your workspace'**
  String get signInTitle;

  /// No description provided for @signInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use the email and password you use on the web.'**
  String get signInSubtitle;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot your password?'**
  String get forgotPassword;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address.'**
  String get emailRequired;

  /// No description provided for @emailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get emailInvalid;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your password.'**
  String get passwordRequired;

  /// No description provided for @errorInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'The email or password is incorrect.'**
  String get errorInvalidCredentials;

  /// No description provided for @errorAccountLocked.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Try again in a few minutes.'**
  String get errorAccountLocked;

  /// No description provided for @errorEmailNotVerified.
  ///
  /// In en, this message translates to:
  /// **'Confirm your email address first, using the link we sent you.'**
  String get errorEmailNotVerified;

  /// No description provided for @openEmailVerification.
  ///
  /// In en, this message translates to:
  /// **'Resend the link on the web'**
  String get openEmailVerification;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Can\'t reach NexDesk. Check your connection and try again.'**
  String get errorNetwork;

  /// No description provided for @errorUnexpected.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Try again.'**
  String get errorUnexpected;

  /// No description provided for @errorReference.
  ///
  /// In en, this message translates to:
  /// **'Reference: {id}'**
  String errorReference(String id);

  /// No description provided for @sessionEnded.
  ///
  /// In en, this message translates to:
  /// **'Your session ended. Sign in again.'**
  String get sessionEnded;

  /// No description provided for @wakingServer.
  ///
  /// In en, this message translates to:
  /// **'Waking the server, this can take up to a minute…'**
  String get wakingServer;

  /// No description provided for @blockedSuspendedTitle.
  ///
  /// In en, this message translates to:
  /// **'This workspace is suspended'**
  String get blockedSuspendedTitle;

  /// No description provided for @blockedSuspendedBody.
  ///
  /// In en, this message translates to:
  /// **'Ask your workspace owner to sort out the account on the web, then sign in again.'**
  String get blockedSuspendedBody;

  /// No description provided for @blockedDisabledTitle.
  ///
  /// In en, this message translates to:
  /// **'Your account is deactivated'**
  String get blockedDisabledTitle;

  /// No description provided for @blockedDisabledBody.
  ///
  /// In en, this message translates to:
  /// **'An admin of your workspace can reactivate it.'**
  String get blockedDisabledBody;

  /// No description provided for @blockedAdminTitle.
  ///
  /// In en, this message translates to:
  /// **'The platform console is on the web'**
  String get blockedAdminTitle;

  /// No description provided for @blockedAdminBody.
  ///
  /// In en, this message translates to:
  /// **'The app is for support teams. Platform admins sign in on the web.'**
  String get blockedAdminBody;

  /// No description provided for @blockedUpdateTitle.
  ///
  /// In en, this message translates to:
  /// **'Update NexDesk'**
  String get blockedUpdateTitle;

  /// No description provided for @blockedUpdateBody.
  ///
  /// In en, this message translates to:
  /// **'This version no longer works with NexDesk. Install the latest version to carry on.'**
  String get blockedUpdateBody;

  /// No description provided for @signInAnother.
  ///
  /// In en, this message translates to:
  /// **'Sign in with another account'**
  String get signInAnother;

  /// No description provided for @openWeb.
  ///
  /// In en, this message translates to:
  /// **'Open NexDesk on the web'**
  String get openWeb;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageArabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get languageArabic;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'This part of the app is on its way.'**
  String get comingSoon;

  /// No description provided for @inbox.
  ///
  /// In en, this message translates to:
  /// **'Inbox'**
  String get inbox;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @workspace.
  ///
  /// In en, this message translates to:
  /// **'Workspace'**
  String get workspace;

  /// No description provided for @role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get role;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @signOutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Sign out of NexDesk on this phone?'**
  String get signOutConfirm;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @tabMine.
  ///
  /// In en, this message translates to:
  /// **'Mine'**
  String get tabMine;

  /// No description provided for @tabUnassigned.
  ///
  /// In en, this message translates to:
  /// **'Unassigned'**
  String get tabUnassigned;

  /// No description provided for @tabSla.
  ///
  /// In en, this message translates to:
  /// **'SLA'**
  String get tabSla;

  /// No description provided for @tabAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get tabAll;

  /// No description provided for @slaBreached.
  ///
  /// In en, this message translates to:
  /// **'Breached'**
  String get slaBreached;

  /// No description provided for @slaAtRisk.
  ///
  /// In en, this message translates to:
  /// **'At risk'**
  String get slaAtRisk;

  /// No description provided for @searchTickets.
  ///
  /// In en, this message translates to:
  /// **'Search tickets'**
  String get searchTickets;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Subject, message, requester or #number'**
  String get searchHint;

  /// No description provided for @savedViews.
  ///
  /// In en, this message translates to:
  /// **'Saved views'**
  String get savedViews;

  /// No description provided for @noSavedViews.
  ///
  /// In en, this message translates to:
  /// **'No saved views yet. Save one on the web and it shows here.'**
  String get noSavedViews;

  /// No description provided for @sharedView.
  ///
  /// In en, this message translates to:
  /// **'Shared'**
  String get sharedView;

  /// No description provided for @clearView.
  ///
  /// In en, this message translates to:
  /// **'Back to the inbox'**
  String get clearView;

  /// No description provided for @emptyMine.
  ///
  /// In en, this message translates to:
  /// **'Nothing assigned to you. Enjoy the quiet.'**
  String get emptyMine;

  /// No description provided for @emptyList.
  ///
  /// In en, this message translates to:
  /// **'No tickets here.'**
  String get emptyList;

  /// No description provided for @emptySearch.
  ///
  /// In en, this message translates to:
  /// **'No tickets match.'**
  String get emptySearch;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// No description provided for @offlineSince.
  ///
  /// In en, this message translates to:
  /// **'Offline. Showing tickets from {time}.'**
  String offlineSince(String time);

  /// No description provided for @ticketCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No tickets} =1{1 ticket} other{{count} tickets}}'**
  String ticketCount(int count);

  /// No description provided for @unassignedPerson.
  ///
  /// In en, this message translates to:
  /// **'Unassigned'**
  String get unassignedPerson;

  /// No description provided for @statusNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get statusNew;

  /// No description provided for @statusOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get statusOpen;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// No description provided for @statusOnHold.
  ///
  /// In en, this message translates to:
  /// **'On hold'**
  String get statusOnHold;

  /// No description provided for @statusSolved.
  ///
  /// In en, this message translates to:
  /// **'Solved'**
  String get statusSolved;

  /// No description provided for @statusClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get statusClosed;

  /// No description provided for @priorityLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get priorityLow;

  /// No description provided for @priorityNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get priorityNormal;

  /// No description provided for @priorityHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get priorityHigh;

  /// No description provided for @priorityUrgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get priorityUrgent;

  /// No description provided for @minutesShort.
  ///
  /// In en, this message translates to:
  /// **'{count} min'**
  String minutesShort(int count);

  /// No description provided for @hoursShort.
  ///
  /// In en, this message translates to:
  /// **'{count} h'**
  String hoursShort(int count);

  /// No description provided for @daysShort.
  ///
  /// In en, this message translates to:
  /// **'{count} d'**
  String daysShort(int count);

  /// No description provided for @slaDueIn.
  ///
  /// In en, this message translates to:
  /// **'Due in {time}'**
  String slaDueIn(String time);

  /// No description provided for @slaOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue {time}'**
  String slaOverdue(String time);

  /// No description provided for @slaPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get slaPaused;

  /// No description provided for @slaMet.
  ///
  /// In en, this message translates to:
  /// **'On time'**
  String get slaMet;

  /// No description provided for @slaFirstResponseDue.
  ///
  /// In en, this message translates to:
  /// **'First response due in {time}'**
  String slaFirstResponseDue(String time);

  /// No description provided for @slaResolutionDue.
  ///
  /// In en, this message translates to:
  /// **'Resolution due in {time}'**
  String slaResolutionDue(String time);

  /// No description provided for @slaFirstResponseOverdue.
  ///
  /// In en, this message translates to:
  /// **'First response overdue by {time}'**
  String slaFirstResponseOverdue(String time);

  /// No description provided for @slaResolutionOverdue.
  ///
  /// In en, this message translates to:
  /// **'Resolution overdue by {time}'**
  String slaResolutionOverdue(String time);

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get justNow;

  /// No description provided for @agoMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 minute ago} other{{count} minutes ago}}'**
  String agoMinutes(int count);

  /// No description provided for @agoHours.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 hour ago} other{{count} hours ago}}'**
  String agoHours(int count);

  /// No description provided for @agoDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{yesterday} other{{count} days ago}}'**
  String agoDays(int count);

  /// No description provided for @ticketTitle.
  ///
  /// In en, this message translates to:
  /// **'Ticket #{number}'**
  String ticketTitle(String number);

  /// No description provided for @selectTicket.
  ///
  /// In en, this message translates to:
  /// **'Choose a ticket to see it here.'**
  String get selectTicket;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
