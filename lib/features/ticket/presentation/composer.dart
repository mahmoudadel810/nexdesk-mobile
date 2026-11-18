import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/api/generated/nex_desk_api.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../shared/mentions.dart';
import '../../../shared/ticket_badges.dart';
import '../../attachments/attachment_repository.dart';
import '../../attachments/attachment_rules.dart';
import '../../attachments/device_files.dart';
import '../../attachments/presentation/attachment_text.dart';
import '../../attachments/presentation/outgoing_attachments.dart';
import '../application/ticket_controller.dart';
import '../data/ticket_repository.dart';

/// Writing a public reply or an internal note. Typing "@" suggests teammates; what is written is kept on the
/// phone as a draft until it is sent, so it survives the app being closed.
class Composer extends ConsumerStatefulWidget {
  const Composer({required this.ticket, super.key});

  final TicketDetailDto ticket;

  @override
  ConsumerState<Composer> createState() => _ComposerState();
}

class _ComposerState extends ConsumerState<Composer> {
  final _text = TextEditingController();
  final _focus = FocusNode();
  bool _internal = false;
  Timer? _saveDraft;
  List<UserDto> _suggestions = const [];
  final _outgoing = <Outgoing>[];

  String get _ticketId => widget.ticket.id;

  @override
  void initState() {
    super.initState();
    _text.addListener(_changed);
    unawaited(_restoreDraft());
  }

  Future<void> _restoreDraft() async {
    final draft = await ref.read(ticketRepositoryProvider).draft(_ticketId);
    if (draft == null || !mounted || _text.text.isNotEmpty) return;
    setState(() => _internal = draft.internal);
    _text.text = draft.body;
  }

  @override
  void dispose() {
    _saveDraft?.cancel();
    for (final item in _outgoing) {
      item.cancel.cancel();
    }
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _changed() {
    _saveDraft?.cancel();
    _saveDraft = Timer(const Duration(milliseconds: 400), _storeDraft);

    final query = mentionQuery(_text.text, _text.selection.baseOffset);
    final people = ref.read(peopleProvider).value ?? const [];
    final next = query == null
        ? const <UserDto>[]
        : mentionCandidates(people, (u) => u.fullName, query.query, limit: 5);
    if (next.length != _suggestions.length || !next.every(_suggestions.contains)) {
      setState(() => _suggestions = next);
    }
  }

  void _storeDraft() => unawaited(
    ref.read(ticketRepositoryProvider).saveDraft(_ticketId, (body: _text.text, internal: _internal)),
  );

  void _mention(UserDto person) {
    final caret = _text.selection.baseOffset;
    final query = mentionQuery(_text.text, caret);
    if (query == null) return;
    final result = insertMention(_text.text, query, caret, person.fullName);
    _text.value = TextEditingValue(
      text: result.text,
      selection: TextSelection.collapsed(offset: result.caret),
    );
    _focus.requestFocus();
  }

  bool get _uploading => _outgoing.any((o) => o.uploading);

  Future<void> _attach() async {
    final source = await chooseAttachSource(context);
    if (source == null || !mounted) return;
    final files = ref.read(deviceFilesProvider);
    final picked = await switch (source) {
      AttachSource.camera => files.takePhoto(),
      AttachSource.gallery => files.choosePhoto(),
      AttachSource.files => files.chooseFile(),
    };
    if (picked == null || !mounted) return;
    final l10n = AppLocalizations.of(context);
    final item = Outgoing(picked);
    final problem = checkAttachment(picked.name, picked.sizeBytes);
    setState(() {
      if (problem != null) item.problem = attachmentProblemText(problem, l10n);
      _outgoing.add(item);
    });
    if (problem != null) return;
    try {
      final uploaded = await ref
          .read(attachmentRepositoryProvider)
          .upload(
            picked,
            cancel: item.cancel,
            onProgress: (progress) {
              if (mounted) setState(() => item.progress = progress);
            },
          );
      if (mounted) setState(() => item.uploaded = uploaded);
    } on AppError catch (error) {
      if (!mounted || error.code == AttachmentCodes.cancelled) return;
      setState(() => item.problem = attachmentErrorText(error, l10n));
    }
  }

  void _remove(Outgoing item) {
    item.cancel.cancel();
    setState(() => _outgoing.remove(item));
  }

  Future<void> _send([TicketStatus? setStatus]) async {
    final body = _text.text.trim();
    if (body.isEmpty || _uploading) return;
    _saveDraft?.cancel();
    final sent = await ref
        .read(ticketProvider(_ticketId).notifier)
        .send(
          body,
          internal: _internal,
          setStatus: setStatus,
          attachmentIds: [for (final o in _outgoing) ?o.uploaded?.id],
        );
    if (sent && mounted) {
      _text.clear();
      setState(() {
        _suggestions = const [];
        _outgoing.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final busy = ref.watch(ticketProvider(_ticketId).select((s) => s.busy));
    ref.watch(peopleProvider);

    return Material(
      color: _internal ? scheme.tertiaryContainer : scheme.surfaceContainer,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 12, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_suggestions.isNotEmpty)
                Semantics(
                  label: l10n.mentionSuggestions,
                  container: true,
                  child: SizedBox(
                    height: 48,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        for (final person in _suggestions)
                          Padding(
                            padding: const EdgeInsetsDirectional.only(end: 8),
                            child: ActionChip(
                              key: Key('mention-${person.id}'),
                              avatar: const Icon(Icons.alternate_email, size: 16),
                              label: Text(person.fullName),
                              onPressed: () => _mention(person),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment(value: false, icon: const Icon(Icons.reply), label: Text(l10n.reply)),
                  ButtonSegment(value: true, icon: const Icon(Icons.lock_outline), label: Text(l10n.note)),
                ],
                selected: {_internal},
                onSelectionChanged: (value) {
                  setState(() => _internal = value.single);
                  _storeDraft();
                },
              ),
              if (_outgoing.isNotEmpty) ...[
                const SizedBox(height: 8),
                OutgoingAttachments(items: _outgoing, onRemove: _remove),
              ],
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    key: const Key('attach'),
                    tooltip: l10n.attach,
                    icon: const Icon(Icons.attach_file),
                    onPressed: busy ? null : _attach,
                  ),
                  Expanded(
                    child: TextField(
                      key: const Key('composer'),
                      controller: _text,
                      focusNode: _focus,
                      minLines: 1,
                      maxLines: 6,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: _internal ? l10n.noteHint : l10n.replyHint(widget.ticket.requester.name),
                        filled: true,
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (busy)
                    const Padding(
                      padding: EdgeInsetsDirectional.all(12),
                      child: SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  else ...[
                    IconButton.filled(
                      key: const Key('send'),
                      tooltip: _internal ? l10n.addNote : l10n.send,
                      icon: Icon(_internal ? Icons.note_add_outlined : Icons.send),
                      onPressed: _uploading ? null : _send,
                    ),
                    PopupMenuButton<TicketStatus>(
                      key: const Key('send-and-set'),
                      enabled: !_uploading,
                      tooltip: l10n.sendAndSet('…'),
                      onSelected: _send,
                      itemBuilder: (_) => [
                        for (final status in [TicketStatus.pending, TicketStatus.onHold, TicketStatus.solved])
                          PopupMenuItem(
                            value: status,
                            child: Text(l10n.sendAndSet(statusLabel(status, l10n))),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
