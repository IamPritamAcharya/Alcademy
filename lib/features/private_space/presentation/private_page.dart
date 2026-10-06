import 'dart:io';
import 'package:port/features/home/presentation/widgets/home_pressable.dart';
import 'package:port/shared/widgets/app_bar_divider.dart';
import 'package:port/shared/widgets/collection_intro.dart';
import 'widgets/private_note_dialog.dart';
import 'package:port/shared/theme/app_style.dart';
import 'package:port/features/private_space/data/private_space_repository.dart';
import 'package:port/features/private_space/data/note_repository.dart';
import 'package:port/features/private_space/models/private_category.dart';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:port/features/private_space/presentation/private_content_viewer.dart';

class PrivatePage extends StatefulWidget {
  final PrivateSpaceRepository? repository;
  final NoteRepository? notes;
  const PrivatePage({super.key, this.repository, this.notes});

  @override
  State<PrivatePage> createState() => _PrivatePageState();
}

class _PrivatePageState extends State<PrivatePage> {
  final ImagePicker _picker = ImagePicker();
  late final _repository = widget.repository ?? PrivateSpaceRepository();
  late final _notes = widget.notes ?? NoteRepository();
  List<String> _privatePhotos = [];
  List<String> _privateVideos = [];
  List<String> _privateDocuments = [];
  List<String> _privateNotes = [];

  bool _isLoading = true;
  final _collectionChanges = ValueNotifier<int>(0);
  Future<Map<String, dynamic>?>? _notePreview;

  @override
  void initState() {
    super.initState();
    _initializePrivateSpace();
  }

  @override
  void dispose() {
    _collectionChanges.dispose();
    super.dispose();
  }

  Future<void> _initializePrivateSpace() async {
    try {
      await _initializePrivateDirectory();
      await _loadPrivateContent();
    } catch (e) {
      _showErrorMessage('Failed to initialize private space: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _initializePrivateDirectory() async {
    await _repository.initialize();
  }

  Future<void> _loadPrivateContent() async {
    final manifest = await _repository.loadManifest();
    if (!mounted) return;
    if (mounted) {
      setState(() {
        _privatePhotos = manifest[PrivateCategory.photos]!;
        _privateVideos = manifest[PrivateCategory.videos]!;
        _privateDocuments = manifest[PrivateCategory.documents]!;
        _privateNotes = manifest[PrivateCategory.notes]!;
        _refreshNotePreview();
      });
    }
  }

  Future<void> _savePrivateContent() async {
    try {
      await _repository.saveManifest({
        PrivateCategory.photos: _privatePhotos,
        PrivateCategory.videos: _privateVideos,
        PrivateCategory.documents: _privateDocuments,
        PrivateCategory.notes: _privateNotes,
      });
      if (mounted) _collectionChanges.value++;
    } catch (e) {
      if (mounted) _showErrorMessage('Failed to save content: $e');
    }
  }

  Future<String?> _copyToPrivateDirectory(
    String originalPath,
    String subfolder,
  ) async {
    try {
      final category = PrivateCategory.values.firstWhere(
        (value) => value.folder == subfolder,
      );
      return await _repository.importFile(originalPath, category);
    } catch (e) {
      if (mounted) _showErrorMessage('Error copying file: $e');
      return null;
    }
  }

  Future<void> _addPrivatePhoto() => _showImportSheet(
    'Add photo',
    Icons.camera_alt_outlined,
    'Take Photo',
    () => _pickImage(ImageSource.camera),
    Icons.photo_library_outlined,
    () => _pickImage(ImageSource.gallery),
  );

  Future<void> _showImportSheet(
    String title,
    IconData cameraIcon,
    String cameraLabel,
    VoidCallback camera,
    IconData galleryIcon,
    VoidCallback gallery,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (context) => SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -.5,
                ),
              ),
              const SizedBox(height: 20),
              _buildBottomSheetOption(
                icon: cameraIcon,
                title: cameraLabel,
                onTap: camera,
              ),
              const SizedBox(height: 12),
              _buildBottomSheetOption(
                icon: galleryIcon,
                title: 'Choose from Gallery',
                onTap: gallery,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    Navigator.pop(context);
    try {
      final XFile? photo = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      if (photo != null) {
        final privatePath = await _copyToPrivateDirectory(photo.path, 'photos');
        if (privatePath != null) {
          if (mounted) {
            setState(() {
              _privatePhotos.add(privatePath);
            });
          }
          await _savePrivateContent();
          _showSuccessMessage('Photo added to private space');
        }
      }
    } catch (e) {
      _showErrorMessage('Failed to add photo: $e');
    }
  }

  Future<void> _addPrivateVideo() => _showImportSheet(
    'Add video',
    Icons.videocam_outlined,
    'Record Video',
    () => _pickVideo(ImageSource.camera),
    Icons.video_library_outlined,
    () => _pickVideo(ImageSource.gallery),
  );

  Future<void> _pickVideo(ImageSource source) async {
    Navigator.pop(context);
    try {
      final XFile? video = await _picker.pickVideo(
        source: source,
        maxDuration: const Duration(minutes: 10),
      );
      if (video != null) {
        final privatePath = await _copyToPrivateDirectory(video.path, 'videos');
        if (privatePath != null) {
          if (mounted) {
            setState(() {
              _privateVideos.add(privatePath);
            });
          }
          await _savePrivateContent();
          _showSuccessMessage('Video added to private space');
        }
      }
    } catch (e) {
      _showErrorMessage('Failed to add video: $e');
    }
  }

  Future<void> _addPrivateDocument() async {
    try {
      final result = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: [
          'pdf',
          'doc',
          'docx',
          'txt',
          'rtf',
          'xls',
          'xlsx',
          'ppt',
          'pptx',
        ],
      );

      if (result != null && result.path != null) {
        final privatePath = await _copyToPrivateDirectory(
          result.path!,
          'documents',
        );
        if (privatePath != null) {
          if (mounted) {
            setState(() {
              _privateDocuments.add(privatePath);
            });
          }
          await _savePrivateContent();
          _showSuccessMessage('Document added to private space');
        }
      }
    } catch (e) {
      _showErrorMessage('Failed to add document: $e');
    }
  }

  Future<void> _addPrivateNote() async {
    await showDialog<void>(
      context: context,
      builder: (_) => PrivateNoteDialog(onSave: _saveNote),
    );
  }

  Future<void> _saveNote(String title, String content) async {
    try {
      final notePath = await _notes.save(title: title, content: content);
      if (!mounted) return;

      if (mounted) {
        setState(() {
          _privateNotes.add(notePath);
          _refreshNotePreview();
        });
      }
      await _savePrivateContent();
      _showSuccessMessage('Note added to private space');
    } catch (e) {
      _showErrorMessage('Failed to save note: $e');
    }
  }

  Widget _buildBottomSheetOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) => Material(
    color: AppStyle.surface,
    borderRadius: BorderRadius.circular(8),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(icon, color: AppStyle.paper, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 16, height: 1.3),
              ),
            ),
            const SizedBox(width: 12),
            const Icon(
              Icons.north_east_rounded,
              color: AppStyle.muted,
              size: 18,
            ),
          ],
        ),
      ),
    ),
  );

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppStyle.surface,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppStyle.surface,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _navigateToContentViewer(String type, List<String> items) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PrivateContentViewer(
          contentType: type,
          items: items,
          collectionChanges: _collectionChanges,
          onAdd: switch (type) {
            'Photos' => _addPrivatePhoto,
            'Videos' => _addPrivateVideo,
            'Documents' => _addPrivateDocument,
            'Notes' => _addPrivateNote,
            _ => null,
          },
          onDelete: (index) async {
            try {
              final filePath = items[index];
              await _repository.deleteFile(filePath);

              setState(() {
                switch (type) {
                  case 'Photos':
                    _privatePhotos.removeAt(index);
                    break;
                  case 'Videos':
                    _privateVideos.removeAt(index);
                    break;
                  case 'Documents':
                    _privateDocuments.removeAt(index);
                    break;
                  case 'Notes':
                    _privateNotes.removeAt(index);
                    _refreshNotePreview();
                    break;
                }
              });
              await _savePrivateContent();
              _showSuccessMessage('Item deleted successfully');
            } catch (e) {
              _showErrorMessage('Failed to delete item: $e');
            }
          },
          onUpdate: (index, updatedPath) async {
            setState(() {
              switch (type) {
                case 'Notes':
                  _privateNotes[index] = updatedPath;
                  _refreshNotePreview();
                  break;
              }
            });
            await _savePrivateContent();
          },
        ),
      ),
    );
  }

  void _refreshNotePreview() {
    _notePreview = _privateNotes.isEmpty
        ? null
        : _notes.read(_privateNotes.last).then((note) => note?.toJson());
  }

  @override
  Widget build(BuildContext context) {
    final total =
        _privatePhotos.length +
        _privateVideos.length +
        _privateDocuments.length +
        _privateNotes.length;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Private Space'),
        bottom: const AppBarDivider(),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.fromLTRB(
                20,
                0,
                20,
                16 + MediaQuery.paddingOf(context).bottom,
              ),
              children: [
                CollectionIntro(
                  eyebrow:
                      'ON THIS DEVICE / $total ${total == 1 ? 'ITEM' : 'ITEMS'}',
                  title: 'Personal archive.',
                ),
                _notebook(),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _mediaPanel(
                        'Photos',
                        _privatePhotos,
                        Icons.photo_outlined,
                        AppStyle.lilac,
                        _addPrivatePhoto,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _mediaPanel(
                        'Videos',
                        _privateVideos,
                        Icons.play_arrow_rounded,
                        AppStyle.blue,
                        _addPrivateVideo,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _documents(),
                const SizedBox(height: 24),
                const Text(
                  'Imported files are copies. The originals remain in your gallery or file manager.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.6,
                    color: AppStyle.muted,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _notebook() => HomePressable(
    key: const ValueKey('private-notes'),
    color: AppStyle.surface,
    borderRadius: BorderRadius.circular(8),
    onTap: () => _navigateToContentViewer('Notes', _privateNotes),
    child: Stack(
      children: [
        const Positioned.fill(
          child: IgnorePointer(child: CustomPaint(painter: _NotebookPainter())),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(44, 16, 18, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text('THE NOTEBOOK', style: AppStyle.eyebrow),
                  ),
                  IconButton(
                    tooltip: 'Add notes',
                    onPressed: _addPrivateNote,
                    style: IconButton.styleFrom(
                      backgroundColor: AppStyle.cover,
                      foregroundColor: AppStyle.paper,
                    ),
                    icon: const Icon(Icons.add_rounded, size: 22),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FutureBuilder<Map<String, dynamic>?>(
                future: _notePreview,
                builder: (_, snapshot) {
                  final note = snapshot.data;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        note?['title'] as String? ?? 'Notes',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                          letterSpacing: -.7,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        note?['content'] as String? ?? 'No notes saved yet.',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.6,
                          color: AppStyle.muted,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${_privateNotes.length} ${_privateNotes.length == 1 ? 'note' : 'notes'}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppStyle.accent,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 20,
                    color: AppStyle.paper,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _mediaPanel(
    String title,
    List<String> items,
    IconData icon,
    Color accent,
    VoidCallback add,
  ) => Material(
    key: ValueKey('private-${title.toLowerCase()}'),
    color: AppStyle.surface,
    borderRadius: BorderRadius.circular(8),
    clipBehavior: Clip.antiAlias,
    child: Column(
      children: [
        InkWell(
          onTap: () => _navigateToContentViewer(title, items),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 102,
                  width: double.infinity,
                  child: Center(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Transform.rotate(
                          angle: -.13,
                          child: Container(
                            width: 72,
                            height: 86,
                            decoration: BoxDecoration(
                              color: AppStyle.cover,
                              border: Border.all(color: AppStyle.rule),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                        Transform.rotate(
                          angle: .08,
                          child: Container(
                            width: 72,
                            height: 86,
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: AppStyle.background,
                              border: Border.all(color: AppStyle.rule),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: title == 'Photos' && items.isNotEmpty
                                ? Image.file(
                                    File(items.last),
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        Icon(icon, size: 32, color: accent),
                                  )
                                : Icon(icon, size: 32, color: accent),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                    letterSpacing: -.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${items.length} ${items.length == 1 ? 'item' : 'items'}',
                  style: const TextStyle(fontSize: 12, color: AppStyle.muted),
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1, color: AppStyle.rule),
        Semantics(
          button: true,
          label: 'Add ${title.toLowerCase()}',
          child: InkWell(
            onTap: add,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  Icon(Icons.add_rounded, size: 18, color: accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Add',
                      style: TextStyle(
                        color: accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _documents() => Material(
    key: const ValueKey('private-documents'),
    color: AppStyle.surface,
    borderRadius: BorderRadius.circular(8),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () => _navigateToContentViewer('Documents', _privateDocuments),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 60,
              decoration: BoxDecoration(
                color: AppStyle.cover,
                borderRadius: BorderRadius.circular(3),
                border: const Border(
                  left: BorderSide(color: AppStyle.gold, width: 3),
                ),
              ),
              child: const Icon(
                Icons.description_outlined,
                size: 26,
                color: AppStyle.gold,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Documents',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                      letterSpacing: -.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_privateDocuments.length} ${_privateDocuments.length == 1 ? 'file' : 'files'}',
                    style: const TextStyle(fontSize: 12, color: AppStyle.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Add documents',
              onPressed: _addPrivateDocument,
              icon: const Icon(
                Icons.add_rounded,
                size: 22,
                color: AppStyle.gold,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _NotebookPainter extends CustomPainter {
  const _NotebookPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppStyle.rule;
    canvas.drawLine(const Offset(26, 0), Offset(26, size.height), paint);
    for (double y = 30; y < size.height - 10; y += 32) {
      canvas.drawCircle(Offset(13, y), 3, Paint()..color = AppStyle.background);
    }
    for (double y = size.height - 44; y < size.height; y += 12) {
      canvas.drawLine(
        Offset(size.width * .65, y),
        Offset(size.width - 18, y),
        Paint()..color = AppStyle.rule.withValues(alpha: .4),
      );
    }
  }

  @override
  bool shouldRepaint(_NotebookPainter oldDelegate) => false;
}
