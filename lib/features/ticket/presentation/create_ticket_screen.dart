import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../core/api/api.dart';
import '../../../core/api/generated/nex_desk_api.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../shared/ticket_badges.dart';

String typeLabel(TicketType type, AppLocalizations l10n) => switch (type) {
  TicketTypeKnown(value: TicketTypeValue.incident) => l10n.typeIncident,
  TicketTypeKnown(value: TicketTypeValue.problem) => l10n.typeProblem,
  TicketTypeKnown(value: TicketTypeValue.task) => l10n.typeTask,
  _ => l10n.typeQuestion,
};

/// A ticket for a request that came by phone, chat or in person, as on the web: the customer is found by email
/// or created from it.
class CreateTicketScreen extends ConsumerStatefulWidget {
  const CreateTicketScreen({super.key});

  @override
  ConsumerState<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends ConsumerState<CreateTicketScreen> {
  final _form = GlobalKey<FormState>();
  final _subject = TextEditingController();
  final _description = TextEditingController();
  final _name = TextEditingController();
  TextEditingController? _email;
  CustomerDto? _customer;
  TicketPriority _priority = TicketPriority.normal;
  TicketType _type = TicketType.question;
  bool _saving = false;
  AppError? _error;

  @override
  void dispose() {
    _subject.dispose();
    _description.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<Iterable<CustomerDto>> _search(String text) async {
    final query = text.trim();
    if (query.length < 2) return const [];
    try {
      final page = await ref.read(apiProvider).customers.listCustomers(search: query, page: 1, pageSize: 8);
      return page.items;
    } on Object {
      return const [];
    }
  }

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    final l10n = AppLocalizations.of(context);
    final email = _email!.text.trim();
    final customer = _customer?.email.toLowerCase() == email.toLowerCase() ? _customer : null;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final ticket = await ref
          .read(apiProvider)
          .tickets
          .createTicket(
            body: CreateTicketRequest(
              subject: _subject.text.trim(),
              description: _description.text.trim(),
              requesterId: customer?.id,
              requesterEmail: customer == null ? email : null,
              requesterName: customer == null && _name.text.trim().isNotEmpty ? _name.text.trim() : null,
              priority: _priority,
              type: _type,
            ),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.ticketCreated(ticket.number))));
      context.go('${Routes.inbox}/${ticket.id}');
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = AppError.from(error);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    String? required(String? value) => (value ?? '').trim().isEmpty ? l10n.fieldRequired : null;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.newTicket)),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsetsDirectional.all(16),
          children: [
            Text(l10n.newTicketSubtitle, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            if (_error case final error?)
              Padding(
                padding: const EdgeInsetsDirectional.only(bottom: 12),
                child: Text(
                  messageFor(error, l10n),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            Autocomplete<CustomerDto>(
              displayStringForOption: (c) => c.email,
              optionsBuilder: (value) => _search(value.text),
              onSelected: (c) => setState(() {
                _customer = c;
                _name.text = c.fullName;
              }),
              fieldViewBuilder: (context, controller, focus, onSubmitted) {
                _email = controller;
                return TextFormField(
                  key: const Key('requester-email'),
                  controller: controller,
                  focusNode: focus,
                  keyboardType: TextInputType.emailAddress,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(labelText: l10n.requesterEmail, helperText: l10n.requesterHint),
                  validator: (value) {
                    final text = (value ?? '').trim();
                    if (text.isEmpty) return l10n.fieldRequired;
                    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text) ? null : l10n.emailInvalid;
                  },
                );
              },
              optionsViewBuilder: (context, onSelected, options) => Align(
                alignment: AlignmentDirectional.topStart,
                child: Material(
                  elevation: 4,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 240, maxWidth: 360),
                    child: ListView(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      children: [
                        for (final c in options)
                          ListTile(
                            key: Key('customer-${c.id}'),
                            title: Text(c.fullName),
                            subtitle: Text(c.email, textDirection: TextDirection.ltr),
                            onTap: () => onSelected(c),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('requester-name'),
              controller: _name,
              decoration: InputDecoration(labelText: l10n.requesterName),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('subject'),
              controller: _subject,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: l10n.subject),
              validator: required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('description'),
              controller: _description,
              minLines: 4,
              maxLines: 10,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: l10n.description, alignLabelWithHint: true),
              validator: required,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<TicketPriority>(
              key: const Key('priority'),
              initialValue: _priority,
              decoration: InputDecoration(labelText: l10n.priority),
              items: [
                for (final p in [
                  TicketPriority.low,
                  TicketPriority.normal,
                  TicketPriority.high,
                  TicketPriority.urgent,
                ])
                  DropdownMenuItem(value: p, child: Text(priorityLabel(p, l10n))),
              ],
              onChanged: (p) => setState(() => _priority = p ?? _priority),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<TicketType>(
              key: const Key('type'),
              initialValue: _type,
              decoration: InputDecoration(labelText: l10n.type),
              items: [
                for (final t in [
                  TicketType.question,
                  TicketType.incident,
                  TicketType.problem,
                  TicketType.task,
                ])
                  DropdownMenuItem(value: t, child: Text(typeLabel(t, l10n))),
              ],
              onChanged: (t) => setState(() => _type = t ?? _type),
            ),
            const SizedBox(height: 24),
            FilledButton(
              key: const Key('create-ticket'),
              onPressed: _saving ? null : () => unawaited(_submit()),
              child: _saving
                  ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(l10n.createTicket),
            ),
          ],
        ),
      ),
    );
  }
}
