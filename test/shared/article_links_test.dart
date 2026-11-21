import 'package:flutter_test/flutter_test.dart';
import 'package:nexdesk_mobile/shared/article_links.dart';

void main() {
  test('points at the customer portal page of the article, as the web does', () {
    expect(
      articleUrl('https://nexdesk.app/', 'brightpath', 'download-an-invoice'),
      'https://nexdesk.app/portal/brightpath/kb/download-an-invoice',
    );
  });

  test('puts the link at the caret and keeps it apart from the words around it', () {
    expect(insertArticleLink('See this.', 8, 'Invoices', 'https://x/kb/i'), (
      text: 'See this Invoices: https://x/kb/i .',
      caret: 33,
    ));
    expect(insertArticleLink('Hi ', 3, 'Invoices', 'https://x/kb/i'), (
      text: 'Hi Invoices: https://x/kb/i',
      caret: 27,
    ));
    expect(insertArticleLink('', 0, 'Invoices', 'https://x/kb/i').text, 'Invoices: https://x/kb/i');
    expect(insertArticleLink('abc', 99, 'T', 'u').text, 'abc T: u');
    expect(insertArticleLink('abc', -1, 'T', 'u').text, 'T: u abc');
  });
}
