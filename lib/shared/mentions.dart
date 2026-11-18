/// "@Full Name" mentions, ported from the web app (frontend/src/app/shared/mentions.ts) so both read and write
/// them the way the API does.
library;

/// The "@na" being typed just before the caret. [start] is where its "@" is.
typedef MentionQuery = ({int start, String query});

typedef MentionPart = ({String text, bool mention});

final _wordChar = RegExp(r'[\p{L}\p{N}]', unicode: true);
final _query = RegExp(r"(?:^|[^\p{L}\p{N}@])@([\p{L}\p{N}.'-]*(?: [\p{L}\p{N}.'-]*)?)$", unicode: true);

bool _isWordChar(String text, int index) =>
    index >= 0 && index < text.length && _wordChar.hasMatch(text[index]);

MentionQuery? mentionQuery(String text, int caret) {
  final match = _query.firstMatch(text.substring(0, caret.clamp(0, text.length)));
  if (match == null) return null;
  final typed = match.group(1)!;
  return (start: caret - typed.length - 1, query: typed);
}

/// People whose full name, or any word of it, starts with what was typed.
List<T> mentionCandidates<T>(List<T> people, String Function(T) fullName, String query, {int limit = 6}) {
  final typed = query.trim().toLowerCase();
  return people
      .where((person) {
        final name = fullName(person).toLowerCase();
        return typed.isEmpty ||
            name.startsWith(typed) ||
            name.split(RegExp(r'\s+')).any((w) => w.startsWith(typed));
      })
      .take(limit)
      .toList();
}

/// Replaces the query with "@Full Name " and says where the caret goes next.
({String text, int caret}) insertMention(String text, MentionQuery query, int caret, String name) {
  final mention = '@$name ';
  final rest = text.substring(caret).replaceFirst(RegExp('^ '), '');
  return (text: text.substring(0, query.start) + mention + rest, caret: query.start + mention.length);
}

/// Splits a message into plain text and "@Full Name" mentions of the given people: whole names only, longest
/// first, ignoring case.
List<MentionPart> splitMentions(String body, List<String> names) {
  final lower = body.toLowerCase();
  final ranges = <(int, int)>[];
  final unique = {for (final n in names) n.trim()}.where((n) => n.isNotEmpty).toList()
    ..sort((a, b) => b.length.compareTo(a.length));
  for (final name in unique) {
    final token = '@$name'.toLowerCase();
    for (var at = lower.indexOf(token); at >= 0; at = lower.indexOf(token, at + 1)) {
      final end = at + token.length;
      final free = !ranges.any((r) => at < r.$2 && end > r.$1);
      if (free && !_isWordChar(body, at - 1) && !_isWordChar(body, end)) ranges.add((at, end));
    }
  }

  ranges.sort((a, b) => a.$1.compareTo(b.$1));
  final parts = <MentionPart>[];
  var cursor = 0;
  for (final (from, to) in ranges) {
    if (from > cursor) parts.add((text: body.substring(cursor, from), mention: false));
    parts.add((text: body.substring(from, to), mention: true));
    cursor = to;
  }
  if (cursor < body.length) parts.add((text: body.substring(cursor), mention: false));
  return parts;
}
