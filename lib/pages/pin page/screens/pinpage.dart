import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:open_file/open_file.dart';
import 'glassmorphic_card.dart';

class PinPage extends StatefulWidget {
  @override
  _PinPageState createState() => _PinPageState();
}

class _PinPageState extends State<PinPage> {
  List<Map<String, String>> pinnedItems = [];
  bool isGridView = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    // Load pinned items
    final savedItems = prefs.getString('pinnedItems');
    if (savedItems != null) {
      setState(() {
        pinnedItems = (json.decode(savedItems) as List)
            .map((item) => Map<String, String>.from(item))
            .toList();
      });
    }

    // Load view mode
    final savedViewMode = prefs.getBool('isGridView');
    if (savedViewMode != null) {
      setState(() {
        isGridView = savedViewMode;
      });
    }
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();

    // Save pinned items
    await prefs.setString('pinnedItems', json.encode(pinnedItems));

    // Save view mode
    await prefs.setBool('isGridView', isGridView);
  }

  Future<void> _addFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      setState(() {
        pinnedItems.add({
          'type': 'file',
          'path': result.files.single.path!,
          'name': result.files.single.name,
        });
      });
      _savePreferences();
    }
  }

  Future<void> _addUrl() async {
    final TextEditingController urlController = TextEditingController();
    showDialog(
        context: context,
        builder: (context) => Dialog(
              backgroundColor:
                  Colors.transparent, // Make background transparent
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20), // Round the corners
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                      sigmaX: 5.0, sigmaY: 5.0), // Apply blur effect
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.black
                          .withOpacity(0.6), // Dark transparent background
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ], // Add a shadow effect for depth
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Enter URL',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: urlController,
                          decoration: InputDecoration(
                            hintText: 'https://example.com',
                            hintStyle: TextStyle(
                                color: Colors.white70), // Light hint text
                            border: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white30),
                                borderRadius: BorderRadius.circular(30)),
                            focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white),
                                borderRadius: BorderRadius.circular(30)),
                          ),
                          keyboardType: TextInputType.url,
                          style: const TextStyle(
                              color: Colors.white), // White text color
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                final url = urlController.text.trim();
                                if (Uri.tryParse(url)?.hasAbsolutePath ==
                                    true) {
                                  setState(() {
                                    pinnedItems.add({
                                      'type': 'url',
                                      'url': url,
                                      'name': url
                                    });
                                  });
                                  _savePreferences();
                                  Navigator.of(context).pop();
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Invalid URL')),
                                  );
                                }
                              },
                              child: const Text(
                                'Add',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ));
  }

  void _removeItem(int index) {
    setState(() {
      pinnedItems.removeAt(index);
    });
    _savePreferences();
  }

  void _reorderItems(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = pinnedItems.removeAt(oldIndex);
      pinnedItems.insert(newIndex, item);
    });
    _savePreferences();
  }

  void _openItem(Map<String, String> item) async {
    if (item['type'] == 'file' && item['path']?.isNotEmpty == true) {
      final result = await OpenFile.open(item['path']!);
      if (result.type != ResultType.done) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open file')),
        );
      }
    } else if (item['type'] == 'url' && item['url']?.isNotEmpty == true) {
      final url = item['url']!;
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open URL')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid item')),
      );
    }
  }

  bool _isImageFile(String path) {
    final extensions = ['jpg', 'jpeg', 'png', 'gif'];
    return extensions.any((ext) => path.toLowerCase().endsWith(ext));
  }

  Widget _buildGridView() {
    if (pinnedItems.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 30.0),
          child: Text(
            "Here you can add your own pinned items for quick access.",
            style:
                TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 0,
              ),
              itemCount: pinnedItems.length,
              itemBuilder: (context, index) {
                final item = pinnedItems[index];
                return GlassmorphicCard(
                  key: ValueKey(item),
                  onTap: () => _openItem(item),
                  child: Column(
                    children: [
                      Expanded(
                        flex: 2,
                        child: item['type'] == 'file' &&
                                _isImageFile(item['path'] ?? '')
                            ? ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12),
                                ),
                                child: Image.file(
                                  File(item['path']!),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                              )
                            : const Icon(
                                Icons.insert_drive_file,
                                color: Colors.white,
                                size: 48,
                              ),
                      ),
                      const Divider(color: Colors.white38, thickness: 1),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          item['name'] ?? '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            overflow: TextOverflow.ellipsis,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildListView() {
    if (pinnedItems.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 30.0),
          child: Text(
            "Here you can add your own pinned items for quick access.",
            style:
                TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Theme(
      data: Theme.of(context).copyWith(
        canvasColor: Colors.transparent,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: ReorderableListView.builder(
          onReorder: (int oldIndex, int newIndex) {
            // Adjust indexes to account for the top and bottom SizedBox
            final int adjustedOldIndex = oldIndex - 1;
            final int adjustedNewIndex = newIndex - 1;

            // Only reorder if there are more than one item and valid indexes
            if (pinnedItems.length > 1 &&
                adjustedOldIndex >= 0 &&
                adjustedNewIndex >= 0 &&
                adjustedNewIndex < pinnedItems.length) {
              setState(() {
                final item = pinnedItems.removeAt(adjustedOldIndex);
                pinnedItems.insert(adjustedNewIndex, item);
              });
              _savePreferences();
            }
          },
          itemCount: pinnedItems.length + 2, // Include the two SizedBox widgets
          itemBuilder: (context, index) {
            if (index == 0) {
              // Top spacer
              return const SizedBox(
                key: ValueKey("topSpacing"),
                height: 10,
              );
            } else if (index == pinnedItems.length + 1) {
              // Bottom spacer
              return const SizedBox(
                key: ValueKey("bottomSpacing"),
                height: 10,
              );
            }

            // Adjust index for pinnedItems
            final itemIndex = index - 1;
            final item = pinnedItems[itemIndex];
            return GlassmorphicCard(
              key: ValueKey(item),
              onTap: () => _openItem(item),
              child: ListTile(
                leading: const Icon(
                  Icons.insert_drive_file_outlined,
                  color: Colors.white,
                ),
                title: Text(
                  item['name'] ?? '',
                  style: const TextStyle(color: Colors.white),
                ),
                trailing: IconButton(
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.red,
                  ),
                  onPressed: () => _removeItem(itemIndex),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1D1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1D1E),
        title: const Text(
          'Pin Page',
          style: TextStyle(
            fontSize: 24,
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: 'ProductSans',
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(
                isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded),
            onPressed: () {
              setState(() {
                isGridView = !isGridView;
              });
              _savePreferences();
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.white.withOpacity(0.2),
            height: 1,
          ),
        ),
      ),
      body: isGridView ? _buildGridView() : _buildListView(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        onPressed: () => showModalBottomSheet(
          backgroundColor: const Color(0xFF1A1D1E),
          context: context,
          builder: (_) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 20), // Add some spacing at the top

              // Pin File Option
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20.0), // Center text and icon
                title: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center, // Center the Row content
                  children: [
                    const Icon(
                      Icons.insert_drive_file,
                      color: Colors.white,
                      size: 30, // Icon size
                    ),
                    const SizedBox(width: 10), // Space between icon and text
                    const Text(
                      'Pin File',
                      style: TextStyle(
                          color: Colors.white, fontSize: 16), // Text styling
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _addFile();
                },
              ),

              // Pin URL Option
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20.0), // Center text and icon
                title: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center, // Center the Row content
                  children: [
                    const Icon(
                      Icons.link,
                      color: Colors.white,
                      size: 30, // Icon size
                    ),
                    const SizedBox(width: 10), // Space between icon and text
                    const Text(
                      'Pin URL',
                      style: TextStyle(
                          color: Colors.white, fontSize: 16), // Text styling
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _addUrl();
                },
              ),

              const SizedBox(height: 20), // Add some spacing at the bottom
            ],
          ),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}
