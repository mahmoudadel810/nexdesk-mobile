import 'package:flutter_test/flutter_test.dart';
import 'package:nexdesk_mobile/core/push/push_link.dart';

const id = '01a1eb4a-f7f9-7578-8884-e487165a1768';

void main() {
  test('a push opens the ticket from its link, as the API sends it', () {
    expect(
      pushLink({'type': 'TicketAssigned', 'ticketId': id, 'ticketNumber': '271', 'link': '/app/tickets/$id'}),
      '/app/tickets/$id',
    );
  });

  test('a full web address in the link is reduced to the path inside the app', () {
    expect(pushLink({'link': 'https://nexdesk-web.vercel.app/app/tickets/$id'}), '/app/tickets/$id');
  });

  test('without a link, the ticket id is enough', () {
    expect(pushLink({'type': 'Mention', 'ticketId': id}), '/app/tickets/$id');
  });

  test('anything that is not a ticket or the notification centre is ignored', () {
    expect(pushLink({'link': '/app/profile'}), isNull);
    expect(pushLink({'link': '/app/tickets/$id/../../admin'}), isNull);
    expect(pushLink({'ticketId': 'not-a-guid'}), isNull);
    expect(pushLink({'ticketId': '$id?x=1'}), isNull);
    expect(pushLink({}), isNull);
  });

  test('the notification centre is a valid destination', () {
    expect(isAppLink('/app/notifications'), isTrue);
  });
}
