import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import '../theme/app_style.dart';

/// The only PDF-engine adapter. Replace this widget to change rendering engines.
class PdfDocumentView extends StatefulWidget {
  final Uint8List bytes;
  final String sourceName;
  final VoidCallback onRetry;
  const PdfDocumentView({
    super.key,
    required this.bytes,
    required this.sourceName,
    required this.onRetry,
  });

  @override
  State<PdfDocumentView> createState() => _PdfDocumentViewState();
}

class _PdfDocumentViewState extends State<PdfDocumentView> {
  final _controller = PdfViewerController();
  final _query = TextEditingController();
  final _queryFocus = FocusNode();
  PdfTextSearcher? _search;
  int _page = 1;
  int _pages = 0;
  bool _searching = false;
  bool _firstPagePainted = false;

  @override
  void dispose() {
    _query.dispose();
    _queryFocus.dispose();
    _search?.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    if (_searching) {
      _search!.resetTextSearch();
      _query.clear();
      _queryFocus.unfocus();
    }
    setState(() => _searching = !_searching);
  }

  Widget _buildSearchBar() => Container(
    margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
    padding: const EdgeInsets.only(left: 14, right: 4),
    decoration: BoxDecoration(
      color: AppStyle.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppStyle.rule),
    ),
    child: Row(
      children: [
        const Icon(Icons.search, size: 20, color: AppStyle.muted),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: _query,
            focusNode: _queryFocus,
            autofocus: true,
            style: const TextStyle(fontSize: 14, color: AppStyle.text),
            decoration: const InputDecoration(
              hintText: 'Search this PDF',
              filled: false,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 16),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
            onChanged: (value) {
              if (value.trim().isEmpty) {
                _search!.resetTextSearch();
              } else {
                _search!.startTextSearch(value.trim());
              }
            },
          ),
        ),
        const SizedBox(width: 8),
        ListenableBuilder(
          listenable: _search!,
          builder: (_, _) => Row(
            children: [
              SizedBox(
                width: 40,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '${_search!.currentIndex == null ? 0 : _search!.currentIndex! + 1}/${_search!.matches.length}',
                    style: const TextStyle(color: AppStyle.muted, fontSize: 12),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Next match',
                onPressed: _search!.hasMatches
                    ? () => _search!.goToNextMatch()
                    : null,
                iconSize: 20,
                icon: const Icon(Icons.keyboard_arrow_down),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Close search',
          onPressed: _toggleSearch,
          iconSize: 20,
          icon: const Icon(Icons.close),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => Column(
    children: [
      if (_searching) _buildSearchBar(),
      Expanded(
        child: Stack(
          fit: StackFit.expand,
          children: [
            PdfViewer.data(
              widget.bytes,
              sourceName: widget.sourceName,
              controller: _controller,
              params: PdfViewerParams(
                backgroundColor: AppStyle.background,
                margin: 12,
                maxImageBytesCachedOnMemory: 32 * 1024 * 1024,
                buildContextMenu: (context, selection) =>
                    AdaptiveTextSelectionToolbar.buttonItems(
                      anchors: TextSelectionToolbarAnchors(
                        primaryAnchor: selection.anchorA,
                        secondaryAnchor: selection.anchorB,
                      ),
                      buttonItems: [
                        if (selection.textSelectionDelegate.isCopyAllowed &&
                            selection.textSelectionDelegate.hasSelectedText)
                          ContextMenuButtonItem(
                            type: ContextMenuButtonType.copy,
                            onPressed: () => selection.textSelectionDelegate
                                .copyTextSelection(),
                          ),
                        if (selection.isTextSelectionEnabled &&
                            !selection.textSelectionDelegate.isSelectingAllText)
                          ContextMenuButtonItem(
                            type: ContextMenuButtonType.selectAll,
                            onPressed: () =>
                                selection.textSelectionDelegate.selectAllText(),
                          ),
                      ],
                    ),
                pagePaintCallbacks: [
                  if (_search != null) _search!.pageTextMatchPaintCallback,
                ],
                onViewerReady: (document, controller) {
                  if (mounted) {
                    setState(() {
                      _search ??= PdfTextSearcher(controller);
                      _pages = document.pages.length;
                    });
                  }
                },
                onPageChanged: (page) {
                  if (mounted && page != null) setState(() => _page = page);
                },
                // Document-ready fires before the page bitmap exists. Keep the
                // dark cover until pdfrx confirms the initial image is rendered.
                onDocumentLoadFinished: (document, succeeded) {
                  if (mounted) setState(() => _firstPagePainted = true);
                },
                loadingBannerBuilder: (context, bytesDownloaded, totalBytes) =>
                    const Center(child: CircularProgressIndicator()),
                errorBannerBuilder: (context, error, stack, document) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Couldn’t open this PDF.'),
                      TextButton(
                        onPressed: widget.onRetry,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            IgnorePointer(
              ignoring: _firstPagePainted,
              child: AnimatedOpacity(
                key: const ValueKey('pdf-loading-cover'),
                opacity: _firstPagePainted ? 0 : 1,
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                child: ColoredBox(
                  color: AppStyle.background,
                  child: _firstPagePainted
                      ? null
                      : const Center(child: CircularProgressIndicator()),
                ),
              ),
            ),
          ],
        ),
      ),
      DecoratedBox(
        decoration: const BoxDecoration(
          color: AppStyle.surface,
          border: Border(top: BorderSide(color: AppStyle.rule)),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                tooltip: 'Previous page',
                onPressed: _pages > 0 && _page > 1
                    ? () => _controller.goToPage(pageNumber: _page - 1)
                    : null,
                icon: const Icon(Icons.chevron_left),
              ),
              Text(
                _pages == 0 ? 'Opening…' : '$_page / $_pages',
                style: const TextStyle(color: AppStyle.muted),
              ),
              IconButton(
                tooltip: 'Next page',
                onPressed: _pages > 0 && _page < _pages
                    ? () => _controller.goToPage(pageNumber: _page + 1)
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
              const SizedBox(width: 16),
              IconButton(
                tooltip: 'Search PDF',
                onPressed: _pages > 0 ? _toggleSearch : null,
                icon: const Icon(Icons.search),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
