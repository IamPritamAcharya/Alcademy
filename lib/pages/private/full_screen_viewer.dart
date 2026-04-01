import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;

class FullScreenViewer extends StatefulWidget {
  final String filePath;
  final String type;

  const FullScreenViewer({
    Key? key,
    required this.filePath,
    required this.type,
  }) : super(key: key);

  @override
  _FullScreenViewerState createState() => _FullScreenViewerState();
}

class _FullScreenViewerState extends State<FullScreenViewer>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  bool _isAppBarVisible = true;
  TransformationController? _transformationController;

  @override
  void initState() {
    super.initState();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _fadeController.forward();

    if (widget.type == 'Photos') {
      _transformationController = TransformationController();
    }

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) _toggleAppBarVisibility();
    });
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _fadeController.dispose();
    _transformationController?.dispose();
    super.dispose();
  }

  void _toggleAppBarVisibility() {
    setState(() {
      _isAppBarVisible = !_isAppBarVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: _isAppBarVisible
          ? AppBar(
              backgroundColor: Colors.black.withOpacity(0.5),
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
              title: Text(
                _getTitle(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.info_outline),
                  onPressed: _showFileInfo,
                ),
                if (widget.type == 'Photos')
                  IconButton(
                    icon: const Icon(Icons.zoom_in),
                    onPressed: _resetZoom,
                  ),
              ],
            )
          : null,
      body: GestureDetector(
        onTap: _toggleAppBarVisibility,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: _buildContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (widget.type) {
      case 'Photos':
        return _buildPhotoViewer();
      case 'Videos':
        return _buildVideoViewer();
      case 'Documents':
        return _buildDocumentViewer();
      case 'Notes':
        return _buildNoteViewer();
      default:
        return _buildUnsupportedViewer();
    }
  }

  Widget _buildPhotoViewer() {
    return InteractiveViewer(
      transformationController: _transformationController,
      minScale: 0.5,
      maxScale: 3.0,
      boundaryMargin: const EdgeInsets.all(20),
      child: Center(
        child: Hero(
          tag: 'photo_${widget.filePath}',
          child: Image.file(
            File(widget.filePath),
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => _buildErrorWidget(
              'Failed to load image',
              Icons.broken_image,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoViewer() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.play_circle_filled,
              color: Colors.white,
              size: 80,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Video Player',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Tap to play video\n(Video player integration needed)',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Video player integration needed'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            icon: const Icon(Icons.play_arrow),
            label: const Text('Play Video'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.2),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentViewer() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getDocumentIcon(),
                color: Colors.orange,
                size: 60,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              path.basename(widget.filePath),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              _getFileSize(),
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  icon: Icons.open_in_new,
                  label: 'Open With',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text('Open with external app functionality needed'),
                        backgroundColor: Colors.blue,
                      ),
                    );
                  },
                ),
                _buildActionButton(
                  icon: Icons.share,
                  label: 'Share',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Share functionality coming soon'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteViewer() {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _loadNoteData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.teal),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return _buildErrorWidget(
            'Failed to load note',
            Icons.note_outlined,
          );
        }

        final noteData = snapshot.data!;
        return SingleChildScrollView(
          padding: EdgeInsets.only(
            top: _isAppBarVisible
                ? kToolbarHeight + MediaQuery.of(context).padding.top + 20
                : 50,
            left: 20,
            right: 20,
            bottom: 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (noteData['title'] != null &&
                  noteData['title'].toString().isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: Colors.teal.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    noteData['title'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: SelectableText(
                  noteData['content'] ?? 'No content',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.6,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (noteData['createdAt'] != null ||
                  noteData['modifiedAt'] != null)
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (noteData['createdAt'] != null)
                        _buildTimestamp('Created', noteData['createdAt']),
                      if (noteData['modifiedAt'] != null &&
                          noteData['modifiedAt'] != noteData['createdAt'])
                        _buildTimestamp('Modified', noteData['modifiedAt']),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimestamp(String label, dynamic timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white.withOpacity(0.2),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.red,
              size: 60,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            'Please try again or check if the file exists',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildUnsupportedViewer() {
    return _buildErrorWidget(
      'Unsupported file type',
      Icons.help_outline,
    );
  }

  String _getTitle() {
    if (widget.type == 'Notes') {
      return 'Private Note';
    }
    return path.basename(widget.filePath);
  }

  IconData _getDocumentIcon() {
    final extension = path.extension(widget.filePath).toLowerCase();
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

  String _getFileSize() {
    try {
      final file = File(widget.filePath);
      if (!file.existsSync()) return 'File not found';

      final bytes = file.lengthSync();
      if (bytes < 1024) return '$bytes B';
      if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
      if (bytes < 1024 * 1024 * 1024)
        return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    } catch (e) {
      return 'Unknown size';
    }
  }

  Future<Map<String, dynamic>?> _loadNoteData() async {
    try {
      final file = File(widget.filePath);
      if (!file.existsSync()) return null;

      final content = await file.readAsString();
      return jsonDecode(content) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  void _resetZoom() {
    if (_transformationController != null) {
      _transformationController!.value = Matrix4.identity();
    }
  }

  void _showFileInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('File Information',
            style: TextStyle(color: Colors.white)),
        content: _buildFileInfoContent(),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.teal)),
          ),
        ],
      ),
    );
  }

  Widget _buildFileInfoContent() {
    try {
      final file = File(widget.filePath);
      if (!file.existsSync()) {
        return const Text(
          'File information not available',
          style: TextStyle(color: Colors.white70),
        );
      }

      final stat = file.statSync();
      final fileName = path.basename(widget.filePath);
      final fileSize = _getFileSize();
      final created = stat.changed;
      final modified = stat.modified;

      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('Name', fileName),
          _buildInfoRow('Size', fileSize),
          _buildInfoRow('Type', widget.type),
          _buildInfoRow('Created', _formatDateTime(created)),
          if (modified != created)
            _buildInfoRow('Modified', _formatDateTime(modified)),
          _buildInfoRow('Path', widget.filePath),
        ],
      );
    } catch (e) {
      return Text(
        'Error loading file information: $e',
        style: const TextStyle(color: Colors.red),
      );
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          SelectableText(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
