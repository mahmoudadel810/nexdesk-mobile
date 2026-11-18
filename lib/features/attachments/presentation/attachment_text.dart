import '../../../core/errors/app_error.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../attachment_repository.dart';
import '../attachment_rules.dart';

String attachmentProblemText(AttachmentProblem problem, AppLocalizations l10n) => switch (problem) {
  AttachmentProblem.tooLarge => l10n.fileTooLarge(fileSizeText(maxAttachmentBytes)),
  AttachmentProblem.blockedType => l10n.fileTypeBlocked,
};

String attachmentErrorText(AppError error, AppLocalizations l10n) => switch (error.code) {
  AttachmentCodes.tooLarge => attachmentProblemText(AttachmentProblem.tooLarge, l10n),
  AttachmentCodes.blocked => attachmentProblemText(AttachmentProblem.blockedType, l10n),
  AttachmentCodes.invalid => l10n.invalidAttachment,
  AttachmentCodes.notFound => l10n.fileNoLongerAvailable,
  _ => messageFor(error, l10n),
};
