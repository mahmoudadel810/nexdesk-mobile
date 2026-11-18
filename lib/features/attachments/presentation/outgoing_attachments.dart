import 'package:dio/dio.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/api/generated/nex_desk_api.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../attachment_rules.dart';
import '../device_files.dart';

/// A file being added to a reply: uploading, uploaded, or refused with the reason.
class Outgoing {
  Outgoing(this.file);

  final PickedFile file;
  final cancel = CancelToken();
  double progress = 0;
  AttachmentDto? uploaded;
  String? problem;

  bool get uploading => uploaded == null && problem == null;
}

/// Where a new attachment comes from.
enum AttachSource { camera, gallery, files }

Future<AttachSource?> chooseAttachSource(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  return showModalBottomSheet<AttachSource>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            key: const Key('attach-camera'),
            leading: const Icon(Icons.photo_camera_outlined),
            title: Text(l10n.takePhoto),
            onTap: () => Navigator.pop(context, AttachSource.camera),
          ),
          ListTile(
            key: const Key('attach-gallery'),
            leading: const Icon(Icons.photo_library_outlined),
            title: Text(l10n.choosePhoto),
            onTap: () => Navigator.pop(context, AttachSource.gallery),
          ),
          ListTile(
            key: const Key('attach-file'),
            leading: const Icon(Icons.insert_drive_file_outlined),
            title: Text(l10n.chooseFile),
            onTap: () => Navigator.pop(context, AttachSource.files),
          ),
        ],
      ),
    ),
  );
}

/// The files added to a reply, each with its progress or problem and a button to remove it.
class OutgoingAttachments extends StatelessWidget {
  const OutgoingAttachments({required this.items, required this.onRemove, super.key});

  final List<Outgoing> items;
  final void Function(Outgoing) onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        for (final item in items)
          InputChip(
            key: Key('outgoing-${item.file.name}'),
            avatar: item.uploading
                ? Semantics(
                    label: l10n.uploading((item.progress * 100).round()),
                    child: SizedBox.square(
                      key: const Key('upload-progress'),
                      dimension: 16,
                      child: CircularProgressIndicator(
                        value: item.progress > 0 ? item.progress : null,
                        strokeWidth: 2,
                      ),
                    ),
                  )
                : Icon(
                    item.problem == null ? Icons.attach_file : Icons.error_outline,
                    size: 16,
                    color: item.problem == null ? null : scheme.error,
                  ),
            label: Text(
              item.problem == null
                  ? '${item.file.name} · ${fileSizeText(item.file.sizeBytes)}'
                  : '${item.file.name} · ${item.problem}',
              overflow: TextOverflow.ellipsis,
              style: item.problem == null ? null : TextStyle(color: scheme.error),
            ),
            deleteButtonTooltipMessage: l10n.removeAttachment(item.file.name),
            onDeleted: () => onRemove(item),
          ),
      ],
    );
  }
}
