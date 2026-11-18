import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../data/inbox_query.dart';
import 'ticket_list.dart';

/// Full-text search across every ticket, open or not, as the person types. "#42" or "42" finds that number.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _text = TextEditingController();
  Timer? _debounce;
  String _search = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _text.dispose();
    super.dispose();
  }

  void _changed(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      final cleaned = value.trim().replaceFirst(RegExp(r'^#(?=\d+$)'), '');
      if (cleaned != _search) setState(() => _search = cleaned);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          key: const Key('search-field'),
          controller: _text,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(hintText: l10n.searchHint, border: InputBorder.none),
          onChanged: _changed,
        ),
      ),
      // Words need two letters to be useful; a ticket number is searched from its first digit.
      body: _search.length < 2 && !RegExp(r'^\d+$').hasMatch(_search)
          ? const SizedBox.shrink()
          : TicketList(
              key: ValueKey(_search),
              query: const InboxQuery().searching(_search),
              emptyText: l10n.emptySearch,
              onOpen: (id) => context.push('/app/tickets/$id'),
            ),
    );
  }
}
