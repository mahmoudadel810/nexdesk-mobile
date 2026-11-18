import 'package:flutter/foundation.dart';

import '../../../core/api/generated/nex_desk_api.dart';

/// The statuses that still need someone: the web's "Unresolved".
const unresolved = [TicketStatus.new2, TicketStatus.open, TicketStatus.pending, TicketStatus.onHold];

/// A filtered ticket list, with the same meaning as the web's filters and saved views.
@immutable
class InboxQuery {
  const InboxQuery({
    this.status,
    this.priority,
    this.assignee,
    this.teamId,
    this.tag,
    this.search,
    this.sort = '-lastActivityAt',
    this.sla,
  });

  /// From a saved view, as the web stores it.
  factory InboxQuery.fromView(TicketViewFilter filter) => InboxQuery(
    status: filter.status,
    priority: filter.priority,
    assignee: filter.assignee,
    teamId: filter.teamId,
    tag: filter.tag,
    search: filter.search,
    sort: filter.sort ?? '-lastActivityAt',
  );

  static const mine = InboxQuery(status: unresolved, assignee: 'me');
  static const unassigned = InboxQuery(status: unresolved, assignee: 'unassigned');
  static const breached = InboxQuery(status: unresolved, sla: TicketSlaFilter.breached, sort: 'due');
  static const atRisk = InboxQuery(status: unresolved, sla: TicketSlaFilter.atRisk, sort: 'due');
  static const all = InboxQuery(status: unresolved);

  final List<TicketStatus>? status;
  final List<TicketPriority>? priority;

  /// `me`, `unassigned`, a user id, or null for anyone.
  final String? assignee;
  final String? teamId;
  final String? tag;
  final String? search;
  final String sort;
  final TicketSlaFilter? sla;

  InboxQuery searching(String text) => InboxQuery(sort: sort, search: text.trim());

  /// Identifies the list in the cache.
  String get cacheKey => [
    'status=${status?.map((s) => s.toJson()).join(',')}',
    'priority=${priority?.map((p) => p.toJson()).join(',')}',
    'assignee=$assignee',
    'team=$teamId',
    'tag=$tag',
    'search=$search',
    'sort=$sort',
    'sla=${sla?.toJson()}',
  ].join('&');

  Future<PagedResultOfTicketListItem> fetch(
    TicketsClient tickets, {
    required String me,
    required int page,
    int pageSize = 25,
  }) => tickets.listTickets(
    status: status,
    priority: priority,
    assigneeId: switch (assignee) {
      'me' => me,
      'unassigned' || null => null,
      final id => id,
    },
    unassigned: assignee == 'unassigned' ? true : null,
    teamId: teamId,
    tag: tag,
    search: search == null || search!.isEmpty ? null : search,
    sort: sort,
    sla: sla,
    page: page,
    pageSize: pageSize,
  );

  @override
  bool operator ==(Object other) => other is InboxQuery && other.cacheKey == cacheKey;

  @override
  int get hashCode => cacheKey.hashCode;
}
