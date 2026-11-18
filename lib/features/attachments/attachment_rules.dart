/// The API's attachment limits (`Attachment.MaxSizeBytes` and `BlockedExtensions` in the backend), checked on
/// the phone so a file that would be refused is never uploaded.
const maxAttachmentBytes = 10 * 1024 * 1024;

const _blockedExtensions = {
  '.exe', '.dll', '.bat', '.cmd', '.com', '.msi', '.scr', '.ps1', '.vbs', '.jar', '.sh', '.app', //
};

const _photoExtensions = {'.jpg', '.jpeg', '.png', '.heic', '.heif', '.webp'};

const _contentTypes = {
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.png': 'image/png',
  '.gif': 'image/gif',
  '.webp': 'image/webp',
  '.heic': 'image/heic',
  '.pdf': 'application/pdf',
  '.txt': 'text/plain',
  '.csv': 'text/csv',
  '.doc': 'application/msword',
  '.docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  '.xls': 'application/vnd.ms-excel',
  '.xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  '.zip': 'application/zip',
};

enum AttachmentProblem { tooLarge, blockedType }

/// The extension with its dot, lower case, as .NET's `Path.GetExtension` sees it: "" when there is none.
String extensionOf(String fileName) {
  final dot = fileName.lastIndexOf('.');
  return dot < 0 || dot == fileName.length - 1 ? '' : fileName.substring(dot).toLowerCase();
}

/// Why the API would refuse this file, or null when it can be uploaded. An empty file counts as too large, as
/// it does on the API.
AttachmentProblem? checkAttachment(String fileName, int sizeBytes) {
  if (_blockedExtensions.contains(extensionOf(fileName))) return AttachmentProblem.blockedType;
  if (sizeBytes <= 0 || sizeBytes > maxAttachmentBytes) return AttachmentProblem.tooLarge;
  return null;
}

bool isPhoto(String fileName) => _photoExtensions.contains(extensionOf(fileName));

String contentTypeOf(String fileName) => _contentTypes[extensionOf(fileName)] ?? 'application/octet-stream';

/// "850 KB", "2.4 MB".
String fileSizeText(int bytes) {
  if (bytes < 1024 * 1024) return '${(bytes / 1024).ceil()} KB';
  final megabytes = bytes / (1024 * 1024);
  return '${megabytes.toStringAsFixed(megabytes < 10 ? 1 : 0)} MB';
}
