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

  /// No description provided for @reply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get reply;

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Internal note'**
  String get note;

  /// No description provided for @replyHint.
  ///
  /// In en, this message translates to:
  /// **'Reply to {name}'**
  String replyHint(String name);

  /// No description provided for @noteHint.
  ///
  /// In en, this message translates to:
  /// **'Note for your team. The customer won\'t see it.'**
  String get noteHint;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @sendAndSet.
  ///
  /// In en, this message translates to:
  /// **'Send and set to {status}'**
  String sendAndSet(String status);

  /// No description provided for @addNote.
  ///
  /// In en, this message translates to:
  /// **'Add note'**
  String get addNote;

  /// No description provided for @internalNote.
  ///
  /// In en, this message translates to:
  /// **'Internal note'**
  String get internalNote;

  /// No description provided for @ticketActions.
  ///
  /// In en, this message translates to:
  /// **'Ticket actions'**
  String get ticketActions;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @priority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get priority;

  /// No description provided for @tags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tags;

  /// No description provided for @assignee.
  ///
  /// In en, this message translates to:
  /// **'Assignee'**
  String get assignee;

  /// No description provided for @team.
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get team;

  /// No description provided for @requester.
  ///
  /// In en, this message translates to:
  /// **'Requester'**
  String get requester;

  /// No description provided for @assignToMe.
  ///
  /// In en, this message translates to:
  /// **'Assign to me'**
  String get assignToMe;

  /// No description provided for @assignTo.
  ///
  /// In en, this message translates to:
  /// **'Assign to…'**
  String get assignTo;

  /// No description provided for @unassign.
  ///
  /// In en, this message translates to:
  /// **'Unassign'**
  String get unassign;

  /// No description provided for @watch.
  ///
  /// In en, this message translates to:
  /// **'Watch'**
  String get watch;

  /// No description provided for @stopWatching.
  ///
  /// In en, this message translates to:
  /// **'Stop watching'**
  String get stopWatching;

  /// No description provided for @watchers.
  ///
  /// In en, this message translates to:
  /// **'Watchers'**
  String get watchers;

  /// No description provided for @addTag.
  ///
  /// In en, this message translates to:
  /// **'Add a tag'**
  String get addTag;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @firstResponse.
  ///
  /// In en, this message translates to:
  /// **'First response'**
  String get firstResponse;

  /// No description provided for @resolution.
  ///
  /// In en, this message translates to:
  /// **'Resolution'**
  String get resolution;

  /// No description provided for @slaDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get slaDone;

  /// No description provided for @customFields.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get customFields;

  /// No description provided for @noLongerAvailable.
  ///
  /// In en, this message translates to:
  /// **'This ticket is no longer available.'**
  String get noLongerAvailable;

  /// No description provided for @closedNotice.
  ///
  /// In en, this message translates to:
  /// **'This ticket is closed. Replies open a new conversation on the web.'**
  String get closedNotice;

  /// No description provided for @staleTicket.
  ///
  /// In en, this message translates to:
  /// **'Someone else changed this ticket. It has been reloaded with their change.'**
  String get staleTicket;

  /// No description provided for @applyAgain.
  ///
  /// In en, this message translates to:
  /// **'Apply mine again'**
  String get applyAgain;

  /// No description provided for @dismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// No description provided for @mentionSuggestions.
  ///
  /// In en, this message translates to:
  /// **'People to mention'**
  String get mentionSuggestions;

  /// No description provided for @readOnly.
  ///
  /// In en, this message translates to:
  /// **'You can read tickets but not change them.'**
  String get readOnly;

  /// No description provided for @eventCreated.
  ///
  /// In en, this message translates to:
  /// **'{actor} created the ticket'**
  String eventCreated(String actor);

  /// No description provided for @eventSubjectChanged.
  ///
  /// In en, this message translates to:
  /// **'{actor} changed the subject from “{from}” to “{to}”'**
  String eventSubjectChanged(String actor, String from, String to);

  /// No description provided for @eventStatusChanged.
  ///
  /// In en, this message translates to:
  /// **'{actor} changed the status from {from} to {to}'**
  String eventStatusChanged(String actor, String from, String to);

  /// No description provided for @eventPriorityChanged.
  ///
  /// In en, this message translates to:
  /// **'{actor} changed the priority from {from} to {to}'**
  String eventPriorityChanged(String actor, String from, String to);

  /// No description provided for @eventTypeChanged.
  ///
  /// In en, this message translates to:
  /// **'{actor} changed the type from {from} to {to}'**
  String eventTypeChanged(String actor, String from, String to);

  /// No description provided for @eventAssigneeChanged.
  ///
  /// In en, this message translates to:
  /// **'{actor} changed the assignee from {from} to {to}'**
  String eventAssigneeChanged(String actor, String from, String to);

  /// No description provided for @eventTeamChanged.
  ///
  /// In en, this message translates to:
  /// **'{actor} changed the team from {from} to {to}'**
  String eventTeamChanged(String actor, String from, String to);

  /// No description provided for @eventTagsChanged.
  ///
  /// In en, this message translates to:
  /// **'{actor} changed the tags from {from} to {to}'**
  String eventTagsChanged(String actor, String from, String to);

  /// No description provided for @eventCustomFieldChanged.
  ///
  /// In en, this message translates to:
  /// **'{actor} changed {field} from {from} to {to}'**
  String eventCustomFieldChanged(String actor, String field, String from, String to);

  /// No description provided for @eventMergedInto.
  ///
  /// In en, this message translates to:
  /// **'{actor} merged this ticket into {to}'**
  String eventMergedInto(String actor, String to);

  /// No description provided for @eventMergedFrom.
  ///
  /// In en, this message translates to:
  /// **'{actor} merged ticket {to} into this one'**
  String eventMergedFrom(String actor, String to);

  /// No description provided for @eventSlaBreached.
  ///
  /// In en, this message translates to:
  /// **'The {to} deadline was missed'**
  String eventSlaBreached(String to);

  /// No description provided for @eventCsatSubmitted.
  ///
  /// In en, this message translates to:
  /// **'{actor} rated the support {to} out of 5'**
  String eventCsatSubmitted(String actor, String to);

  /// No description provided for @eventOther.
  ///
  /// In en, this message translates to:
  /// **'{actor} updated the ticket'**
  String eventOther(String actor);

  /// No description provided for @actorStaff.
  ///
  /// In en, this message translates to:
  /// **'An agent'**
  String get actorStaff;

  /// No description provided for @actorCustomer.
  ///
  /// In en, this message translates to:
  /// **'The customer'**
  String get actorCustomer;

  /// No description provided for @actorSystem.
  ///
  /// In en, this message translates to:
  /// **'NexDesk'**
  String get actorSystem;

  /// No description provided for @actorApiKey.
  ///
  /// In en, this message translates to:
  /// **'An integration'**
  String get actorApiKey;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'none'**
  String get none;

  /// No description provided for @attach.
  ///
  /// In en, this message translates to:
  /// **'Attach a file'**
  String get attach;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get takePhoto;

  /// No description provided for @choosePhoto.
  ///
  /// In en, this message translates to:
  /// **'Choose a photo'**
  String get choosePhoto;

  /// No description provided for @chooseFile.
  ///
  /// In en, this message translates to:
  /// **'Choose a file'**
  String get chooseFile;

  /// No description provided for @fileTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Over the {limit} limit'**
  String fileTooLarge(String limit);

  /// No description provided for @fileTypeBlocked.
  ///
  /// In en, this message translates to:
  /// **'This type of file can\'t be sent'**
  String get fileTypeBlocked;

  /// No description provided for @invalidAttachment.
  ///
  /// In en, this message translates to:
  /// **'Upload this file again'**
  String get invalidAttachment;

  /// No description provided for @fileNoLongerAvailable.
  ///
  /// In en, this message translates to:
  /// **'File no longer available'**
  String get fileNoLongerAvailable;

  /// No description provided for @cannotOpenFile.
  ///
  /// In en, this message translates to:
  /// **'No app on this phone can open this file.'**
  String get cannotOpenFile;

  /// No description provided for @removeAttachment.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}'**
  String removeAttachment(String name);

  /// No description provided for @newTicket.
  ///
  /// In en, this message translates to:
  /// **'New ticket'**
  String get newTicket;

  /// No description provided for @newTicketSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Record a request you received by phone, chat or in person.'**
  String get newTicketSubtitle;

  /// No description provided for @subject.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get subject;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @requesterEmail.
  ///
  /// In en, this message translates to:
  /// **'Customer email'**
  String get requesterEmail;

  /// No description provided for @requesterHint.
  ///
  /// In en, this message translates to:
  /// **'Start typing to find an existing customer.'**
  String get requesterHint;

  /// No description provided for @requesterName.
  ///
  /// In en, this message translates to:
  /// **'Customer name (optional)'**
  String get requesterName;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @createTicket.
  ///
  /// In en, this message translates to:
  /// **'Create ticket'**
  String get createTicket;

  /// No description provided for @ticketCreated.
  ///
  /// In en, this message translates to:
  /// **'Ticket #{number} created.'**
  String ticketCreated(int number);

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'Fill this in.'**
  String get fieldRequired;

  /// No description provided for @typeQuestion.
  ///
  /// In en, this message translates to:
  /// **'Question'**
  String get typeQuestion;

  /// No description provided for @typeIncident.
  ///
  /// In en, this message translates to:
  /// **'Incident'**
  String get typeIncident;

  /// No description provided for @typeProblem.
  ///
  /// In en, this message translates to:
  /// **'Problem'**
  String get typeProblem;

  /// No description provided for @typeTask.
  ///
  /// In en, this message translates to:
  /// **'Task'**
  String get typeTask;

  /// No description provided for @availability.
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get availability;

  /// No description provided for @availabilityOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get availabilityOnline;

  /// No description provided for @availabilityAway.
  ///
  /// In en, this message translates to:
  /// **'Away'**
  String get availabilityAway;

  /// No description provided for @availabilityOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get availabilityOffline;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @appLock.
  ///
  /// In en, this message translates to:
  /// **'Lock with fingerprint or face'**
  String get appLock;

  /// No description provided for @appLockHint.
  ///
  /// In en, this message translates to:
  /// **'Asks again after 5 minutes away.'**
  String get appLockHint;

  /// No description provided for @appLockUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Set up a fingerprint, face or screen lock on this phone to use this.'**
  String get appLockUnavailable;

  /// No description provided for @unlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get unlock;

  /// No description provided for @lockedTitle.
  ///
  /// In en, this message translates to:
  /// **'NexDesk is locked'**
  String get lockedTitle;

  /// No description provided for @unlockReason.
  ///
  /// In en, this message translates to:
  /// **'Unlock NexDesk'**
  String get unlockReason;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String version(String version);

  /// No description provided for @aboutText.
  ///
  /// In en, this message translates to:
  /// **'NexDesk is a help desk for support teams: tickets, SLAs and a customer help centre. This app is for agents on the move; settings and reports live on the web.'**
  String get aboutText;

  /// No description provided for @openOnWeb.
  ///
  /// In en, this message translates to:
  /// **'Open NexDesk on the web'**
  String get openOnWeb;

  /// No description provided for @notificationSettings.
  ///
  /// In en, this message translates to:
  /// **'Notification settings'**
  String get notificationSettings;

  /// No description provided for @notificationSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose what you want to hear about, and where.'**
  String get notificationSettingsSubtitle;

  /// No description provided for @channelInApp.
  ///
  /// In en, this message translates to:
  /// **'In the app'**
  String get channelInApp;

  /// No description provided for @channelEmail.
  ///
  /// In en, this message translates to:
  /// **'By email'**
  String get channelEmail;

  /// No description provided for @channelPush.
  ///
  /// In en, this message translates to:
  /// **'On my phone'**
  String get channelPush;

  /// No description provided for @pushUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Push isn\'t set up in this build, so this phone gets no push notifications.'**
  String get pushUnavailable;

  /// No description provided for @prefTicketAssigned.
  ///
  /// In en, this message translates to:
  /// **'A ticket is assigned to me'**
  String get prefTicketAssigned;

  /// No description provided for @prefTicketReply.
  ///
  /// In en, this message translates to:
  /// **'Someone replies on a ticket I follow'**
  String get prefTicketReply;

  /// No description provided for @prefTicketNote.
  ///
  /// In en, this message translates to:
  /// **'Someone adds an internal note on a ticket I follow'**
  String get prefTicketNote;

  /// No description provided for @prefSlaWarning.
  ///
  /// In en, this message translates to:
  /// **'A deadline of my ticket is close'**
  String get prefSlaWarning;

  /// No description provided for @prefSlaBreach.
  ///
  /// In en, this message translates to:
  /// **'A deadline is missed'**
  String get prefSlaBreach;

  /// No description provided for @prefAutomation.
  ///
  /// In en, this message translates to:
  /// **'An automation rule notifies me'**
  String get prefAutomation;

  /// No description provided for @prefMention.
  ///
  /// In en, this message translates to:
  /// **'A teammate mentions me'**
  String get prefMention;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get markAllRead;

  /// No description provided for @metricFirstResponse.
  ///
  /// In en, this message translates to:
  /// **'first response'**
  String get metricFirstResponse;

  /// No description provided for @metricResolution.
  ///
  /// In en, this message translates to:
  /// **'resolution'**
  String get metricResolution;

  /// No description provided for @notificationsEmpty.
  ///
  /// In en, this message translates to:
  /// **'You are all caught up.'**
  String get notificationsEmpty;

  /// No description provided for @someone.
  ///
  /// In en, this message translates to:
  /// **'Someone'**
  String get someone;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @notificationsUnread.
  ///
  /// In en, this message translates to:
  /// **'Notifications, {count} unread'**
  String notificationsUnread(int count);

  /// No description provided for @notifyTicketAssigned.
  ///
  /// In en, this message translates to:
  /// **'{actor} assigned ticket #{number} to you'**
  String notifyTicketAssigned(String actor, int number);

  /// No description provided for @notifyTicketReply.
  ///
  /// In en, this message translates to:
  /// **'{actor} replied on ticket #{number}'**
  String notifyTicketReply(String actor, int number);

  /// No description provided for @notifyTicketNote.
  ///
  /// In en, this message translates to:
  /// **'{actor} added a note on ticket #{number}'**
  String notifyTicketNote(String actor, int number);

  /// No description provided for @notifySlaWarning.
  ///
  /// In en, this message translates to:
  /// **'Ticket #{number} is close to its {metric} deadline'**
  String notifySlaWarning(int number, String metric);

  /// No description provided for @notifySlaBreach.
  ///
  /// In en, this message translates to:
  /// **'Ticket #{number} missed its {metric} deadline'**
  String notifySlaBreach(int number, String metric);

  /// No description provided for @notifyAutomation.
  ///
  /// In en, this message translates to:
  /// **'{actor}: ticket #{number}'**
  String notifyAutomation(String actor, int number);

  /// No description provided for @notifyMention.
  ///
  /// In en, this message translates to:
  /// **'{actor} mentioned you on ticket #{number}'**
  String notifyMention(String actor, int number);

  /// No description provided for @uploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading, {percent}%'**
  String uploading(int percent);
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
