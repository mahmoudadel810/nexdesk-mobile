import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../core/api/generated/nex_desk_api.dart';
import '../../../core/auth/session.dart';
import '../../../core/auth/session_controller.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../ticket/presentation/ticket_screen.dart';
import '../application/inbox_controller.dart';
import '../data/inbox_query.dart';
import 'ticket_list.dart';

/// The saved view the inbox is showing instead of its tabs, if any.
class SelectedView extends Notifier<SavedViewDto?> {
  @override
  SavedViewDto? build() {
    ref.watch(signedInUserProvider);
    return null;
  }

  // ignore: use_setters_to_change_properties
  void set(SavedViewDto? view) => state = view;
}

final selectedViewProvider = NotifierProvider<SelectedView, SavedViewDto?>(SelectedView.new);

/// On tablets the inbox and the open ticket sit side by side.
class SelectedTicket extends Notifier<String?> {
  @override
  String? build() {
    ref.watch(signedInUserProvider);
    return null;
  }

  // ignore: use_setters_to_change_properties
  void set(String? id) => state = id;
}

final selectedTicketProvider = NotifierProvider<SelectedTicket, String?>(SelectedTicket.new);

class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key});

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  bool _atRisk = false;

  void _open(String id, bool wide) {
    if (wide) {
      ref.read(selectedTicketProvider.notifier).set(id);
    } else {
      context.go('/app/tickets/$id');
    }
  }

  Future<void> _pickView() async {
    final picked = await showModalBottomSheet<SavedViewDto>(
      context: context,
      showDragHandle: true,
      builder: (_) => const _SavedViewsSheet(),
    );
    if (picked != null) ref.read(selectedViewProvider.notifier).set(picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final wide = MediaQuery.sizeOf(context).width >= 840;
    final view = ref.watch(selectedViewProvider);
    final selected = ref.watch(selectedTicketProvider);

    Widget listFor(InboxQuery query, {String? emptyText}) => TicketList(
      key: ValueKey(query.cacheKey),
      query: query,
      selectedId: wide ? selected : null,
      emptyText: emptyText,
      onOpen: (id) => _open(id, wide),
    );

    final Widget lists = view != null
        ? listFor(InboxQuery.fromView(view.filter))
        : TabBarView(
            children: [
              listFor(InboxQuery.mine, emptyText: l10n.emptyMine),
              listFor(InboxQuery.unassigned),
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 0),
                    child: SegmentedButton<bool>(
                      segments: [
                        ButtonSegment(value: false, label: Text(l10n.slaBreached)),
                        ButtonSegment(value: true, label: Text(l10n.slaAtRisk)),
                      ],
                      selected: {_atRisk},
                      onSelectionChanged: (value) => setState(() => _atRisk = value.single),
                    ),
                  ),
                  Expanded(child: listFor(_atRisk ? InboxQuery.atRisk : InboxQuery.breached)),
                ],
              ),
              listFor(InboxQuery.all),
            ],
          );

    final canCreate = switch (ref.watch(sessionProvider)) {
      SignedIn(:final session) => session.can('tickets.create'),
      _ => false,
    };
    final inbox = Scaffold(
      appBar: AppBar(
        title: Text(view?.name ?? l10n.inbox),
        leading: view == null
            ? null
            : IconButton(
                tooltip: l10n.clearView,
                icon: const BackButtonIcon(),
                onPressed: () => ref.read(selectedViewProvider.notifier).set(null),
              ),
        actions: [
          IconButton(
            key: const Key('search'),
            tooltip: l10n.searchTickets,
            icon: const Icon(Icons.search),
            onPressed: () => context.push('/app/tickets/search'),
          ),
          IconButton(
            key: const Key('views'),
            tooltip: l10n.savedViews,
            icon: const Icon(Icons.bookmarks_outlined),
            onPressed: _pickView,
          ),
        ],
        bottom: view != null
            ? null
            : TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: [
                  Tab(text: l10n.tabMine),
                  Tab(text: l10n.tabUnassigned),
                  Tab(text: l10n.tabSla),
                  Tab(text: l10n.tabAll),
                ],
              ),
      ),
      body: lists,
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              key: const Key('new-ticket'),
              icon: const Icon(Icons.add),
              label: Text(l10n.newTicket),
              onPressed: () => context.push(Routes.newTicket),
            )
          : null,
    );

    final body = DefaultTabController(length: 4, child: inbox);
    if (!wide) return body;

    return Row(
      children: [
        SizedBox(width: 420, child: body),
        const VerticalDivider(width: 1),
        Expanded(
          child: selected == null
              ? Center(child: Text(l10n.selectTicket))
              : TicketScreen(key: ValueKey(selected), ticketId: selected),
        ),
      ],
    );
  }
}

class _SavedViewsSheet extends ConsumerWidget {
  const _SavedViewsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final views = ref.watch(savedViewsProvider);
    return SafeArea(
      child: views.when(
        loading: () => const Padding(
          padding: EdgeInsetsDirectional.all(32),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (_, _) => Padding(
          padding: const EdgeInsetsDirectional.all(24),
          child: Text(l10n.errorNetwork, textAlign: TextAlign.center),
        ),
        data: (list) => list.isEmpty
            ? Padding(
                padding: const EdgeInsetsDirectional.all(24),
                child: Text(l10n.noSavedViews, textAlign: TextAlign.center),
              )
            : ListView(
                shrinkWrap: true,
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 8),
                    child: Text(l10n.savedViews, style: Theme.of(context).textTheme.titleMedium),
                  ),
                  for (final view in list)
                    ListTile(
                      leading: Icon(view.isShared ? Icons.group_outlined : Icons.bookmark_outline),
                      title: Text(view.name),
                      subtitle: view.isShared ? Text(l10n.sharedView) : null,
                      onTap: () => Navigator.pop(context, view),
                    ),
                ],
              ),
      ),
    );
  }
}
