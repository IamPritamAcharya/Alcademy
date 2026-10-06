import 'package:flutter/material.dart';
import 'package:port/shared/theme/app_style.dart';
import 'package:port/shared/widgets/app_bar_divider.dart';

/// A focused search route: queries and results stay separate from the collection.
class SearchResultsPage<T> extends StatefulWidget {
  final String title;
  final String hint;
  final List<T> items;
  final String Function(T) searchableText;
  final Widget Function(BuildContext, T, int) resultBuilder;
  const SearchResultsPage({
    super.key,
    required this.title,
    required this.hint,
    required this.items,
    required this.searchableText,
    required this.resultBuilder,
  });
  @override
  State<SearchResultsPage<T>> createState() => _SearchResultsPageState<T>();
}

class _SearchResultsPageState<T> extends State<SearchResultsPage<T>> {
  final _controller = TextEditingController();
  String _query = '';
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _query.trim().toLowerCase();
    final results = widget.items
        .where(
          (item) => widget.searchableText(item).toLowerCase().contains(query),
        )
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        bottom: const AppBarDivider(),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: TextField(
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onChanged: (value) => setState(() => _query = value),
              onSubmitted: (_) => FocusScope.of(context).unfocus(),
              decoration: InputDecoration(
                hintText: widget.hint,
                prefixIcon: const Icon(Icons.search_rounded, size: 22),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        onPressed: () {
                          _controller.clear();
                          setState(() => _query = '');
                        },
                        icon: const Icon(Icons.close_rounded, size: 20),
                      ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                20,
                0,
                20,
                12 + MediaQuery.paddingOf(context).bottom,
              ),
              itemCount: results.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          query.isEmpty
                              ? '${results.length} AVAILABLE'
                              : '${results.length} ${results.length == 1 ? 'RESULT' : 'RESULTS'}',
                          style: AppStyle.eyebrow,
                        ),
                        if (results.isEmpty) ...[
                          const SizedBox(height: 28),
                          Text(
                            query.isEmpty
                                ? 'Nothing to search yet.'
                                : 'No matches found.',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Try a different name or keyword.',
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.5,
                              color: AppStyle.muted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }
                return widget.resultBuilder(
                  context,
                  results[index - 1],
                  index - 1,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class SearchEntryPoint extends StatelessWidget {
  final String hint;
  final VoidCallback onTap;
  const SearchEntryPoint({super.key, required this.hint, required this.onTap});
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    child: Material(
      color: AppStyle.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppStyle.rule),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Row(
            children: [
              const Icon(Icons.search_rounded, size: 22, color: AppStyle.muted),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  hint,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppStyle.muted,
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Icon(
                Icons.arrow_forward_rounded,
                size: 18,
                color: AppStyle.muted,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
