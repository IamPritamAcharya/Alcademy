import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'private_content_viewer.dart';

class PrivatePage extends StatefulWidget {
  const PrivatePage({Key? key}) : super(key: key);

  @override
  _PrivatePageState createState() => _PrivatePageState();
}

class _PrivatePageState extends State<PrivatePage> {
  final ImagePicker _picker = ImagePicker();
  List<String> _privatePhotos = [];
  List<String> _privateVideos = [];
  List<String> _privateDocuments = [];
  List<String> _privateNotes = [];

  Directory? _privateDirectory;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializePrivateSpace();
  }

  Future<void> _initializePrivateSpace() async {
    try {
      await _initializePrivateDirectory();
      await _loadPrivateContent();
    } catch (e) {
      _showErrorMessage('Failed to initialize private space: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _initializePrivateDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    _privateDirectory = Directory('${appDir.path}/private_space');

    await Directory('${_privateDirectory!.path}/photos')
        .create(recursive: true);
    await Directory('${_privateDirectory!.path}/videos')
        .create(recursive: true);
    await Directory('${_privateDirectory!.path}/documents')
        .create(recursive: true);
    await Directory('${_privateDirectory!.path}/notes').create(recursive: true);
  }

  Future<void> _loadPrivateContent() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _privatePhotos = prefs.getStringList('private_photos') ?? [];
      _privateVideos = prefs.getStringList('private_videos') ?? [];
      _privateDocuments = prefs.getStringList('private_documents') ?? [];
      _privateNotes = prefs.getStringList('private_notes') ?? [];
    });
  }

  Future<void> _savePrivateContent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('private_photos', _privatePhotos);
      await prefs.setStringList('private_videos', _privateVideos);
      await prefs.setStringList('private_documents', _privateDocuments);
      await prefs.setStringList('private_notes', _privateNotes);
    } catch (e) {
      _showErrorMessage('Failed to save content: $e');
    }
  }

  Future<String?> _copyToPrivateDirectory(
      String originalPath, String subfolder) async {
    try {
      final file = File(originalPath);
      if (!await file.exists()) {
        _showErrorMessage('File not found');
        return null;
      }

      final fileName = path.basename(originalPath);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = path.extension(fileName);
      final nameWithoutExt = path.basenameWithoutExtension(fileName);
      final newFileName = '${timestamp}_${nameWithoutExt}$extension';
      final newPath = '${_privateDirectory!.path}/$subfolder/$newFileName';

      await file.copy(newPath);
      return newPath;
    } catch (e) {
      _showErrorMessage('Error copying file: $e');
      return null;
    }
  }

  Future<void> _addPrivatePhoto() async {
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
            _buildBottomSheetOption(
              icon: Icons.camera_alt,
              title: 'Take Photo',
              onTap: () => _pickImage(ImageSource.camera),
            ),
            const SizedBox(height: 10),
            _buildBottomSheetOption(
              icon: Icons.photo_library,
              title: 'Choose from Gallery',
              onTap: () => _pickImage(ImageSource.gallery),
            ),
          ],
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
          setState(() {
            _privatePhotos.add(privatePath);
          });
          await _savePrivateContent();
          _showSuccessMessage('Photo added to private space');
        }
      }
    } catch (e) {
      _showErrorMessage('Failed to add photo: $e');
    }
  }

  Future<void> _addPrivateVideo() async {
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
            _buildBottomSheetOption(
              icon: Icons.videocam,
              title: 'Record Video',
              onTap: () => _pickVideo(ImageSource.camera),
            ),
            const SizedBox(height: 10),
            _buildBottomSheetOption(
              icon: Icons.video_library,
              title: 'Choose from Gallery',
              onTap: () => _pickVideo(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

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
          setState(() {
            _privateVideos.add(privatePath);
          });
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
      FilePickerResult? result = await FilePicker.platform.pickFiles(
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
          'pptx'
        ],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final privatePath = await _copyToPrivateDirectory(
            result.files.single.path!, 'documents');
        if (privatePath != null) {
          setState(() {
            _privateDocuments.add(privatePath);
          });
          await _savePrivateContent();
          _showSuccessMessage('Document added to private space');
        }
      }
    } catch (e) {
      _showErrorMessage('Failed to add document: $e');
    }
  }

  Future<void> _addPrivateNote() async {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Add Private Note',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: titleController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      hintText: 'Note title...',
                      hintStyle:
                          TextStyle(color: Colors.white.withOpacity(0.5)),
                      enabledBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Colors.white.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide:
                            const BorderSide(color: Colors.teal, width: 1.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 120),
                    child: TextField(
                      controller: noteController,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.05),
                        hintText: 'Enter your private note...',
                        hintStyle:
                            TextStyle(color: Colors.white.withOpacity(0.5)),
                        enabledBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.white.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                              const BorderSide(color: Colors.teal, width: 1.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white.withOpacity(0.7),
                        ),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 10),
                      TextButton(
                        onPressed: () async {
                          if (noteController.text.isNotEmpty) {
                            await _saveNote(
                                titleController.text, noteController.text);
                            Navigator.pop(context);
                          }
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.teal,
                        ),
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveNote(String title, String content) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final noteData = {
        'title': title.isEmpty ? 'Untitled Note' : title,
        'content': content,
        'createdAt': timestamp,
        'modifiedAt': timestamp,
      };

      final fileName = 'note_$timestamp.json';
      final notePath = '${_privateDirectory!.path}/notes/$fileName';

      await File(notePath).writeAsString(jsonEncode(noteData));

      setState(() {
        _privateNotes.add(notePath);
      });
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
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 15),
            Text(title,
                style: const TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
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
        backgroundColor: Colors.red,
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
          onDelete: (index) async {
            try {
              final filePath = items[index];
              await File(filePath).delete();

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
                  break;
              }
            });
            await _savePrivateContent();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F0F0F),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const CircularProgressIndicator(
                  color: Color(0xFF00D4AA),
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Loading Private Space...',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: const Text(
          'Private Space',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Colors.white24),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          color: Colors.white,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F0F0F),
              Color(0xFF1A1A1A),
            ],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF00D4AA).withOpacity(0.1),
                              const Color(0xFF00A693).withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF00D4AA).withOpacity(0.2),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00D4AA).withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF00D4AA),
                                    const Color(0xFF00A693),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF00D4AA)
                                        .withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.shield_outlined,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Welcome to Private Space',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Your content is stored privately in a separate secure folder',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Private Content',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1A1A),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1),
                              ),
                            ),
                            child: Text(
                              '${_privatePhotos.length + _privateVideos.length + _privateDocuments.length + _privateNotes.length} items',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.75,
                  ),
                  delegate: SliverChildListDelegate([
                    _buildModernPrivateItem(
                      icon: Icons.photo_camera_outlined,
                      title: 'Photos',
                      subtitle: '${_privatePhotos.length} items',
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFFA855F7)],
                      ),
                      shadowColor: const Color(0xFF8B5CF6),
                      onTap: () =>
                          _navigateToContentViewer('Photos', _privatePhotos),
                      onAdd: _addPrivatePhoto,
                    ),
                    _buildModernPrivateItem(
                      icon: Icons.play_circle_outline,
                      title: 'Videos',
                      subtitle: '${_privateVideos.length} items',
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                      ),
                      shadowColor: const Color(0xFF3B82F6),
                      onTap: () =>
                          _navigateToContentViewer('Videos', _privateVideos),
                      onAdd: _addPrivateVideo,
                    ),
                    _buildModernPrivateItem(
                      icon: Icons.description_outlined,
                      title: 'Documents',
                      subtitle: '${_privateDocuments.length} files',
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                      ),
                      shadowColor: const Color(0xFFF59E0B),
                      onTap: () => _navigateToContentViewer(
                          'Documents', _privateDocuments),
                      onAdd: _addPrivateDocument,
                    ),
                    _buildModernPrivateItem(
                      icon: Icons.edit_note_outlined,
                      title: 'Notes',
                      subtitle: '${_privateNotes.length} notes',
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00D4AA), Color(0xFF00A693)],
                      ),
                      shadowColor: const Color(0xFF00D4AA),
                      onTap: () =>
                          _navigateToContentViewer('Notes', _privateNotes),
                      onAdd: _addPrivateNote,
                    ),
                  ]),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.info_outline,
                            color: Colors.blue.shade400,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Files are copied and stored independently. Even if deleted from the original location, they remain accessible here.',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              height: 1.4,
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
        ),
      ),
    );
  }

  Widget _buildModernPrivateItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Gradient gradient,
    required Color shadowColor,
    required VoidCallback onTap,
    required VoidCallback onAdd,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: shadowColor.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              flex: 5,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: gradient,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: shadowColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            Flexible(
              flex: 1,
              child: GestureDetector(
                onTap: onAdd,
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(minHeight: 36),
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: shadowColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 14,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Add',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
