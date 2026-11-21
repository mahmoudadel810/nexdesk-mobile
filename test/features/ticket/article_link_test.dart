import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nexdesk_mobile/app/startup.dart';

import '../../fakes.dart';
import 'ticket_helpers.dart';

const articles = 'GET /api/v1/kb/articles';

Map<String, Object?> article(String title, String slug) => {
  'id': 'article-$slug',
  'title': title,
  'slug': slug,
  'categoryId': 'category-1',
  'categoryName': 'Billing and plans',
  'status': 'Published',
  'publishedAt': '2026-11-01T09:00:00Z',
  'updatedAt': '2026-11-01T09:00:00Z',
  'viewCount': 12,
  'helpfulCount': 3,
  'notHelpfulCount': 0,
};

FakeApi articlesApi({List<String> permissions = const [...agent, 'kb.view']}) {
  final api = ticketApi(permissions: permissions);
  api.routes[articles] = (request) {
    final search = request.queryParameters['Search'] as String?;
    final all = [
      article('Download an invoice', 'download-an-invoice'),
      article('Change your plan', 'change-your-plan'),
    ];
    return json(
      200,
      pageJson(
        all.where((a) => search == null || (a['title']! as String).toLowerCase().contains(search)).toList(),
      ),
    );
  };
  return api;
}

/// The article searches the sheet sent, newest last.
List<Map<String, Object?>> searches(FakeApi api) => [
  for (final call in api.calls)
    if ('${call.method} ${call.path}' == articles) call.queryParameters,
];

/// The test app's /mobile/config answers with https://web.test as the web address.
Future<ProviderContainer> openWithWeb(WidgetTester tester, FakeApi api) => openTicket(tester, api);

void main() {
  testWidgets('a published article is linked where the caret was', (tester) async {
    final api = articlesApi();
    await openWithWeb(tester, api);

    await tester.enterText(find.byKey(const Key('composer')), 'Hi Casey, this explains it.');
    final field = tester.widget<TextField>(find.byKey(const Key('composer')));
    field.controller!.selection = const TextSelection.collapsed(offset: 26);
    await tester.tap(find.byKey(const Key('insert-article')));
    await tester.pumpAndSettle();

    expect(find.text('Change your plan'), findsOneWidget);
    expect(searches(api).single['Status'], 'Published');

    await tester.enterText(find.byKey(const Key('article-search')), 'invoice');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(find.text('Change your plan'), findsNothing);
    expect(searches(api).last, containsPair('Search', 'invoice'));
    expect(searches(api).last, containsPair('Status', 'Published'));

    await tester.tap(find.byKey(const Key('article-download-an-invoice')));
    await tester.pumpAndSettle();

    final text = tester.widget<TextField>(find.byKey(const Key('composer'))).controller!;
    expect(
      text.text,
      'Hi Casey, this explains it Download an invoice: https://web.test/portal/brightpath/kb/download-an-invoice .',
    );
    expect(text.selection.baseOffset, text.text.length - 2);
  });

  testWidgets('a search with no match says so', (tester) async {
    await openWithWeb(tester, articlesApi());

    await tester.tap(find.byKey(const Key('insert-article')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('article-search')), 'zzz');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.text('No published article matches.'), findsOneWidget);
  });

  testWidgets('there is no article button without the web address or the right to read articles', (
    tester,
  ) async {
    final container = await openTicket(tester, articlesApi());
    container.read(webBaseUrlProvider.notifier).set(null);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('insert-article')), findsNothing, reason: 'the web address is not known yet');

    container.read(webBaseUrlProvider.notifier).set('https://web.test');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('insert-article')), findsOneWidget);
  });

  testWidgets('someone who may not read articles gets no article button', (tester) async {
    await openWithWeb(tester, articlesApi(permissions: agent));

    expect(find.byKey(const Key('composer')), findsOneWidget);
    expect(find.byKey(const Key('insert-article')), findsNothing);
  });
}
