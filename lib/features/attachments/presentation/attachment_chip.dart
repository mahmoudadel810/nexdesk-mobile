import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/api/generated/nex_desk_api.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../attachment_repository.dart';
import '../attachment_rules.dart';
import '../device_files.dart';
import 'attachment_text.dart';

/// A file on a timeline message. Tapping downloads it to the cache (once) and opens it in the phone's viewer.
class AttachmentChip extends ConsumerStatefulWidget {
  const AttachmentChip(this.attachment, {super.key});

  final AttachmentDto attachment;

  @override
  ConsumerState<AttachmentChip> createState() => _AttachmentChipState();
}

class _AttachmentChipState extends ConsumerState<AttachmentChip> {
  bool _opening = false;
  bool _gone = false;

  Future<void> _open() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _opening = true);
    try {
      final file = await ref.read(attachmentRepositoryProvider).download(widget.attachment);
      final opened = await ref.read(deviceFilesProvider).open(file);
      if (!opened) messenger.showSnackBar(SnackBar(content: Text(l10n.cannotOpenFile)));
    } on AppError catch (error) {
      if (error.code == AttachmentCodes.notFound && mounted) setState(() => _gone = true);
      messenger.showSnackBar(SnackBar(content: Text(attachmentErrorText(error, l10n))));
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final file = widget.attachment;
    return ActionChip(
      key: Key('attachment-${file.id}'),
      avatar: _opening
          ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2))
          : Icon(_gone ? Icons.link_off : Icons.attach_file, size: 16),
      label: Text(
        _gone
            ? '${file.fileName} · ${l10n.fileNoLongerAvailable}'
            : '${file.fileName} · ${fileSizeText(file.sizeBytes)}',
        overflow: TextOverflow.ellipsis,
      ),
      onPressed: _opening || _gone ? null : _open,
    );
  }
}
