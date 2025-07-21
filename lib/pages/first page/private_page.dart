// private_page.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:permission_handler/permission_handler.dart';

class PrivatePage extends StatefulWidget {
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

  @override
  void initState() {
    super.initState();
    _initializePrivateDirectory();
    _loadPrivateContent();
  }

  // Initialize private directory
  Future<void> _initializePrivateDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    _privateDirectory = Directory('${appDir.path}/private_space');
    
    // Create subdirectories
    await Directory('${_privateDirectory!.path}/photos').create(recursive: true);
    await Directory('${_privateDirectory!.path}/videos').create(recursive: true);
    await Directory('${_privateDirectory!.path}/documents').create(recursive: true);
    await Directory('${_privateDirectory!.path}/notes').create(recursive: true);
  }

  // Load existing private content
  Future<void> _loadPrivateContent() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _privatePhotos = prefs.getStringList('private_photos') ?? [];
      _privateVideos = prefs.getStringList('private_videos') ?? [];
      _privateDocuments = prefs.getStringList('private_documents') ?? [];
      _privateNotes = prefs.getStringList('private_notes') ?? [];
    });
  }

  // Save content lists to preferences
  Future<void> _savePrivateContent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('private_photos', _privatePhotos);
    await prefs.setStringList('private_videos', _privateVideos);
    await prefs.setStringList('private_documents', _privateDocuments);
    await prefs.setStringList('private_notes', _privateNotes);
  }

  // Copy file to private directory
  Future<String?> _copyToPrivateDirectory(String originalPath, String subfolder) async {
    try {
      final file = File(originalPath);
      if (!await file.exists()) return null;

      final fileName = path.basename(originalPath);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final newFileName = '${timestamp}_$fileName';
      final newPath = '${_privateDirectory!.path}/$subfolder/$newFileName';
      
      await file.copy(newPath);
      return newPath;
    } catch (e) {
      print('Error copying file: $e');
      return null;
    }
  }

  // Add photo to private space
  Future<void> _addPrivatePhoto() async {
    await Permission.camera.request();
    await Permission.storage.request();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt, color: Colors.white),
              title: Text('Take Photo', style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(context);
                final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
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
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: Colors.white),
              title: Text('Choose from Gallery', style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(context);
                final XFile? photo = await _picker.pickImage(source: ImageSource.gallery);
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
              },
            ),
          ],
        ),
      ),
    );
  }

  // Add video to private space
  Future<void> _addPrivateVideo() async {
    await Permission.camera.request();
    await Permission.storage.request();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.videocam, color: Colors.white),
              title: Text('Record Video', style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(context);
                final XFile? video = await _picker.pickVideo(source: ImageSource.camera);
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
              },
            ),
            ListTile(
              leading: Icon(Icons.video_library, color: Colors.white),
              title: Text('Choose from Gallery', style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(context);
                final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
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
              },
            ),
          ],
        ),
      ),
    );
  }

  // Add document to private space
  Future<void> _addPrivateDocument() async {
    await Permission.storage.request();
    
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );

    if (result != null) {
      final privatePath = await _copyToPrivateDirectory(result.files.single.path!, 'documents');
      if (privatePath != null) {
        setState(() {
          _privateDocuments.add(privatePath);
        });
        await _savePrivateContent();
        _showSuccessMessage('Document added to private space');
      }
    }
  }

  // Add note to private space
  Future<void> _addPrivateNote() async {
    TextEditingController noteController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text('Add Private Note', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: noteController,
          maxLines: 5,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter your private note...',
            hintStyle: TextStyle(color: Colors.white54),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white54),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.teal),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () async {
              if (noteController.text.isNotEmpty) {
                final timestamp = DateTime.now().millisecondsSinceEpoch;
                final fileName = 'note_$timestamp.txt';
                final notePath = '${_privateDirectory!.path}/notes/$fileName';
                
                await File(notePath).writeAsString(noteController.text);
                
                setState(() {
                  _privateNotes.add(notePath);
                });
                await _savePrivateContent();
                Navigator.pop(context);
                _showSuccessMessage('Note added to private space');
              }
            },
            child: Text('Save', style: TextStyle(color: Colors.teal)),
          ),
        ],
      ),
    );
  }

  // Show success message
  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  // Navigate to content viewer
  void _navigateToContentViewer(String type, List<String> items) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PrivateContentViewer(
          contentType: type,
          items: items,
          onDelete: (index) {
            setState(() {
              switch (type) {
                case 'Photos':
                  File(items[index]).deleteSync();
                  _privatePhotos.removeAt(index);
                  break;
                case 'Videos':
                  File(items[index]).deleteSync();
                  _privateVideos.removeAt(index);
                  break;
                case 'Documents':
                  File(items[index]).deleteSync();
                  _privateDocuments.removeAt(index);
                  break;
                case 'Notes':
                  File(items[index]).deleteSync();
                  _privateNotes.removeAt(index);
                  break;
              }
            });
            _savePrivateContent();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        title: Text(
          'Private Space',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black87,
              Colors.grey[900]!,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome section
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.security,
                          color: Colors.green,
                          size: 24,
                        ),
                      ),
                      SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome to Private Space',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              'Content stored independently & securely',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 30),
                
                // Private content section
                Text(
                  'Private Content',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 20),
                
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    children: [
                      _buildPrivateItem(
                        icon: Icons.photo_library,
                        title: 'Private Photos',
                        subtitle: '${_privatePhotos.length} photos',
                        color: Colors.purple,
                        onTap: () => _navigateToContentViewer('Photos', _privatePhotos),
                        onAdd: _addPrivatePhoto,
                      ),
                      _buildPrivateItem(
                        icon: Icons.video_library,
                        title: 'Private Videos',
                        subtitle: '${_privateVideos.length} videos',
                        color: Colors.blue,
                        onTap: () => _navigateToContentViewer('Videos', _privateVideos),
                        onAdd: _addPrivateVideo,
                      ),
                      _buildPrivateItem(
                        icon: Icons.description,
                        title: 'Documents',
                        subtitle: '${_privateDocuments.length} files',
                        color: Colors.orange,
                        onTap: () => _navigateToContentViewer('Documents', _privateDocuments),
                        onAdd: _addPrivateDocument,
                      ),
                      _buildPrivateItem(
                        icon: Icons.note,
                        title: 'Private Notes',
                        subtitle: '${_privateNotes.length} notes',
                        color: Colors.teal,
                        onTap: () => _navigateToContentViewer('Notes', _privateNotes),
                        onAdd: _addPrivateNote,
                      ),
                    ],
                  ),
                ),
                
                // Bottom section
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.white.withOpacity(0.7),
                        size: 20,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Files are copied to private storage. Even if deleted from original location, they remain here safely.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrivateItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    required VoidCallback onAdd,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
          ),
        ),
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.all(15),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 24,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: onAdd,
                child: Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.add,
                    color: color,
                    size: 16,
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

// Content Viewer Screen
class PrivateContentViewer extends StatelessWidget {
  final String contentType;
  final List<String> items;
  final Function(int) onDelete;

  PrivateContentViewer({
    required this.contentType,
    required this.items,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        title: Text(
          'Private $contentType',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: items.isEmpty
          ? Center(
              child: Text(
                'No $contentType added yet',
                style: TextStyle(color: Colors.white54, fontSize: 16),
              ),
            )
          : GridView.builder(
              padding: EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    // Open full screen viewer
                    _showFullScreenViewer(context, items[index], contentType);
                  },
                  onLongPress: () {
                    // Show delete confirmation
                    _showDeleteConfirmation(context, index);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _buildContentPreview(items[index], contentType),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildContentPreview(String filePath, String type) {
    switch (type) {
      case 'Photos':
        return Image.file(
          File(filePath),
          fit: BoxFit.cover,
        );
      case 'Videos':
        return Container(
          color: Colors.black54,
          child: Center(
            child: Icon(
              Icons.play_circle_filled,
              color: Colors.white,
              size: 50,
            ),
          ),
        );
      case 'Documents':
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.description,
                color: Colors.orange,
                size: 40,
              ),
              SizedBox(height: 8),
              Text(
                path.basename(filePath),
                style: TextStyle(color: Colors.white, fontSize: 12),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      case 'Notes':
        return FutureBuilder<String>(
          future: File(filePath).readAsString(),
          builder: (context, snapshot) {
            return Container(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.note,
                    color: Colors.teal,
                    size: 30,
                  ),
                  SizedBox(height: 8),
                  Expanded(
                    child: Text(
                      snapshot.data ?? 'Loading...',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      default:
        return Container();
    }
  }

  void _showFullScreenViewer(BuildContext context, String filePath, String type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenViewer(filePath: filePath, type: type),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text('Delete Item', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete this item permanently?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              onDelete(index);
              Navigator.pop(context);
              Navigator.pop(context); // Go back to refresh the list
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// Full Screen Viewer
class FullScreenViewer extends StatelessWidget {
  final String filePath;
  final String type;

  FullScreenViewer({required this.filePath, required this.type});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: _buildFullScreenContent(),
      ),
    );
  }

  Widget _buildFullScreenContent() {
    switch (type) {
      case 'Photos':
        return InteractiveViewer(
          child: Image.file(File(filePath)),
        );
      case 'Notes':
        return FutureBuilder<String>(
          future: File(filePath).readAsString(),
          builder: (context, snapshot) {
            return SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Text(
                snapshot.data ?? 'Loading...',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            );
          },
        );
      default:
        return Container(
          child: Text(
            'Preview not available',
            style: TextStyle(color: Colors.white),
          ),
        );
    }
  }
}