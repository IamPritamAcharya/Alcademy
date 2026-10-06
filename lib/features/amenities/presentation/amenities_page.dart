import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:port/features/amenities/data/amenities_repository.dart';
import 'package:port/shared/theme/app_style.dart';
import 'package:port/shared/widgets/app_bar_divider.dart';
import 'package:port/shared/widgets/collection_intro.dart';
import 'package:port/features/amenities/presentation/amenities_list.dart';
import 'package:port/features/amenities/presentation/pagination_controls.dart';
import 'package:port/shared/widgets/search_results_page.dart';
import 'package:port/features/amenities/presentation/tag_filter_bar.dart';

class AmenitiesPage extends StatefulWidget {
  final http.Client? client;
  const AmenitiesPage({super.key, this.client});
  @override
  State<AmenitiesPage> createState() => _AmenitiesPageState();
}

class _AmenitiesPageState extends State<AmenitiesPage> {
  late final _repository = AmenitiesRepository(client: widget.client);
  final _scroll = ScrollController();
  List<Map<String, dynamic>> _all = [];
  int _page = 1;
  static const _perPage = 10;
  String _tag = '';
  bool _loading = true;
  String? _error;

  List<Map<String, dynamic>> get _filtered => _all.where((item) {
    return _tag.isEmpty || item['tag'] == _tag;
  }).toList();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load({bool refresh = false}) async {
    if (mounted) {
      setState(() {
        _loading = _all.isEmpty;
        _error = null;
      });
    }
    try {
      final items = await _repository.load(forceRefresh: refresh);
      if (!mounted) return;
      setState(() {
        _all = items;
        if (!_all.any((item) => item['tag'] == _tag)) _tag = '';
        _page = _page.clamp(
          1,
          math.max(1, (_filtered.length / _perPage).ceil()),
        );
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'The campus guide couldn’t update. Please try again.';
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _tag = '';
      _page = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final pages = math.max(1, (filtered.length / _perPage).ceil());
    final start = (_page - 1) * _perPage;
    final items = filtered.skip(start).take(_perPage).toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Amenities'),
        bottom: const AppBarDivider(),
      ),
      body: RefreshIndicator(
        onRefresh: () => _load(refresh: true),
        child: ListView(
          controller: _scroll,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            20,
            0,
            20,
            12 + MediaQuery.paddingOf(context).bottom,
          ),
          children: [
            const CollectionIntro(
              eyebrow: 'THE CAMPUS GUIDE',
              title: 'Around campus.',
              detail:
                  'Spaces, facilities, and the places that make up your campus.',
            ),
            SearchEntryPoint(
              hint: 'Find a place or facility',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SearchResultsPage<Map<String, dynamic>>(
                    title: 'Search amenities',
                    hint: 'Find a place or facility',
                    items: List.of(_all),
                    searchableText: (item) => '${item['name']} ${item['tag']}',
                    resultBuilder: (_, item, index) => AmenityEntry(
                      item: item,
                      index: index,
                      heroPrefix: 'amenity-search',
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TagFilterBar(
              tags: _all.map((item) => item['tag'] as String).toSet().toList(),
              selectedTag: _tag,
              onTagSelected: (tag) => setState(() {
                _tag = tag;
                _page = 1;
              }),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Text(
                  _loading
                      ? 'LOADING PLACES'
                      : '${filtered.length} ${filtered.length == 1 ? 'PLACE' : 'PLACES'}',
                  style: AppStyle.eyebrow,
                ),
                const SizedBox(width: 12),
                Expanded(child: Container(height: 1, color: AppStyle.rule)),
              ],
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _error!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppStyle.muted,
                          height: 1.5,
                        ),
                      ),
                      TextButton(
                        onPressed: () => _load(refresh: true),
                        child: const Text('Try again'),
                      ),
                    ],
                  ),
                ),
              if (items.isNotEmpty)
                AmenitiesList(items: items, startIndex: start)
              else if (_error == null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _tag.isNotEmpty
                            ? 'No places in this category.'
                            : 'No amenities listed yet.',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Try another category or pull down to update the guide.',
                        style: TextStyle(
                          color: AppStyle.muted,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                      if (_tag.isNotEmpty)
                        TextButton(
                          onPressed: _clearFilters,
                          child: const Text('Clear filters'),
                        ),
                    ],
                  ),
                ),
              if (pages > 1)
                PaginationControls(
                  currentPage: _page,
                  totalPages: pages,
                  onPageChanged: (page) {
                    setState(() => _page = page);
                    _scroll.animateTo(
                      0,
                      duration: MediaQuery.disableAnimationsOf(context)
                          ? Duration.zero
                          : const Duration(milliseconds: 280),
                      curve: Curves.easeOutCubic,
                    );
                  },
                ),
            ],
          ],
        ),
      ),
    );
  }
}
