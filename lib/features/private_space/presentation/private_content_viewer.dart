import 'package:port/shared/widgets/app_bar_divider.dart';
import 'package:port/shared/widgets/collection_intro.dart';
import 'package:port/shared/widgets/search_results_page.dart';
import 'package:port/shared/widgets/editorial_list_row.dart';
import 'package:port/shared/theme/app_style.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import '../data/note_repository.dart';
import '../data/file_metadata_repository.dart';
import 'package:path/path.dart' as path;
import 'package:port/features/private_space/presentation/full_screen_viewer.dart';
import 'package:port/features/private_space/presentation/note_editor.dart';

class PrivateContentViewer extends StatefulWidget {
  final String contentType;
  final List<String> items;
  final Function(int) onDelete;
  final Function(int, String)? onUpdate;
  final VoidCallback? onAdd;
  final Listenable? collectionChanges;

  const PrivateContentViewer({
    super.key,
    required this.contentType,
    required this.items,
    required this.onDelete,
    this.onUpdate,
    this.onAdd,
    this.collectionChanges,
  });

  @override
  State<PrivateContentViewer> createState() => _PrivateContentViewerState();
}

class _PrivateContentViewerState extends State<PrivateContentViewer> {
  bool _isGridView = true;
  List<String> _filteredItems = [];
  final _notes = NoteRepository();
  final _metadata = FileMetadataRepository();
  final Map<String, Future<Map<String, dynamic>?>> _noteLoads = {};
  final Map<String, Map<String, dynamic>> _noteData = {};
  final Map<String, FileStat?> _fileStats = {};
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
    _isGridView =
        widget.contentType == 'Photos' || widget.contentType == 'Videos';
    _refreshMetadata();
    widget.collectionChanges?.addListener(_onCollectionChanged);
  }

  @override
  void didUpdateWidget(covariant PrivateContentViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.collectionChanges != widget.collectionChanges) {
      oldWidget.collectionChanges?.removeListener(_onCollectionChanged);
      widget.collectionChanges?.addListener(_onCollectionChanged);
    }
    _filteredItems = widget.items;
    _refreshMetadata();
  }

  @override
  void dispose() {
    widget.collectionChanges?.removeListener(_onCollectionChanged);
    super.dispose();
  }

  void _onCollectionChanged() {
    if (!mounted) return;
    setState(() => _filteredItems = widget.items);
    _refreshMetadata();
  }

  void _refreshMetadata() {
    final generation = ++_loadGeneration;
    _noteLoads.clear();
    _noteData.clear();
    _fileStats.clear();
    for (final item in widget.items) {
      if (widget.contentType == 'Notes') {
        _noteLoads[item] = _loadNoteData(item).then((data) {
          if (mounted && generation == _loadGeneration && data != null) {
            setState(() => _noteData[item] = data);
          }
          return data;
        });
      }
      _loadFileStat(item, generation);
    }
  }

  Future<void> _loadFileStat(String item, int generation) async {
    try {
      final stat = await _metadata.read(item);
      if (mounted && generation == _loadGeneration) {
        setState(() => _fileStats[item] = stat);
      }
    } on FileSystemException {
      if (mounted && generation == _loadGeneration) {
        setState(() => _fileStats[item] = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyle.background,
      appBar: AppBar(
        centerTitle: false,
        title: Text(
          'Private ${widget.contentType}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppStyle.text),
        ),
        bottom: const AppBarDivider(),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppStyle.text),
        actions: [
          if (widget.items.isNotEmpty) ...[
            IconButton(
              tooltip: _isGridView ? 'Show list' : 'Show grid',
              icon: Icon(
                _isGridView
                    ? Icons.view_agenda_outlined
                    : Icons.grid_view_rounded,
              ),
              onPressed: () {
                setState(() {
                  _isGridView = !_isGridView;
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.search),
              tooltip: 'Search private ${widget.contentType.toLowerCase()}',
              onPressed: _openSearch,
            ),
          ],
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: CollectionIntro(
              eyebrow: 'PERSONAL ARCHIVE',
              title: widget.contentType,
              detail:
                  '${widget.items.length} saved items · Hold an item for options',
            ),
          ),
          Expanded(
            child: _filteredItems.isEmpty
                ? _buildEmptyState()
                : _isGridView
                ? _buildGridView()
                : _buildListView(),
          ),
        ],
      ),
      bottomNavigationBar: widget.onAdd == null
          ? null
          : SafeArea(
              minimum: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: FilledButton.icon(
                onPressed: widget.onAdd,
                icon: const Icon(Icons.add_rounded, size: 20),
                label: Text(switch (widget.contentType) {
                  'Photos' => 'Add photo',
                  'Videos' => 'Add video',
                  'Documents' => 'Add document',
                  'Notes' => 'New note',
                  _ => 'Add item',
                }),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 18,
                    horizontal: 16,
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildEmptyState() => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getEmptyStateIcon(), size: 56, color: AppStyle.muted),
          const SizedBox(height: 20),
          Text(
            'No ${widget.contentType.toLowerCase()} added yet',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppStyle.muted,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Add an item from your private space to get started.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppStyle.muted, fontSize: 14, height: 1.5),
          ),
        ],
      ),
    ),
  );

  IconData _getEmptyStateIcon() {
    switch (widget.contentType) {
      case 'Photos':
        return Icons.photo_library_outlined;
      case 'Videos':
        return Icons.video_library_outlined;
      case 'Documents':
        return Icons.description_outlined;
      case 'Notes':
        return Icons.note_outlined;
      default:
        return Icons.folder_outlined;
    }
  }

  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: 132 + MediaQuery.textScalerOf(context).scale(14) * 4,
      ),
      itemCount: _filteredItems.length,
      itemBuilder: (context, index) {
        return _buildGridItem(index);
      },
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      itemCount: _filteredItems.length,
      itemBuilder: (context, index) {
        return _buildListItem(index);
      },
    );
  }

  Widget _buildGridItem(int index) {
    final item = _filteredItems[index];
    final media =
        widget.contentType == 'Photos' || widget.contentType == 'Videos';
    return Material(
      color: AppStyle.surface,
      borderRadius: BorderRadius.circular(6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openFullScreenViewer(item),
        onLongPress: () => _showOptionsBottomSheet(index),
        child: Column(
          children: [
            Expanded(
              child: SizedBox(
                width: double.infinity,
                child: _buildContentPreview(item),
              ),
            ),
            if (media)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _getItemTitle(item),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      _getContentIcon(),
                      color: _getContentColor(),
                      size: 16,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildListItem(int index) {
    final item = _filteredItems[index];
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openFullScreenViewer(item),
        onLongPress: () => _showOptionsBottomSheet(index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 4),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppStyle.rule)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 60,
                decoration: BoxDecoration(
                  color: AppStyle.surface,
                  borderRadius: BorderRadius.circular(3),
                  border: Border(
                    left: BorderSide(color: _getContentColor(), width: 3),
                  ),
                ),
                child: widget.contentType == 'Photos'
                    ? Image.file(
                        File(item),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.photo_outlined,
                          color: _getContentColor(),
                        ),
                      )
                    : Icon(
                        widget.contentType == 'Documents'
                            ? _getDocumentIcon(item)
                            : _getContentIcon(),
                        color: _getContentColor(),
                        size: 26,
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getItemTitle(item),
                      style: const TextStyle(
                        fontSize: 18,
                        height: 1.3,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getItemSubtitle(item),
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: AppStyle.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Padding(
                padding: EdgeInsets.only(top: 22),
                child: Icon(
                  Icons.north_east_rounded,
                  color: AppStyle.muted,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContentPreview(String filePath) {
    switch (widget.contentType) {
      case 'Photos':
        return Image.file(
          File(filePath),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) => Container(
            color: AppStyle.surface,
            child: const Center(
              child: Icon(Icons.broken_image, color: AppStyle.muted, size: 40),
            ),
          ),
        );
      case 'Videos':
        return Container(
          color: Colors.black54,
          child: const Center(
            child: Icon(
              Icons.play_circle_filled,
              color: AppStyle.text,
              size: 50,
            ),
          ),
        );
      case 'Documents':
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_getDocumentIcon(filePath), color: AppStyle.gold, size: 40),
              const SizedBox(height: 8),
              Text(
                path.basename(filePath),
                style: const TextStyle(color: AppStyle.text, fontSize: 12),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      case 'Notes':
        return FutureBuilder<Map<String, dynamic>?>(
          future: _noteLoads[filePath],
          builder: (context, snapshot) {
            final noteData = snapshot.data;
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.note, color: AppStyle.blue, size: 30),
                  const SizedBox(height: 8),
                  if (noteData != null) ...[
                    Text(
                      noteData['title'] ?? 'Untitled',
                      style: const TextStyle(
                        color: AppStyle.text,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Text(
                        noteData['content'] ?? '',
                        style: TextStyle(
                          color: AppStyle.text.withValues(alpha: 0.8),
                          fontSize: 10,
                        ),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ] else
                    const Text(
                      'Loading...',
                      style: TextStyle(color: AppStyle.muted, fontSize: 10),
                    ),
                ],
              ),
            );
          },
        );
      default:
        return Container(
          color: AppStyle.surface,
          child: const Center(
            child: Icon(Icons.file_present, color: AppStyle.muted, size: 40),
          ),
        );
    }
  }

  IconData _getContentIcon() {
    switch (widget.contentType) {
      case 'Photos':
        return Icons.photo;
      case 'Videos':
        return Icons.videocam;
      case 'Documents':
        return Icons.description;
      case 'Notes':
        return Icons.note;
      default:
        return Icons.file_present;
    }
  }

  Color _getContentColor() {
    switch (widget.contentType) {
      case 'Photos':
        return AppStyle.lilac;
      case 'Videos':
        return AppStyle.blue;
      case 'Documents':
        return AppStyle.gold;
      case 'Notes':
        return AppStyle.blue;
      default:
        return AppStyle.muted;
    }
  }

  IconData _getDocumentIcon(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    switch (extension) {
      case '.pdf':
        return Icons.picture_as_pdf;
      case '.doc':
      case '.docx':
        return Icons.description;
      case '.xls':
      case '.xlsx':
        return Icons.table_chart;
      case '.ppt':
      case '.pptx':
        return Icons.slideshow;
      case '.txt':
        return Icons.text_snippet;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _getItemTitle(String item) {
    if (widget.contentType == 'Notes' && _noteData.containsKey(item)) {
      return _noteData[item]!['title'] as String? ?? 'Untitled Note';
    }
    return path.basenameWithoutExtension(item);
  }

  String _getItemSubtitle(String item) {
    if (!_fileStats.containsKey(item)) return 'Loading...';
    final stat = _fileStats[item];
    if (stat == null) return 'File not found';
    final size = FileMetadataRepository.formatSize(stat.size);
    final date = _formatDate(stat.modified);
    return '$size • $date';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Future<Map<String, dynamic>?> _loadNoteData(String filePath) async {
    try {
      return (await _notes.read(filePath))?.toJson();
    } catch (e) {
      return null;
    }
  }

  void _openFullScreenViewer(String item) {
    if (widget.contentType == 'Notes') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NoteEditor(
            filePath: item,
            onSave: (updatedPath) {
              if (!mounted) return;
              _refreshMetadata();
              if (widget.onUpdate != null) {
                final index = widget.items.indexOf(item);
                if (index != -1) {
                  widget.onUpdate!(index, updatedPath);
                }
              }
            },
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              FullScreenViewer(filePath: item, type: widget.contentType),
        ),
      );
    }
  }

  void _showOptionsBottomSheet(int index) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppStyle.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppStyle.text.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            if (widget.contentType == 'Notes')
              _buildBottomSheetOption(
                icon: Icons.edit,
                title: 'Edit Note',
                onTap: () {
                  Navigator.pop(context);
                  _openFullScreenViewer(_filteredItems[index]);
                },
              ),
            _buildBottomSheetOption(
              icon: Icons.delete,
              title: 'Delete',
              color: Colors.red,
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(index);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSheetOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppStyle.rule.withValues(alpha: .65),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color ?? AppStyle.text, size: 24),
            const SizedBox(width: 15),
            Text(
              title,
              style: TextStyle(
                color: color ?? AppStyle.text,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppStyle.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text(
          'Delete Item',
          style: TextStyle(color: AppStyle.text),
        ),
        content: Text(
          'Are you sure you want to delete this item permanently? This action cannot be undone.',
          style: TextStyle(color: AppStyle.text.withValues(alpha: 0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppStyle.text.withValues(alpha: 0.7)),
            ),
          ),
          TextButton(
            onPressed: () {
              final actualIndex = widget.items.indexOf(_filteredItems[index]);
              if (actualIndex != -1) {
                widget.onDelete(actualIndex);
              }
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _openSearch() => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => SearchResultsPage<String>(
        title: 'Search private ${widget.contentType.toLowerCase()}',
        hint: 'Find ${widget.contentType.toLowerCase()}',
        items: List.of(widget.items),
        searchableText: (item) =>
            '${_getItemTitle(item)} ${path.basename(item)}',
        resultBuilder: (_, item, index) => EditorialListRow(
          number: index + 1,
          title: _getItemTitle(item),
          category: widget.contentType,
          subtitle: _getItemSubtitle(item),
          accent: _getContentColor(),
          leading: SizedBox(
            width: 28,
            child: Icon(_getContentIcon(), size: 24, color: _getContentColor()),
          ),
          onTap: () => _openFullScreenViewer(item),
        ),
      ),
    ),
  );
}
