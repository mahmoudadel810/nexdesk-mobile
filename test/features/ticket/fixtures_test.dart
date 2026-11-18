import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nexdesk_mobile/core/api/generated/nex_desk_api.dart';

Object? fixture(String name) => jsonDecode(File('test/fixtures/$name').readAsStringSync());

void main() {
  test('a ticket from the real API parses, with its assignee and status', () {
    final ticket = TicketDetailDto.fromJson(fixture('ticket.json')! as Map<String, Object?>);

    expect(ticket.number, 271);
    expect(ticket.status, TicketStatus.new2);
    expect(ticket.assignee, isNotNull);
    expect(ticket.mergedInto, isNull);
  });

  test('a timeline from the real API parses: messages carry no event type, events do', () {
    final timeline = [
      for (final item in fixture('timeline.json')! as List<Object?>)
        TimelineItem.fromJson(item! as Map<String, Object?>),
    ];

    expect(timeline, hasLength(3));
    expect(timeline[0].eventType, isNull);
    expect(timeline[1].eventType, TicketEventType.created);
    expect(timeline[2].eventType, TicketEventType.assigneeChanged);
  });

  test('a timeline item survives a round trip through the phone cache', () {
    final item = TimelineItem.fromJson(
      (fixture('timeline.json')! as List<Object?>)[0]! as Map<String, Object?>,
    );

    final again = TimelineItem.fromJson(jsonDecode(jsonEncode(item.toJson())) as Map<String, Object?>);

    expect(again.eventType, isNull);
    expect(again.body, item.body);
  });
}
