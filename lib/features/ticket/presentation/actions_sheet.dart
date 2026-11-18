import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/api/generated/nex_desk_api.dart';
import '../../../core/auth/session_controller.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../shared/ticket_badges.dart';
import '../application/ticket_controller.dart';

const _statuses = [
  TicketStatus.new2,
  TicketStatus.open,
  TicketStatus.pending,
  TicketStatus.onHold,
  TicketStatus.solved,
  TicketStatus.closed,
];
const _priorities = [TicketPriority.low, TicketPriority.normal, TicketPriority.high, TicketPriority.urgent];

/// Status, priority, assignment and tags in one sheet. Each change closes the sheet so the result is visible.
class ActionsSheet extends ConsumerStatefulWidget {
  const ActionsSheet({required this.ticketId, super.key});

  final String ticketId;

  @override
  ConsumerState<ActionsSheet> createState() => _ActionsSheetState();
}

class _ActionsSheetState extends ConsumerState<ActionsSheet> {
  final _tag = TextEditingController();

  @override
  void dispose() {
    _tag.dispose();
    super.dispose();
  }

  TicketController get _controller => ref.read(ticketProvider(widget.ticketId).notifier);

  Future<void> _do(Future<bool> Function() action) async {
    final navigator = Navigator.of(context);
    await action();
    if (mounted) navigator.pop();
  }

  Future<void> _pickAssignee() async {
    final l10n = AppLocalizations.of(context);
    final people = await ref.read(peopleProvider.future);
    if (!mounted) return;
    final agents = people.where((p) => p.role != Role.viewer).toList();
    final picked = await showModalBottomSheet<UserDto>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 8),
              child: Text(l10n.assignTo, style: Theme.of(context).textTheme.titleMedium),
            ),
            for (final person in agents)
              ListTile(
                leading: CircleAvatar(child: Text(person.fullName.characters.first)),
                title: Text(person.fullName),
                onTap: () => Navigator.pop(context, person),
              ),
          ],
        ),
      ),
    );
    if (picked != null) await _do(() => _controller.assign(picked.id));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ticket = ref.watch(ticketProvider(widget.ticketId)).ticket;
    final me = ref.watch(sessionProvider.notifier).current?.user;
    if (ticket == null) return const SizedBox.shrink();
    final theme = Theme.of(context);

    Widget section(String title, Widget child) => Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            section(
              l10n.status,
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final status in _statuses)
                    ChoiceChip(
                      key: Key('status-${status.toJson()}'),
                      label: Text(statusLabel(status, l10n)),
                      selected: ticket.status == status,
                      onSelected: ticket.status == status
                          ? null
                          : (_) => _do(() => _controller.setStatus(status)),
                    ),
                ],
              ),
            ),
            section(
              l10n.priority,
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final priority in _priorities)
                    ChoiceChip(
                      key: Key('priority-${priority.toJson()}'),
                      label: Text(priorityLabel(priority, l10n)),
                      selected: ticket.priority == priority,
                      onSelected: ticket.priority == priority
                          ? null
                          : (_) => _do(() => _controller.setPriority(priority)),
                    ),
                ],
              ),
            ),
            section(
              l10n.assignee,
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (me != null && ticket.assignee?.id != me.id)
                    ActionChip(
                      key: const Key('assign-me'),
                      avatar: const Icon(Icons.person_add_alt, size: 18),
                      label: Text(l10n.assignToMe),
                      onPressed: () => _do(() => _controller.assign(me.id)),
                    ),
                  ActionChip(
                    avatar: const Icon(Icons.group_outlined, size: 18),
                    label: Text(l10n.assignTo),
                    onPressed: _pickAssignee,
                  ),
                  if (ticket.assignee != null)
                    ActionChip(
                      avatar: const Icon(Icons.person_remove_outlined, size: 18),
                      label: Text(l10n.unassign),
                      onPressed: () => _do(() => _controller.assign(null)),
                    ),
                ],
              ),
            ),
            section(
              l10n.tags,
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  for (final tag in ticket.tags)
                    InputChip(
                      label: Text(tag),
                      onDeleted: () => _do(() => _controller.setTags([...ticket.tags]..remove(tag))),
                    ),
                  SizedBox(
                    width: 160,
                    child: TextField(
                      controller: _tag,
                      decoration: InputDecoration(hintText: l10n.addTag, isDense: true),
                      textInputAction: TextInputAction.done,
                      onSubmitted: (value) {
                        final tag = value.trim().toLowerCase();
                        if (tag.isNotEmpty && !ticket.tags.contains(tag)) {
                          _do(() => _controller.setTags([...ticket.tags, tag]));
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
