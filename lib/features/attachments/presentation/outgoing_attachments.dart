import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/api/generated/nex_desk_api.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../attachment_repository.dart';
import '../attachment_rules.dart';
import '../device_files.dart';
import 'attachment_text.dart';

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

/// The files being added to a reply or a new ticket: picks one, checks it against the API's limits, uploads it
/// with progress, and keeps the reason when it is refused. Listen to it to rebuild.
class OutgoingFiles extends ChangeNotifier {
  OutgoingFiles(this._ref);

  final WidgetRef _ref;
  final items = <Outgoing>[];
  bool _disposed = false;

  bool get uploading => items.any((o) => o.uploading);

  List<String> get uploadedIds => [for (final o in items) ?o.uploaded?.id];

  Future<void> pick(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final source = await chooseAttachSource(context);
    if (source == null || _disposed) return;
    final files = _ref.read(deviceFilesProvider);
    final picked = await switch (source) {
      AttachSource.camera => files.takePhoto(),
      AttachSource.gallery => files.choosePhoto(),
      AttachSource.files => files.chooseFile(),
    };
    if (picked == null || _disposed) return;
    final item = Outgoing(picked);
    final problem = checkAttachment(picked.name, picked.sizeBytes);
    if (problem != null) item.problem = attachmentProblemText(problem, l10n);
    items.add(item);
    notifyListeners();
    if (problem != null) return;
    try {
      item.uploaded = await _ref
          .read(attachmentRepositoryProvider)
          .upload(
            picked,
            cancel: item.cancel,
            onProgress: (progress) {
              item.progress = progress;
              if (!_disposed) notifyListeners();
            },
          );
    } on AppError catch (error) {
      if (error.code == AttachmentCodes.cancelled) return;
      item.problem = attachmentErrorText(error, l10n);
    }
    if (!_disposed) notifyListeners();
  }

  void remove(Outgoing item) {
    item.cancel.cancel();
    items.remove(item);
    notifyListeners();
  }

  void clear() {
    items.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    for (final item in items) {
      item.cancel.cancel();
    }
    super.dispose();
  }
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
