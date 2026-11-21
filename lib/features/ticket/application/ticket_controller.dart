import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/generated/nex_desk_api.dart';
import '../../../core/auth/session_controller.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/realtime/live_hub.dart';
import '../../../core/realtime/realtime_controller.dart';
import '../data/ticket_repository.dart';

/// A change to the ticket's fields, built against whatever version is current when it is applied.
typedef TicketChange = Future<TicketView> Function(TicketRepository tickets, TicketDetailDto current);

class TicketState {
  const TicketState({this.view, this.loading = true, this.busy = false, this.error, this.stale = false});

  final TicketView? view;
  final bool loading;

  /// A send or change is on its way.
  final bool busy;
  final AppError? error;

  /// Someone else changed the ticket first: it was reloaded, and the person's change can be applied again.
  final bool stale;

  TicketDetailDto? get ticket => view?.ticket;

  TicketState copyWith({
    TicketView? view,
    bool? loading,
    bool? busy,
    AppError? error,
    bool clearError = false,
    bool? stale,
  }) => TicketState(
    view: view ?? this.view,
    loading: loading ?? this.loading,
    busy: busy ?? this.busy,
    error: clearError ? null : error ?? this.error,
    stale: stale ?? this.stale,
  );
}

class TicketController extends Notifier<TicketState> {
  TicketController(this.id);

  final String id;
  TicketChange? _pending;

  TicketRepository get _tickets => ref.read(ticketRepositoryProvider);

  /// Counts rebuilds. Riverpod keeps this object when someone else signs in, so an answer requested before
  /// that is recognised by the count it started with and dropped.
  int _builds = 0;

  bool _outdated(int build) => !ref.mounted || build != _builds;

  @override
  TicketState build() {
    _builds++;
    _pending = null;
    if (ref.watch(signedInUserProvider) == null) return const TicketState();
    final events = ref.watch(liveEventsProvider).listen(_onEvent);
    ref.onDispose(() => unawaited(events.cancel()));
    Future.microtask(_start);
    return const TicketState();
  }

  /// Someone else changed this ticket, or the live connection is back after a gap: reload it, which also
  /// updates the copy kept on the phone. A send or change in flight reloads on its own.
  void _onEvent(LiveEvent event) {
    final relevant = switch (event) {
      TicketChanged(:final ticketId) => ticketId == id,
      LiveConnected() => state.view != null,
      _ => false,
    };
    if (relevant && !state.busy && ref.mounted) unawaited(refresh());
  }

  Future<void> _start() async {
    final build = _builds;
    final cached = await _tickets.cached(id);
    if (_outdated(build)) return;
    if (cached != null && state.view == null) state = TicketState(view: cached, loading: false);
    await refresh();
  }

  Future<void> refresh() async {
    final build = _builds;
    try {
      final view = await _tickets.fetch(id);
      if (!_outdated(build)) state = state.copyWith(view: view, loading: false, clearError: true);
    } on AppError catch (error) {
      if (!_outdated(build)) state = state.copyWith(loading: false, error: error);
    }
  }

  /// Sends a reply or note. Returns whether it went, so the composer knows to clear itself.
  Future<bool> send(
    String body, {
    required bool internal,
    TicketStatus? setStatus,
    List<String> attachmentIds = const [],
  }) => _run(
    (tickets) => tickets.send(
      id,
      body: body.trim(),
      internal: internal,
      setStatus: setStatus,
      attachmentIds: attachmentIds,
    ),
  );

  Future<bool> setStatus(TicketStatus status) => _change(
    (tickets, current) => tickets.update(
      id,
      UpdateTicketRequest(
        subject: null,
        status: status,
        priority: null,
        type: null,
        tags: null,
        customFields: null,
        version: current.version,
      ),
    ),
  );

  Future<bool> setPriority(TicketPriority priority) => _change(
    (tickets, current) => tickets.update(
      id,
      UpdateTicketRequest(
        subject: null,
        status: null,
        priority: priority,
        type: null,
        tags: null,
        customFields: null,
        version: current.version,
      ),
    ),
  );

  Future<bool> setTags(List<String> tags) => _change(
    (tickets, current) => tickets.update(
      id,
      UpdateTicketRequest(
        subject: null,
        status: null,
        priority: null,
        type: null,
        tags: tags,
        customFields: null,
        version: current.version,
      ),
    ),
  );

  Future<bool> assign(String? assigneeId) => _change(
    (tickets, current) =>
        tickets.assign(id, version: current.version, assigneeId: assigneeId, teamId: current.team?.id),
  );

  Future<bool> toggleWatching() {
    final watching = state.ticket?.isWatching ?? false;
    return _run((tickets) => tickets.watch(id, watching: !watching));
  }

  /// After a stale-ticket refusal: applies the same change to the reloaded ticket.
  Future<bool> applyAgain() async {
    final change = _pending;
    if (change == null) return false;
    return _change(change);
  }

  void dismissStale() {
    _pending = null;
    state = state.copyWith(stale: false);
  }

  Future<bool> _change(TicketChange change) async {
    final current = state.ticket;
    if (current == null) return false;
    _pending = change;
    final done = await _run((tickets) => change(tickets, current));
    if (done) _pending = null;
    return done;
  }

  Future<bool> _run(Future<TicketView> Function(TicketRepository tickets) action) async {
    if (state.busy) return false;
    final build = _builds;
    state = state.copyWith(busy: true, clearError: true, stale: false);
    try {
      final view = await action(_tickets);
      if (!_outdated(build)) state = state.copyWith(view: view, busy: false);
      return true;
    } on AppError catch (error) {
      if (_outdated(build)) return false;
      if (error.code == 'stale-ticket') {
        await refresh();
        if (!_outdated(build)) state = state.copyWith(busy: false, stale: true);
      } else {
        state = state.copyWith(busy: false, error: error);
      }
      return false;
    }
  }
}

final ticketProvider = NotifierProvider.family<TicketController, TicketState, String>(TicketController.new);

/// The workspace's active team, for @mentions and assigning.
final peopleProvider = FutureProvider<List<UserDto>>(
  (ref) async =>
      ref.watch(signedInUserProvider) == null ? const [] : ref.watch(ticketRepositoryProvider).people(),
);

final fieldLabelsProvider = FutureProvider<Map<String, String>>(
  (ref) async =>
      ref.watch(signedInUserProvider) == null ? const {} : ref.watch(ticketRepositoryProvider).fieldLabels(),
);
