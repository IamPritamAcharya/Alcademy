import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'full_screen_viewer.dart';
import 'note_editor.dart';

class PrivateContentViewer extends StatefulWidget {
  final String contentType;
  final List<String> items;
  final Function(int) onDelete;
  final Function(int, String)? onUpdate;

  const PrivateContentViewer({
    Key? key,
    required this.contentType,
    required this.items,
    required this.onDelete,
    this.onUpdate,
  }) : super(key: key);

  @override
  _PrivateContentViewerState createState() => _PrivateContentViewerState();
}

class _PrivateContentViewerState extends State<PrivateContentViewer> {
  bool _isGridView = true;
  String _searchQuery = '';
  List<String> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
  }

  void _filterItems(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredItems = widget.items;
      } else {
        _filteredItems = widget.items.where((item) {
          final fileName = path.basename(item).toLowerCase();
          return fileName.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        title: Text(
          'Private ${widget.contentType}',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (widget.items.isNotEmpty) ...[
            IconButton(
              icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
              onPressed: () {
                setState(() {
                  _isGridView = !_isGridView;
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: _showSearchDialog,
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          if (_searchQuery.isNotEmpty)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Colors.white54, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Search: $_searchQuery',
                      style: const TextStyle(color: Colors.white54),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _filterItems(''),
                    child: const Icon(Icons.close,
                        color: Colors.white54, size: 20),
                  ),
                ],
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
    );
  }

  Widget _buildEmptyState() {
    if (widget.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getEmptyStateIcon(),
                size: 60,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No ${widget.contentType.toLowerCase()} added yet',
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Tap the + button to add your first ${widget.contentType.toLowerCase().substring(0, widget.contentType.length - 1)}',
              style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    } else {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search_off,
              size: 60,
              color: Colors.white54,
            ),
            const SizedBox(height: 20),
            Text(
              'No results found for "$_searchQuery"',
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }
  }

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
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.0,
      ),
      itemCount: _filteredItems.length,
      itemBuilder: (context, index) {
        return _buildGridItem(index);
      },
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredItems.length,
      itemBuilder: (context, index) {
        return _buildListItem(index);
      },
    );
  }

  Widget _buildGridItem(int index) {
    final item = _filteredItems[index];
    return GestureDetector(
      onTap: () => _openFullScreenViewer(item),
      onLongPress: () => _showOptionsBottomSheet(index),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              _buildContentPreview(item),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    _getContentIcon(),
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListItem(int index) {
    final item = _filteredItems[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: ListTile(
        onTap: () => _openFullScreenViewer(item),
        onLongPress: () => _showOptionsBottomSheet(index),
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: _getContentColor().withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: widget.contentType == 'Photos'
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(item),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.broken_image,
                      color: Colors.white54,
                    ),
                  ),
                )
              : Icon(
                  _getContentIcon(),
                  color: _getContentColor(),
                  size: 24,
                ),
        ),
        title: Text(
          _getItemTitle(item),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          _getItemSubtitle(item),
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 12,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: Colors.white.withOpacity(0.3),
          size: 16,
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
            color: Colors.grey[800],
            child: const Center(
              child: Icon(
                Icons.broken_image,
                color: Colors.white54,
                size: 40,
              ),
            ),
          ),
        );
      case 'Videos':
        return Container(
          color: Colors.black54,
          child: const Center(
            child: Icon(
              Icons.play_circle_filled,
              color: Colors.white,
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
              Icon(
                _getDocumentIcon(filePath),
                color: Colors.orange,
                size: 40,
              ),
              const SizedBox(height: 8),
              Text(
                path.basename(filePath),
                style: const TextStyle(color: Colors.white, fontSize: 12),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      case 'Notes':
        return FutureBuilder<Map<String, dynamic>?>(
          future: _loadNoteData(filePath),
          builder: (context, snapshot) {
            final noteData = snapshot.data;
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.note,
                    color: Colors.teal,
                    size: 30,
                  ),
                  const SizedBox(height: 8),
                  if (noteData != null) ...[
                    Text(
                      noteData['title'] ?? 'Untitled',
                      style: const TextStyle(
                        color: Colors.white,
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
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 10,
                        ),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ] else
                    const Text(
                      'Loading...',
                      style: TextStyle(color: Colors.white54, fontSize: 10),
                    ),
                ],
              ),
            );
          },
        );
      default:
        return Container(
          color: Colors.grey[800],
          child: const Center(
            child: Icon(
              Icons.file_present,
              color: Colors.white54,
              size: 40,
            ),
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
        return Colors.purple;
      case 'Videos':
        return Colors.blue;
      case 'Documents':
        return Colors.orange;
      case 'Notes':
        return Colors.teal;
      default:
        return Colors.grey;
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
    if (widget.contentType == 'Notes') {
      try {
        final file = File(item);
        if (file.existsSync()) {
          final content = file.readAsStringSync();
          final data = jsonDecode(content) as Map<String, dynamic>;
          return data['title'] ?? 'Untitled Note';
        }
      } catch (e) {}
    }
    return path.basenameWithoutExtension(item);
  }

  String _getItemSubtitle(String item) {
    final file = File(item);
    if (!file.existsSync()) return 'File not found';

    final stat = file.statSync();
    final size = _formatFileSize(stat.size);
    final date = _formatDate(stat.modified);

    return '$size • $date';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
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
      final file = File(filePath);
      if (!file.existsSync()) return null;

      final content = await file.readAsString();
      return jsonDecode(content) as Map<String, dynamic>;
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
          builder: (context) => FullScreenViewer(
            filePath: item,
            type: widget.contentType,
          ),
        ),
      );
    }
  }

  void _showOptionsBottomSheet(int index) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
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
                color: Colors.white.withOpacity(0.3),
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
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color ?? Colors.white, size: 24),
            const SizedBox(width: 15),
            Text(
              title,
              style: TextStyle(
                color: color ?? Colors.white,
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
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('Delete Item', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete this item permanently? This action cannot be undone.',
          style: TextStyle(color: Colors.white.withOpacity(0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: TextStyle(color: Colors.white.withOpacity(0.7))),
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

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String searchText = _searchQuery;
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text('Search', style: TextStyle(color: Colors.white)),
          content: TextField(
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            onChanged: (value) => searchText = value,
            decoration: InputDecoration(
              hintText: 'Search ${widget.contentType.toLowerCase()}...',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.teal),
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _filterItems('');
                Navigator.pop(context);
              },
              child:
                  const Text('Clear', style: TextStyle(color: Colors.orange)),
            ),
            TextButton(
              onPressed: () {
                _filterItems(searchText);
                Navigator.pop(context);
              },
              child: const Text('Search', style: TextStyle(color: Colors.teal)),
            ),
          ],
        );
      },
    );
  }
}
