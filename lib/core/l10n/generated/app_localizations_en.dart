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
  String get inbox => 'Inbox';

  @override
  String get notifications => 'Notifications';

  @override
  String get profile => 'Profile';

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

  @override
  String get tabMine => 'Mine';

  @override
  String get tabUnassigned => 'Unassigned';

  @override
  String get tabSla => 'SLA';

  @override
  String get tabAll => 'All';

  @override
  String get slaBreached => 'Breached';

  @override
  String get slaAtRisk => 'At risk';

  @override
  String get searchTickets => 'Search tickets';

  @override
  String get searchHint => 'Subject, message, requester or #number';

  @override
  String get savedViews => 'Saved views';

  @override
  String get noSavedViews => 'No saved views yet. Save one on the web and it shows here.';

  @override
  String get sharedView => 'Shared';

  @override
  String get clearView => 'Back to the inbox';

  @override
  String get emptyMine => 'Nothing assigned to you. Enjoy the quiet.';

  @override
  String get emptyList => 'No tickets here.';

  @override
  String get emptySearch => 'No tickets match.';

  @override
  String get retry => 'Try again';

  @override
  String offlineSince(String time) {
    return 'Offline. Showing tickets from $time.';
  }

  @override
  String ticketCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tickets',
      one: '1 ticket',
      zero: 'No tickets',
    );
    return '$_temp0';
  }

  @override
  String get unassignedPerson => 'Unassigned';

  @override
  String get statusNew => 'New';

  @override
  String get statusOpen => 'Open';

  @override
  String get statusPending => 'Pending';

  @override
  String get statusOnHold => 'On hold';

  @override
  String get statusSolved => 'Solved';

  @override
  String get statusClosed => 'Closed';

  @override
  String get priorityLow => 'Low';

  @override
  String get priorityNormal => 'Normal';

  @override
  String get priorityHigh => 'High';

  @override
  String get priorityUrgent => 'Urgent';

  @override
  String minutesShort(int count) {
    return '$count min';
  }

  @override
  String hoursShort(int count) {
    return '$count h';
  }

  @override
  String daysShort(int count) {
    return '$count d';
  }

  @override
  String slaDueIn(String time) {
    return 'Due in $time';
  }

  @override
  String slaOverdue(String time) {
    return 'Overdue $time';
  }

  @override
  String get slaPaused => 'Paused';

  @override
  String get slaMet => 'On time';

  @override
  String slaFirstResponseDue(String time) {
    return 'First response due in $time';
  }

  @override
  String slaResolutionDue(String time) {
    return 'Resolution due in $time';
  }

  @override
  String slaFirstResponseOverdue(String time) {
    return 'First response overdue by $time';
  }

  @override
  String slaResolutionOverdue(String time) {
    return 'Resolution overdue by $time';
  }

  @override
  String get justNow => 'just now';

  @override
  String agoMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes ago',
      one: '1 minute ago',
    );
    return '$_temp0';
  }

  @override
  String agoHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours ago',
      one: '1 hour ago',
    );
    return '$_temp0';
  }

  @override
  String agoDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: 'yesterday',
    );
    return '$_temp0';
  }

  @override
  String ticketTitle(String number) {
    return 'Ticket #$number';
  }

  @override
  String get selectTicket => 'Choose a ticket to see it here.';

  @override
  String get reply => 'Reply';

  @override
  String get note => 'Internal note';

  @override
  String replyHint(String name) {
    return 'Reply to $name';
  }

  @override
  String get noteHint => 'Note for your team. The customer won\'t see it.';

  @override
  String get send => 'Send';

  @override
  String sendAndSet(String status) {
    return 'Send and set to $status';
  }

  @override
  String get addNote => 'Add note';

  @override
  String get internalNote => 'Internal note';

  @override
  String get ticketActions => 'Ticket actions';

  @override
  String get status => 'Status';

  @override
  String get priority => 'Priority';

  @override
  String get tags => 'Tags';

  @override
  String get assignee => 'Assignee';

  @override
  String get team => 'Team';

  @override
  String get requester => 'Requester';

  @override
  String get assignToMe => 'Assign to me';

  @override
  String get assignTo => 'Assign to…';

  @override
  String get unassign => 'Unassign';

  @override
  String get watch => 'Watch';

  @override
  String get stopWatching => 'Stop watching';

  @override
  String get watchers => 'Watchers';

  @override
  String get addTag => 'Add a tag';

  @override
  String get save => 'Save';

  @override
  String get firstResponse => 'First response';

  @override
  String get resolution => 'Resolution';

  @override
  String get slaDone => 'Done';

  @override
  String get customFields => 'Details';

  @override
  String get noLongerAvailable => 'This ticket is no longer available.';

  @override
  String get closedNotice => 'This ticket is closed. Replies open a new conversation on the web.';

  @override
  String get staleTicket => 'Someone else changed this ticket. It has been reloaded with their change.';

  @override
  String get applyAgain => 'Apply mine again';

  @override
  String get dismiss => 'Dismiss';

  @override
  String get mentionSuggestions => 'People to mention';

  @override
  String get readOnly => 'You can read tickets but not change them.';

  @override
  String eventCreated(String actor) {
    return '$actor created the ticket';
  }

  @override
  String eventSubjectChanged(String actor, String from, String to) {
    return '$actor changed the subject from “$from” to “$to”';
  }

  @override
  String eventStatusChanged(String actor, String from, String to) {
    return '$actor changed the status from $from to $to';
  }

  @override
  String eventPriorityChanged(String actor, String from, String to) {
    return '$actor changed the priority from $from to $to';
  }

  @override
  String eventTypeChanged(String actor, String from, String to) {
    return '$actor changed the type from $from to $to';
  }

  @override
  String eventAssigneeChanged(String actor, String from, String to) {
    return '$actor changed the assignee from $from to $to';
  }

  @override
  String eventTeamChanged(String actor, String from, String to) {
    return '$actor changed the team from $from to $to';
  }

  @override
  String eventTagsChanged(String actor, String from, String to) {
    return '$actor changed the tags from $from to $to';
  }

  @override
  String eventCustomFieldChanged(String actor, String field, String from, String to) {
    return '$actor changed $field from $from to $to';
  }

  @override
  String eventMergedInto(String actor, String to) {
    return '$actor merged this ticket into $to';
  }

  @override
  String eventMergedFrom(String actor, String to) {
    return '$actor merged ticket $to into this one';
  }

  @override
  String eventSlaBreached(String to) {
    return 'The $to deadline was missed';
  }

  @override
  String eventCsatSubmitted(String actor, String to) {
    return '$actor rated the support $to out of 5';
  }

  @override
  String eventOther(String actor) {
    return '$actor updated the ticket';
  }

  @override
  String get actorStaff => 'An agent';

  @override
  String get actorCustomer => 'The customer';

  @override
  String get actorSystem => 'NexDesk';

  @override
  String get actorApiKey => 'An integration';

  @override
  String get none => 'none';

  @override
  String get attach => 'Attach a file';

  @override
  String get insertArticle => 'Insert a help article';

  @override
  String get linkArticleTitle => 'Link a help article';

  @override
  String get searchArticles => 'Search published articles';

  @override
  String get noArticles => 'No published article matches.';

  @override
  String get takePhoto => 'Take a photo';

  @override
  String get choosePhoto => 'Choose a photo';

  @override
  String get chooseFile => 'Choose a file';

  @override
  String fileTooLarge(String limit) {
    return 'Over the $limit limit';
  }

  @override
  String get fileTypeBlocked => 'This type of file can\'t be sent';

  @override
  String get invalidAttachment => 'Upload this file again';

  @override
  String get fileNoLongerAvailable => 'File no longer available';

  @override
  String get cannotOpenFile => 'No app on this phone can open this file.';

  @override
  String removeAttachment(String name) {
    return 'Remove $name';
  }

  @override
  String get listSeparator => ', ';

  @override
  String get newTicket => 'New ticket';

  @override
  String get newTicketSubtitle => 'Record a request you received by phone, chat or in person.';

  @override
  String get subject => 'Subject';

  @override
  String get description => 'Description';

  @override
  String get requesterEmail => 'Customer email';

  @override
  String get requesterHint => 'Start typing to find an existing customer.';

  @override
  String get requesterName => 'Customer name (optional)';

  @override
  String get type => 'Type';

  @override
  String get createTicket => 'Create ticket';

  @override
  String ticketCreated(int number) {
    return 'Ticket #$number created.';
  }

  @override
  String get fieldRequired => 'Fill this in.';

  @override
  String get typeQuestion => 'Question';

  @override
  String get typeIncident => 'Incident';

  @override
  String get typeProblem => 'Problem';

  @override
  String get typeTask => 'Task';

  @override
  String get availability => 'Availability';

  @override
  String get availabilityOnline => 'Online';

  @override
  String get availabilityAway => 'Away';

  @override
  String get availabilityOffline => 'Offline';

  @override
  String get theme => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get appLock => 'Lock with fingerprint or face';

  @override
  String get appLockHint => 'Asks again after 5 minutes away.';

  @override
  String get appLockUnavailable => 'Set up a fingerprint, face or screen lock on this phone to use this.';

  @override
  String get unlock => 'Unlock';

  @override
  String get lockedTitle => 'NexDesk is locked';

  @override
  String get unlockReason => 'Unlock NexDesk';

  @override
  String get about => 'About';

  @override
  String version(String version) {
    return 'Version $version';
  }

  @override
  String get aboutText =>
      'NexDesk is a help desk for support teams: tickets, SLAs and a customer help centre. This app is for agents on the move; settings and reports live on the web.';

  @override
  String get openOnWeb => 'Open NexDesk on the web';

  @override
  String get notificationSettings => 'Notification settings';

  @override
  String get notificationSettingsSubtitle => 'Choose what you want to hear about, and where.';

  @override
  String get channelInApp => 'In the app';

  @override
  String get channelEmail => 'By email';

  @override
  String get channelPush => 'On my phone';

  @override
  String get pushUnavailable => 'Push isn\'t set up in this build, so this phone gets no push notifications.';

  @override
  String get prefTicketAssigned => 'A ticket is assigned to me';

  @override
  String get prefTicketReply => 'Someone replies on a ticket I follow';

  @override
  String get prefTicketNote => 'Someone adds an internal note on a ticket I follow';

  @override
  String get prefSlaWarning => 'A deadline of my ticket is close';

  @override
  String get prefSlaBreach => 'A deadline is missed';

  @override
  String get prefAutomation => 'An automation rule notifies me';

  @override
  String get prefMention => 'A teammate mentions me';

  @override
  String get markAllRead => 'Mark all as read';

  @override
  String get metricFirstResponse => 'first response';

  @override
  String get metricResolution => 'resolution';

  @override
  String get notificationsEmpty => 'You are all caught up.';

  @override
  String get someone => 'Someone';

  @override
  String get open => 'Open';

  @override
  String notificationsUnread(int count) {
    return 'Notifications, $count unread';
  }

  @override
  String notifyTicketAssigned(String actor, int number) {
    return '$actor assigned ticket #$number to you';
  }

  @override
  String notifyTicketReply(String actor, int number) {
    return '$actor replied on ticket #$number';
  }

  @override
  String notifyTicketNote(String actor, int number) {
    return '$actor added a note on ticket #$number';
  }

  @override
  String notifySlaWarning(int number, String metric) {
    return 'Ticket #$number is close to its $metric deadline';
  }

  @override
  String notifySlaBreach(int number, String metric) {
    return 'Ticket #$number missed its $metric deadline';
  }

  @override
  String notifyAutomation(String actor, int number) {
    return '$actor: ticket #$number';
  }

  @override
  String notifyMention(String actor, int number) {
    return '$actor mentioned you on ticket #$number';
  }

  @override
  String uploading(int percent) {
    return 'Uploading, $percent%';
  }
}
