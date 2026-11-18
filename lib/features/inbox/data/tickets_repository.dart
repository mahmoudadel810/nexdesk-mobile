import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api.dart';
import '../../../core/api/generated/nex_desk_api.dart';
import '../../../core/auth/session_controller.dart';
import '../../../core/cache/database.dart';
import '../../../core/errors/app_error.dart';
import 'inbox_query.dart';

/// One page of a list, and whether it came from the phone's cache rather than the network.
class TicketPage {
  const TicketPage({required this.result, this.cachedAt});

  final PagedResultOfTicketListItem result;

  /// When the cached copy was stored; null for a fresh network answer.
  final DateTime? cachedAt;
}

/// Ticket lists for the inbox. The first three pages of each list are kept on the phone, so the inbox opens
/// at once and still shows something offline; the network answer replaces them.
class TicketsRepository {
  TicketsRepository(this._api, this._database, this._me, this._now);

  static const cachedPages = 3;

  final NexDeskApi _api;
  final AppDatabase _database;
  final String Function() _me;
  final DateTime Function() _now;

  Future<TicketPage?> cached(InboxQuery query, int page) async {
    final row = await _database.read(_key(query, page));
    if (row == null) return null;
    return TicketPage(
      result: PagedResultOfTicketListItem.fromJson(jsonDecode(row.json) as Map<String, Object?>),
      cachedAt: row.storedAt,
    );
  }

  Future<TicketPage> fetch(InboxQuery query, int page) async {
    final PagedResultOfTicketListItem result;
    try {
      result = await query.fetch(_api.tickets, me: _me(), page: page);
    } on Object catch (error) {
      throw AppError.from(error);
    }

    if (page <= cachedPages) {
      await _database.put(_key(query, page), jsonEncode(result.toJson()), _now());
    }
    return TicketPage(result: result);
  }

  Future<List<SavedViewDto>> savedViews() async {
    try {
      final views = await _api.savedViews.listSavedViews();
      await _database.put('views', jsonEncode([for (final v in views) v.toJson()]), _now());
      return views;
    } on Object catch (error) {
      final row = await _database.read('views');
      if (row != null) {
        return [
          for (final v in jsonDecode(row.json) as List<Object?>)
            SavedViewDto.fromJson(v! as Map<String, Object?>),
        ];
      }
      throw AppError.from(error);
    }
  }

  static String _key(InboxQuery query, int page) => 'tickets:${query.cacheKey}:$page';
}

final ticketsRepositoryProvider = Provider<TicketsRepository>(
  (ref) => TicketsRepository(
    ref.watch(apiProvider),
    ref.watch(databaseProvider),
    () => ref.read(sessionProvider.notifier).current?.user.id ?? '',
    ref.watch(clockProvider),
  ),
);
