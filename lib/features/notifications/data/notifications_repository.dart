import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api.dart';
import '../../../core/api/generated/nex_desk_api.dart';
import '../../../core/errors/app_error.dart';

/// The signed-in person's notifications. Not cached: the list is short-lived and the badge must match the
/// server.
class NotificationsRepository {
  NotificationsRepository(this._api);

  final NexDeskApi _api;

  static const pageSize = 25;

  Future<PagedResultOfNotificationDto> page(int page) =>
      _guard(() => _api.notifications.listNotifications(page: page, pageSize: pageSize));

  Future<int> unreadCount() async => (await _guard(_api.notifications.getUnreadNotificationCount)).count;

  /// Returns the unread count after marking.
  Future<int> markRead(String id) async =>
      (await _guard(() => _api.notifications.markNotificationRead(id: id))).count;

  Future<int> markAllRead() async => (await _guard(_api.notifications.markAllNotificationsRead)).count;

  static Future<T> _guard<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on Object catch (error) {
      throw AppError.from(error);
    }
  }
}

final notificationsRepositoryProvider = Provider<NotificationsRepository>(
  (ref) => NotificationsRepository(ref.watch(apiProvider)),
);
