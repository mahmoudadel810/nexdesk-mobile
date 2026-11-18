/// Where a notification or link may take the person inside the app. Anything else is ignored, so a crafted
/// push or link cannot open an arbitrary screen.
final _ticket = RegExp(
  r'^/app/tickets/[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

bool isAppLink(String path) => _ticket.hasMatch(path) || path == '/app/notifications';

/// The screen a push opens, from its data (`type`, `ticketId`, `ticketNumber`, `link`; see `PushPayloads` in
/// the API). The `link` is preferred; a payload with only a ticket id still works.
String? pushLink(Map<String, Object?> data) {
  final link = data['link'];
  if (link is String) {
    final path = Uri.tryParse(link)?.path;
    if (path != null && isAppLink(path)) return path;
  }
  final ticketId = data['ticketId'];
  if (ticketId is String && isAppLink('/app/tickets/$ticketId')) return '/app/tickets/$ticketId';
  return null;
}
