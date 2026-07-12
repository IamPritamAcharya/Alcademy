import 'dart:convert';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'models/gate_model.dart';
import 'utils/gate_utils.dart';
import 'utils/gate_data_fetcher.dart';
import 'gate_dynamic_pyq.dart';
import 'gate_pdf_viewer.dart';

// Main GATE Page

class GatePage extends StatefulWidget {
  const GatePage({super.key});

  @override
  State<GatePage> createState() => _GatePageState();
}

class _GatePageState extends State<GatePage> with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<GateCategory> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await fetchGateData();

    List<GateCategory> loadedCategories = [];
    for (var cat in data['gateCategories']) {
      List<GateResource> resources = [];
      for (var res in cat['resources']) {
        resources.add(GateResource(
          title: res['title'],
          subtitle: res['subtitle'],
          url: res['url'],
          keyUrl: res['keyUrl'],
          subjectCodes: res['subjectCodes'] != null ? List<String>.from(res['subjectCodes']) : null,
          tag: res['tag'],
          icon: getGateIconData(res['icon']),
          gradient: [
            Color(int.parse(res['gradient'][0])),
            Color(int.parse(res['gradient'][1])),
          ],
        ));
      }
      loadedCategories.add(GateCategory(
        name: cat['name'],
        icon: getGateIconData(cat['icon']),
        accent: Color(int.parse(cat['accent'])),
        resources: resources,
      ));
    }

    if (mounted) {
      setState(() {
        _categories = loadedCategories;
        _tabController = TabController(length: _categories.length, vsync: this);
        _tabController.addListener(() {
          if (mounted) setState(() {});
        });
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    if (!_isLoading) _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<GateResource> get _filteredResults {
    if (_searchQuery.isEmpty) return [];
    final q = _searchQuery.toLowerCase();
    return _categories
        .expand((c) => c.resources)
        .where((r) =>
            r.title.toLowerCase().contains(q) ||
            r.subtitle.toLowerCase().contains(q) ||
            r.tag.toLowerCase().contains(q))
        .toList();
  }

  void _openResource(GateResource resource) {
    if (resource.url.isEmpty) return;

    if (resource.url.contains('{year}') || resource.url.contains('{branch}')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => GateDynamicSelectionPage(resource: resource)),
      );
    } else if (resource.url.toLowerCase().endsWith('.pdf')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => GatePdfViewer(url: resource.url, title: resource.title)),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => _GateWebView(resource: resource)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1D1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1D1E),
        elevation: 0,
        title: Center(
          child: const Text(
            'GATE Preparation',
            style: TextStyle(
              fontFamily: 'ProductSans',
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF3DFFC0)))
            : Column(
                children: [
                  _buildSearchBar(),
                  _buildTabBar(),
                  Expanded(
                    child: _searchQuery.isNotEmpty
                        ? _buildSearchResults()
                        : TabBarView(
                            controller: _tabController,
                            children: _categories
                                .map((cat) => _buildCategoryList(cat))
                                .toList(),
                          ),
                  ),
                ],
              ),
      ),
    );
  }

  // Search bar

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(
            fontFamily: 'ProductSans',
            color: Colors.white,
            fontSize: 15,
          ),
          onChanged: (val) => setState(() => _searchQuery = val),
          decoration: InputDecoration(
            hintText: 'Search subjects, topics...',
            hintStyle: TextStyle(
              fontFamily: 'ProductSans',
              color: Colors.white.withOpacity(0.3),
              fontSize: 15,
            ),
            prefixIcon: Icon(Icons.search_rounded,
                color: Colors.white.withOpacity(0.4), size: 22),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.close_rounded,
                        color: Colors.white.withOpacity(0.4), size: 20),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
    );
  }

  // Tab bar

  Widget _buildTabBar() {
    return SizedBox(
      height: 60,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = _tabController.index == index;
          return GestureDetector(
            onTap: () {
              setState(() {
                _tabController.animateTo(index);
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: isSelected
                    ? Colors.white.withOpacity(0.15)
                    : Colors.white.withOpacity(0.05),
                border: Border.all(
                  color: isSelected
                      ? Colors.white.withOpacity(0.3)
                      : Colors.white.withOpacity(0.1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    cat.icon,
                    color: isSelected
                        ? Colors.white
                        : Colors.white.withOpacity(0.7),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    cat.name,
                    style: TextStyle(
                      fontFamily: 'ProductSans',
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withOpacity(0.7),
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Category resource list

  Widget _buildCategoryList(GateCategory cat) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: cat.resources.length,
      itemBuilder: (_, i) => _ResourceCard(
        resource: cat.resources[i],
        onTap: () => _openResource(cat.resources[i]),
      ),
    );
  }

  // Search results

  Widget _buildSearchResults() {
    final results = _filteredResults;
    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded,
                color: Colors.white.withOpacity(0.20), size: 56),
            const SizedBox(height: 12),
            Text(
              'No results for "$_searchQuery"',
              style: TextStyle(
                fontFamily: 'ProductSans',
                color: Colors.white.withOpacity(0.35),
                fontSize: 15,
              ),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: results.length,
      itemBuilder: (_, i) => _ResourceCard(
        resource: results[i],
        onTap: () => _openResource(results[i]),
      ),
    );
  }
}

// Resource card

class _ResourceCard extends StatelessWidget {
  final GateResource resource;
  final VoidCallback onTap;

  const _ResourceCard({required this.resource, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white.withOpacity(0.1),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    alignment: Alignment.center,
                    child: Icon(resource.icon, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          resource.title,
                          style: const TextStyle(
                            fontFamily: 'ProductSans',
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          resource.subtitle,
                          style: TextStyle(
                            fontFamily: 'ProductSans',
                            fontSize: 14,
                            color: Colors.grey.shade400,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            resource.tag,
                            style: const TextStyle(
                              fontFamily: 'ProductSans',
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(
                    Icons.open_in_browser_rounded,
                    color: Colors.greenAccent,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// In-app WebView for resources

class _GateWebView extends StatefulWidget {
  final GateResource resource;
  const _GateWebView({required this.resource});

  @override
  State<_GateWebView> createState() => _GateWebViewState();
}

class _GateWebViewState extends State<_GateWebView> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onNavigationRequest: (request) {
          return NavigationDecision.navigate;
        },
        onPageFinished: (_) => setState(() => _isLoading = false),
        onWebResourceError: (_) => setState(() {
          _isLoading = false;
          _hasError = true;
        }),
        onHttpError: (err) {
          if (err.response?.statusCode != null &&
              err.response!.statusCode >= 400) {
            setState(() {
              _isLoading = false;
              _hasError = true;
            });
          }
        },
      ))
      ..loadRequest(Uri.parse(widget.resource.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1D1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1D1E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.resource.title,
              style: const TextStyle(
                fontFamily: 'ProductSans',
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              widget.resource.tag,
              style: TextStyle(
                fontFamily: 'ProductSans',
                color: Colors.white70,
                fontSize: 11,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser_rounded,
                color: Colors.white70, size: 20),
            tooltip: 'Open in browser',
            onPressed: () => launchUrl(Uri.parse(widget.resource.url),
                mode: LaunchMode.externalApplication),
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: LinearProgressIndicator(
            value: _isLoading ? null : 1.0,
            backgroundColor: Colors.white.withOpacity(0.05),
            color: Colors.white,
            minHeight: 2,
          ),
        ),
      ),
      body: _hasError ? _buildError() : WebViewWidget(controller: _controller),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => launchUrl(Uri.parse(widget.resource.url),
            mode: LaunchMode.externalApplication),
        backgroundColor: const Color(0xFF2A2D2E),
        icon: const Icon(Icons.download_rounded, color: Colors.white, size: 20),
        label: const Text(
          'Download / Open externally',
          style: TextStyle(
            fontFamily: 'ProductSans',
            fontWeight: FontWeight.w700,
            color: Colors.white,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.cloud_off_rounded,
                color: Colors.redAccent, size: 36),
          ),
          const SizedBox(height: 16),
          const Text('Resource unavailable',
              style: TextStyle(
                  fontFamily: 'ProductSans',
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('Try opening in your browser',
              style: TextStyle(
                  fontFamily: 'ProductSans',
                  color: Colors.white.withOpacity(0.40),
                  fontSize: 13)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => launchUrl(Uri.parse(widget.resource.url),
                mode: LaunchMode.externalApplication),
            icon: const Icon(Icons.open_in_browser_rounded, size: 16),
            label: const Text('Open in Browser'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB97AFF),
              foregroundColor: Colors.white,
              textStyle: const TextStyle(fontFamily: 'ProductSans'),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}
