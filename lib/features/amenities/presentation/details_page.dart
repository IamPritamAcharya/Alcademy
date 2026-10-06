import 'package:flutter/material.dart';
import 'package:port/shared/theme/app_style.dart';
import 'package:port/shared/widgets/app_bar_divider.dart';
import 'package:port/shared/widgets/collection_intro.dart';
import 'package:port/shared/widgets/markdown_viewer.dart';
import 'package:port/features/amenities/presentation/amenity_photo.dart';

class DetailsPage extends StatefulWidget {
  final Map<String, dynamic> item;
  final String? heroTag;
  const DetailsPage({super.key, required this.item, this.heroTag});
  @override
  State<DetailsPage> createState() => _DetailsPageState();
}

class _DetailsPageState extends State<DetailsPage> {
  final _controller = PageController();
  int _photo = 0;
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openImage(String url) => showDialog<void>(
    context: context,
    builder: (context) => Dialog.fullscreen(
      backgroundColor: AppStyle.background,
      child: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                tooltip: 'Close photo',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ),
            Expanded(
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: AmenityPhoto(url: url, fit: BoxFit.contain),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Pinch to zoom',
                style: TextStyle(fontSize: 12, color: AppStyle.muted),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  void _move(int index) => _controller.animateToPage(
    index,
    duration: MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 300),
    curve: Curves.easeOutCubic,
  );

  @override
  Widget build(BuildContext context) {
    final images = (widget.item['images'] as List? ?? [])
        .whereType<String>()
        .toList();
    final name = widget.item['name'] as String? ?? 'Campus amenity';
    final description = widget.item['description'] as String? ?? '';
    Widget gallery = AspectRatio(
      aspectRatio: 1.6,
      child: PageView.builder(
        controller: _controller,
        itemCount: images.length,
        onPageChanged: (index) => setState(() => _photo = index),
        itemBuilder: (_, index) => Semantics(
          button: true,
          label: 'Open photo ${index + 1}',
          child: GestureDetector(
            onTap: () => _openImage(images[index]),
            child: AmenityPhoto(url: images[index]),
          ),
        ),
      ),
    );
    if (widget.heroTag != null) {
      gallery = Hero(tag: widget.heroTag!, child: gallery);
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus guide'),
        bottom: const AppBarDivider(),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        children: [
          CollectionIntro(
            eyebrow: (widget.item['tag'] as String? ?? 'Campus').toUpperCase(),
            title: name,
          ),
          if (images.isNotEmpty) ...[
            ClipRRect(borderRadius: BorderRadius.circular(8), child: gallery),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'PHOTO ${_photo + 1} / ${images.length}',
                      style: AppStyle.eyebrow,
                    ),
                  ),
                  if (images.length > 1) ...[
                    IconButton(
                      tooltip: 'Previous photo',
                      onPressed: _photo > 0 ? () => _move(_photo - 1) : null,
                      icon: const Icon(Icons.arrow_back_rounded, size: 20),
                    ),
                    IconButton(
                      tooltip: 'Next photo',
                      onPressed: _photo < images.length - 1
                          ? () => _move(_photo + 1)
                          : null,
                      icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                    ),
                  ],
                ],
              ),
            ),
            const Divider(color: AppStyle.rule),
            const SizedBox(height: 20),
          ],
          if (description.trim().isNotEmpty)
            SharedMarkdownViewer(markdownData: description)
          else
            const Text(
              'More details will be added to the campus guide.',
              style: TextStyle(
                color: AppStyle.muted,
                fontSize: 14,
                height: 1.5,
              ),
            ),
        ],
      ),
    );
  }
}
