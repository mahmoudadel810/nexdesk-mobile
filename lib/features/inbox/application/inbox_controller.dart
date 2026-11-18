import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/generated/nex_desk_api.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/realtime/live_hub.dart';
import '../../../core/realtime/realtime_controller.dart';
import '../data/inbox_query.dart';
import '../data/tickets_repository.dart';

class InboxState {
  const InboxState({
    this.items = const [],
    this.page = 0,
    this.totalCount = 0,
    this.loading = true,
    this.loadingMore = false,
    this.error,
    this.cachedAt,
  });

  final List<TicketListItem> items;

  /// The last page loaded.
  final int page;
  final int totalCount;

  /// Nothing to show yet.
  final bool loading;
  final bool loadingMore;

  /// The last refresh failed. With [items] still shown, a network error means "offline".
  final AppError? error;

  /// Set while the list on screen is the cached copy from that time.
  final DateTime? cachedAt;

  bool get hasMore => items.length < totalCount;

  bool get offline => (error?.isNetwork ?? false) && items.isNotEmpty;

  InboxState copyWith({
    List<TicketListItem>? items,
    int? page,
    int? totalCount,
    bool? loading,
    bool? loadingMore,
    AppError? error,
    bool clearError = false,
    DateTime? cachedAt,
    bool clearCachedAt = false,
  }) => InboxState(
    items: items ?? this.items,
    page: page ?? this.page,
    totalCount: totalCount ?? this.totalCount,
    loading: loading ?? this.loading,
    loadingMore: loadingMore ?? this.loadingMore,
    error: clearError ? null : error ?? this.error,
    cachedAt: clearCachedAt ? null : cachedAt ?? this.cachedAt,
  );
}

/// One ticket list: shows the cached copy straight away, then the network answer; loads further pages as the
/// person scrolls, dropping tickets that moved between pages in the meantime.
class InboxController extends Notifier<InboxState> {
  InboxController(this.query);

  final InboxQuery query;

  TicketsRepository get _tickets => ref.read(ticketsRepositoryProvider);

  Timer? _reload;

  @override
  InboxState build() {
    final events = ref.watch(liveEventsProvider).listen(_onEvent);
    ref.onDispose(() {
      unawaited(events.cancel());
      _reload?.cancel();
    });
    Future.microtask(_start);
    return const InboxState();
  }

  /// Ticket changes come in bursts (a bulk update, an automation run), so they reload page 1 once, a second
  /// after the last one. A reconnect reloads straight away to catch up on what was missed.
  void _onEvent(LiveEvent event) {
    switch (event) {
      case TicketChanged():
        _reload?.cancel();
        _reload = Timer(const Duration(seconds: 1), () => unawaited(refresh()));
      case LiveConnected() when !state.loading:
        unawaited(refresh());
      case _:
        break;
    }
  }

  Future<void> _start() async {
    final cached = await _tickets.cached(query, 1);
    if (cached != null && state.loading) {
      state = InboxState(
        items: cached.result.items,
        page: 1,
        totalCount: cached.result.totalCount,
        loading: false,
        cachedAt: cached.cachedAt,
      );
    }
    await refresh();
  }

  Future<void> refresh() async {
    try {
      final fresh = await _tickets.fetch(query, 1);
      if (!ref.mounted) return;
      state = InboxState(
        items: fresh.result.items,
        page: 1,
        totalCount: fresh.result.totalCount,
        loading: false,
      );
    } on AppError catch (error) {
      if (ref.mounted) state = state.copyWith(loading: false, error: error);
    }
  }

  Future<void> loadMore() async {
    if (state.loadingMore || state.loading || !state.hasMore || state.error != null) return;
    state = state.copyWith(loadingMore: true);
    try {
      final next = await _tickets.fetch(query, state.page + 1);
      final seen = {for (final item in state.items) item.id};
      state = state.copyWith(
        items: [...state.items, ...next.result.items.where((item) => seen.add(item.id))],
        page: state.page + 1,
        totalCount: next.result.totalCount,
        loadingMore: false,
      );
    } on AppError catch (error) {
      state = state.copyWith(loadingMore: false, error: error);
    }
  }
}

final inboxProvider = NotifierProvider.family<InboxController, InboxState, InboxQuery>(InboxController.new);

final savedViewsProvider = FutureProvider<List<SavedViewDto>>(
  (ref) => ref.watch(ticketsRepositoryProvider).savedViews(),
);
