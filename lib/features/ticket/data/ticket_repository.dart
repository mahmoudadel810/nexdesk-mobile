import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api.dart';
import '../../../core/api/generated/nex_desk_api.dart';
import '../../../core/auth/session_controller.dart';
import '../../../core/cache/database.dart';
import '../../../core/errors/app_error.dart';

/// A ticket and its timeline, as last seen.
class TicketView {
  const TicketView({required this.ticket, required this.timeline, this.cachedAt});

  final TicketDetailDto ticket;
  final List<TimelineItem> timeline;
  final DateTime? cachedAt;
}

/// What was being written on a ticket, kept on the phone until it is sent.
typedef Draft = ({String body, bool internal});

/// Reading and changing one ticket. The last 50 opened tickets are kept on the phone with their timelines.
class TicketRepository {
  TicketRepository(this._api, this._database, this._now);

  final NexDeskApi _api;
  final AppDatabase _database;
  final DateTime Function() _now;

  Future<TicketView?> cached(String id) async {
    final row = await _database.read('ticket:$id');
    if (row == null) return null;
    final json = jsonDecode(row.json) as Map<String, Object?>;
    return TicketView(
      ticket: TicketDetailDto.fromJson(json['ticket']! as Map<String, Object?>),
      timeline: [
        for (final item in json['timeline']! as List<Object?>)
          TimelineItem.fromJson(item! as Map<String, Object?>),
      ],
      cachedAt: row.storedAt,
    );
  }

  Future<TicketView> fetch(String id) async {
    final (ticket, timeline) = await _guard(
      () async => (await _api.tickets.getTicket(id: id), await _api.tickets.getTicketTimeline(id: id)),
    );
    await _store(ticket, timeline);
    return TicketView(ticket: ticket, timeline: timeline);
  }

  Future<TicketView> send(
    String id, {
    required String body,
    required bool internal,
    TicketStatus? setStatus,
    List<String> attachmentIds = const [],
  }) async {
    await _guard(
      () => _api.tickets.addTicketMessage(
        id: id,
        body: AddMessageRequest(
          body: body,
          isInternal: internal,
          attachmentIds: attachmentIds.isEmpty ? null : attachmentIds,
          setStatus: setStatus,
        ),
      ),
    );
    await clearDraft(id);
    return fetch(id);
  }

  Future<TicketView> update(String id, UpdateTicketRequest change) async {
    await _guard(() => _api.tickets.updateTicket(id: id, body: change));
    return fetch(id);
  }

  Future<TicketView> assign(String id, {required int version, String? assigneeId, String? teamId}) async {
    await _guard(
      () => _api.tickets.assignTicket(
        id: id,
        body: AssignTicketRequest(assigneeId: assigneeId, teamId: teamId, version: version),
      ),
    );
    return fetch(id);
  }

  Future<TicketView> watch(String id, {required bool watching}) async {
    await _guard(() => watching ? _api.tickets.watchTicket(id: id) : _api.tickets.unwatchTicket(id: id));
    return fetch(id);
  }

  /// Everyone who can be mentioned or assigned: the workspace's active team.
  Future<List<UserDto>> people() async {
    try {
      final page = await _api.users.listUsers(isActive: true, page: 1, pageSize: 100);
      await _database.put('people', jsonEncode([for (final u in page.items) u.toJson()]), _now());
      return page.items;
    } on Object catch (error) {
      final row = await _database.read('people');
      if (row == null) throw AppError.from(error);
      return [
        for (final u in jsonDecode(row.json) as List<Object?>) UserDto.fromJson(u! as Map<String, Object?>),
      ];
    }
  }

  /// Custom field labels by key, so the ticket shows "Account ID" rather than "account_id".
  Future<Map<String, String>> fieldLabels() async {
    try {
      final fields = await _api.customFields.listCustomFields();
      final labels = {for (final f in fields) f.key: f.label};
      await _database.put('field-labels', jsonEncode(labels), _now());
      return labels;
    } on Object {
      final row = await _database.read('field-labels');
      return row == null ? const {} : (jsonDecode(row.json) as Map<String, Object?>).cast<String, String>();
    }
  }

  Future<Draft?> draft(String id) async {
    final row = await _database.read('draft:$id');
    if (row == null) return null;
    final json = jsonDecode(row.json) as Map<String, Object?>;
    return (body: json['body']! as String, internal: json['internal']! as bool);
  }

  Future<void> saveDraft(String id, Draft draft) => draft.body.trim().isEmpty
      ? clearDraft(id)
      : _database.put('draft:$id', jsonEncode({'body': draft.body, 'internal': draft.internal}), _now());

  Future<void> clearDraft(String id) => _database.remove('draft:$id');

  Future<void> _store(TicketDetailDto ticket, List<TimelineItem> timeline) async {
    await _database.put(
      'ticket:${ticket.id}',
      jsonEncode({
        'ticket': ticket.toJson(),
        'timeline': [for (final item in timeline) item.toJson()],
      }),
      _now(),
    );
    await _database.keepNewest('ticket:', 50);
  }

  static Future<T> _guard<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on Object catch (error) {
      throw AppError.from(error);
    }
  }
}

final ticketRepositoryProvider = Provider<TicketRepository>(
  (ref) => TicketRepository(ref.watch(apiProvider), ref.watch(databaseProvider), ref.watch(clockProvider)),
);
