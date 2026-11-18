import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/generated/nex_desk_api.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/realtime/live_hub.dart';
import '../../../core/realtime/realtime_controller.dart';
import '../data/notifications_repository.dart';

class NotificationsState {
  const NotificationsState({
    this.items = const [],
    this.page = 0,
    this.totalCount = 0,
    this.unread = 0,
    this.loading = true,
    this.loadingMore = false,
    this.error,
  });

  final List<NotificationDto> items;
  final int page;
  final int totalCount;

  /// What the badge shows: the server's count, kept current by live arrivals and marking.
  final int unread;
  final bool loading;
  final bool loadingMore;
  final AppError? error;

  bool get hasMore => items.length < totalCount;

  NotificationsState copyWith({
    List<NotificationDto>? items,
    int? page,
    int? totalCount,
    int? unread,
    bool? loading,
    bool? loadingMore,
    AppError? error,
    bool clearError = false,
  }) => NotificationsState(
    items: items ?? this.items,
    page: page ?? this.page,
    totalCount: totalCount ?? this.totalCount,
    unread: unread ?? this.unread,
    loading: loading ?? this.loading,
    loadingMore: loadingMore ?? this.loadingMore,
    error: clearError ? null : error ?? this.error,
  );
}

/// The notification centre and the unread badge. A live `notification` goes to the top of the list; after
/// every (re)connect the list and count are reloaded, since nothing sent while offline is replayed.
class NotificationsController extends Notifier<NotificationsState> {
  NotificationsRepository get _repository => ref.read(notificationsRepositoryProvider);

  @override
  NotificationsState build() {
    final events = ref.watch(liveEventsProvider).listen(_onEvent);
    ref.onDispose(() => unawaited(events.cancel()));
    Future.microtask(refresh);
    return const NotificationsState();
  }

  Future<void> refresh() async {
    try {
      final (page, unread) = (await _repository.page(1), await _repository.unreadCount());
      if (!ref.mounted) return;
      state = NotificationsState(
        items: page.items,
        page: 1,
        totalCount: page.totalCount,
        unread: unread,
        loading: false,
      );
    } on AppError catch (error) {
      if (ref.mounted) state = state.copyWith(loading: false, error: error);
    }
  }

  Future<void> loadMore() async {
    if (state.loading || state.loadingMore || !state.hasMore || state.error != null) return;
    state = state.copyWith(loadingMore: true);
    try {
      final next = await _repository.page(state.page + 1);
      final seen = {for (final n in state.items) n.id};
      state = state.copyWith(
        items: [...state.items, ...next.items.where((n) => seen.add(n.id))],
        page: state.page + 1,
        totalCount: next.totalCount,
        loadingMore: false,
      );
    } on AppError catch (error) {
      state = state.copyWith(loadingMore: false, error: error);
    }
  }

  Future<void> markRead(NotificationDto notification) async {
    if (notification.isRead) return;
    state = state.copyWith(
      items: [for (final n in state.items) n.id == notification.id ? _read(n) : n],
      unread: state.unread > 0 ? state.unread - 1 : 0,
    );
    try {
      final unread = await _repository.markRead(notification.id);
      state = state.copyWith(unread: unread);
    } on AppError {
      // The badge corrects itself on the next reload.
    }
  }

  Future<void> markAllRead() async {
    final before = state;
    state = state.copyWith(items: [for (final n in state.items) _read(n)], unread: 0, clearError: true);
    try {
      state = state.copyWith(unread: await _repository.markAllRead());
    } on AppError catch (error) {
      state = before.copyWith(error: error);
    }
  }

  void _onEvent(LiveEvent event) {
    switch (event) {
      case NotificationArrived(:final notification):
        if (state.items.any((n) => n.id == notification.id)) return;
        state = state.copyWith(
          items: [notification, ...state.items],
          totalCount: state.totalCount + 1,
          unread: state.unread + (notification.isRead ? 0 : 1),
        );
      case LiveConnected():
        unawaited(refresh());
      case TicketChanged() || LiveDisconnected():
        break;
    }
  }

  static NotificationDto _read(NotificationDto n) =>
      NotificationDto.fromJson({...n.toJson(), 'isRead': true});
}

final notificationsProvider = NotifierProvider<NotificationsController, NotificationsState>(
  NotificationsController.new,
);
