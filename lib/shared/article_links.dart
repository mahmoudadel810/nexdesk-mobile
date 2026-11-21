/// The customer portal's page for a published article, which opens without signing in. The same link the web
/// composer inserts.
String articleUrl(String webBaseUrl, String tenantSlug, String articleSlug) {
  final base = webBaseUrl.replaceAll(RegExp(r'/+$'), '');
  return '$base/portal/${Uri.encodeComponent(tenantSlug)}/kb/${Uri.encodeComponent(articleSlug)}';
}

/// Puts "Title: link" at the caret, with a space on either side where it would otherwise touch a word (a full
/// stop straight after the link would be read as part of it). Returns the new text and the caret after the link.
({String text, int caret}) insertArticleLink(String text, int caret, String title, String url) {
  final at = caret.clamp(0, text.length);
  final before = text.substring(0, at);
  final after = text.substring(at);
  final lead = before.isNotEmpty && !RegExp(r'\s$').hasMatch(before) ? ' ' : '';
  final trail = after.isNotEmpty && !RegExp(r'^\s').hasMatch(after) ? ' ' : '';
  final link = '$lead$title: $url';
  return (text: '$before$link$trail$after', caret: before.length + link.length);
}
