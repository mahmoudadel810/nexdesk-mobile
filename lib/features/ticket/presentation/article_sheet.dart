import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/api/api.dart';
import '../../../core/api/generated/nex_desk_api.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/l10n/generated/app_localizations.dart';

/// Finds a published help article to link in a reply. Closes with the chosen article.
Future<KbArticleListItem?> pickArticle(BuildContext context) => showModalBottomSheet<KbArticleListItem>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (_) => const ArticleSheet(),
);

class ArticleSheet extends ConsumerStatefulWidget {
  const ArticleSheet({super.key});

  @override
  ConsumerState<ArticleSheet> createState() => _ArticleSheetState();
}

class _ArticleSheetState extends ConsumerState<ArticleSheet> {
  Timer? _debounce;
  int _searches = 0;
  List<KbArticleListItem>? _results;
  AppError? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_search(''));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _typed(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () => unawaited(_search(text)));
  }

  Future<void> _search(String text) async {
    final search = ++_searches;
    final query = text.trim();
    try {
      final page = await ref
          .read(apiProvider)
          .knowledgeBase
          // Drafts are for the team only: the customer could not open their link.
          .listKbArticles(
            status: KbArticleStatus.published,
            search: query.isEmpty ? null : query,
            page: 1,
            pageSize: 10,
          );
      if (!mounted || search != _searches) return;
      setState(() {
        _results = page.items;
        _error = null;
      });
    } on Object catch (error) {
      if (!mounted || search != _searches) return;
      setState(() => _error = AppError.from(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final results = _results;
    return SafeArea(
      child: Padding(
        padding: EdgeInsetsDirectional.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.7),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 8),
                child: Text(l10n.linkArticleTitle, style: theme.textTheme.titleMedium),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 8),
                child: TextField(
                  key: const Key('article-search'),
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    labelText: l10n.searchArticles,
                    prefixIcon: const Icon(Icons.search),
                    isDense: true,
                  ),
                  onChanged: _typed,
                  onSubmitted: (text) {
                    _debounce?.cancel();
                    unawaited(_search(text));
                  },
                ),
              ),
              if (_error case final error?)
                Padding(
                  padding: const EdgeInsetsDirectional.all(16),
                  child: Text(messageFor(error, l10n), style: TextStyle(color: theme.colorScheme.error)),
                )
              else if (results == null)
                const Padding(
                  padding: EdgeInsetsDirectional.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (results.isEmpty)
                Padding(
                  padding: const EdgeInsetsDirectional.all(16),
                  child: Text(l10n.noArticles, textAlign: TextAlign.center),
                )
              else
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final article in results)
                        ListTile(
                          key: Key('article-${article.slug}'),
                          leading: const Icon(Icons.menu_book_outlined),
                          title: Text(article.title),
                          subtitle: Text(article.categoryName),
                          onTap: () => Navigator.pop(context, article),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
