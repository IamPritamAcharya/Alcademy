import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

final supabase = Supabase.instance.client;

const String PREFIX_BANNER_CHANGES = "banner_changes_";
const String PREFIX_LOGO_CHANGES = "logo_changes_";
const int MAX_CHANGES_PER_DAY = 3;

class CreateClubPostPage extends StatefulWidget {
  const CreateClubPostPage({super.key});

  @override
  _CreateClubPostPageState createState() => _CreateClubPostPageState();
}

class _CreateClubPostPageState extends State<CreateClubPostPage> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController bodyController = TextEditingController();
  List<File> _images = [];
  String? _clubId;
  String? _clubName;
  String? _bannerUrl;
  String? _logoUrl;
  bool isLoading = false;
  bool isClubDataLoading = true;
  bool compressImages = true;

  @override
  void initState() {
    super.initState();
    _loadUserClubData();
  }

  @override
  void dispose() {
    titleController.dispose();
    bodyController.dispose();
    super.dispose();
  }

  Future<void> _loadUserClubData() async {
    setState(() {
      isClubDataLoading = true;
    });

    final user = supabase.auth.currentUser;
    if (user == null) {
      setState(() {
        isClubDataLoading = false;
      });
      return;
    }

    String userId = user.id;
    String? allowedClubId = await fetchUserClubId(userId);

    if (allowedClubId != null) {
      final response = await supabase
          .from('clubs')
          .select('id, name, banner_url, logo_url')
          .eq('id', allowedClubId)
          .single();

      setState(() {
        _clubId = response['id'];
        _clubName = response['name'];
        _bannerUrl = response['banner_url'];
        _logoUrl = response['logo_url'];
        isClubDataLoading = false;
      });
        } else {
      setState(() {
        isClubDataLoading = false;
      });
    }
  }

  Future<File?> compressImage(File file) async {
    if (!compressImages) return file;

    try {
      final dir = await getTemporaryDirectory();
      final targetPath = path.join(dir.absolute.path,
          "${DateTime.now().millisecondsSinceEpoch}_compressed.jpg");

      // Try to compress the image with better error handling
      final XFile? compressedFile =
          await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 85,
        minWidth: 800,
        minHeight: 800,
        format: CompressFormat.jpeg,
        keepExif: false,
      );

      if (compressedFile != null) {
        final originalSize = await file.length();
        final compressedSize = await File(compressedFile.path).length();
        debugPrint(
            "Image compressed from ${originalSize / (1024 * 1024)} MB to ${compressedSize / (1024 * 1024)} MB");
        return File(compressedFile.path);
      }
      return file;
    } catch (e) {
      debugPrint("Compression failed: $e");
      // If compression fails, still return the original file
      return file;
    }
  }

  Future<void> pickImages() async {
    final pickedFiles = await ImagePicker().pickMultiImage();

    if (pickedFiles.isNotEmpty) {
      if (pickedFiles.length > 6) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("You can only select up to 6 images!")),
        );
      } else {
        setState(() {
          _images = pickedFiles.map((file) => File(file.path)).toList();
        });
      }
    }
  }

  Future<File?> pickSingleImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    return null;
  }

  Future<bool> canChangeImage(String type) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final user = supabase.auth.currentUser;
    if (user == null) return false;

    String userId = user.id;
    String prefix =
        type == 'banner' ? PREFIX_BANNER_CHANGES : PREFIX_LOGO_CHANGES;
    String key = prefix + userId;

    String today =
        DateTime.now().toString().substring(0, 10).replaceAll('-', '');
    String prefKey = "${key}_$today";

    int changes = prefs.getInt(prefKey) ?? 0;

    return changes < MAX_CHANGES_PER_DAY;
  }

  Future<void> incrementChangeCount(String type) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final user = supabase.auth.currentUser;
    if (user == null) return;

    String userId = user.id;
    String prefix =
        type == 'banner' ? PREFIX_BANNER_CHANGES : PREFIX_LOGO_CHANGES;
    String key = prefix + userId;

    String today =
        DateTime.now().toString().substring(0, 10).replaceAll('-', '');
    String prefKey = key + "_" + today;

    int changes = prefs.getInt(prefKey) ?? 0;
    await prefs.setInt(prefKey, changes + 1);
  }

  Future<String?> uploadImageToSupabase(File image,
      {String folder = 'posts'}) async {
    try {
      // Check if file exists and is readable
      if (!await image.exists()) {
        debugPrint("Error: Image file does not exist at path: ${image.path}");
        return null;
      }

      // Compress image if option is enabled
      File? processedImage = await compressImage(image);
      if (processedImage == null) {
        debugPrint("Error: Image compression failed");
        return null;
      }

      // Check file size (3MB limit for Supabase bucket)
      final fileSize = await processedImage.length();
      debugPrint("Image file size: ${fileSize / (1024 * 1024)} MB");

      if (fileSize > 3 * 1024 * 1024) {
        // 3MB limit
        debugPrint(
            "Error: Image file too large (${fileSize / (1024 * 1024)} MB). Bucket limit is 3MB.");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    "Image too large! Please compress or choose a smaller image (max 3MB)")),
          );
        }
        return null;
      }

      String fileExtension = path.extension(processedImage.path).toLowerCase();
      List<String> allowedExtensions = ['.jpg', '.jpeg', '.png', '.webp'];

      if (!allowedExtensions.contains(fileExtension)) {
        debugPrint(
            "Error: Invalid file type. Only JPEG, PNG, and WebP are allowed.");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    "Invalid file type! Only JPEG, PNG, and WebP are allowed.")),
          );
        }
        return null;
      }

      final user = supabase.auth.currentUser;
      if (user == null) {
        debugPrint("Error: User not authenticated");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Authentication required for upload")),
          );
        }
        return null;
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final sanitizedUserId = user.id.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
      final fileName = '${timestamp}_$sanitizedUserId$fileExtension';
      final filePath = '$folder/$fileName';

      debugPrint("Uploading to Supabase Storage: $filePath");

      try {
        final response = await supabase.storage
            .from('club-posts')
            .uploadBinary(filePath, await processedImage.readAsBytes(),
                fileOptions: FileOptions(
                  cacheControl: '3600',
                  upsert: false,
                  contentType: _getContentType(fileExtension),
                ));

        debugPrint("Upload response: $response");

        final publicUrl =
            supabase.storage.from('club-posts').getPublicUrl(filePath);

        debugPrint("Image uploaded successfully: $publicUrl");

        if (compressImages && processedImage.path != image.path) {
          try {
            await processedImage.delete();
          } catch (e) {
            debugPrint("Warning: Failed to cleanup compressed image: $e");
          }
        }

        return publicUrl;
      } on StorageException catch (e) {
        debugPrint("Storage exception: ${e.message}");

        if (e.message.contains('row-level security policy')) {
          debugPrint("Attempting alternative upload method due to RLS policy...");

          try {

            final publicUrl =
                supabase.storage.from('club-posts').getPublicUrl(filePath);

            debugPrint("Alternative upload successful: $publicUrl");
            return publicUrl;
          } catch (altError) {
            debugPrint("Alternative upload also failed: $altError");
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    "Upload failed: ${e.message}. Check your permissions in Supabase.")),
          );
        }
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint("Exception during image upload: $e");
      debugPrint("Stack trace: $stackTrace");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to upload image: ${e.toString()}")),
        );
      }
      return null;
    }
  }

  String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  Future<List<String>> uploadImagesToSupabase() async {
    List<String> imageUrls = [];
    List<String> failedUploads = [];

    for (int i = 0; i < _images.length; i++) {
      File image = _images[i];
      String? url = await uploadImageToSupabase(image, folder: 'posts');
      if (url != null) {
        imageUrls.add(url);
      } else {
        failedUploads.add("Image ${i + 1}");
        debugPrint("Failed to upload image ${i + 1}");
      }
    }

    if (failedUploads.isNotEmpty && imageUrls.isNotEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                "Warning: ${failedUploads.length} image(s) failed to upload. Proceeding with ${imageUrls.length} successful uploads."),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }

    return imageUrls;
  }

  Future<void> changeClubBanner() async {
    if (_clubId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("You don't have permission to manage any club")),
      );
      return;
    }

    bool canChange = await canChangeImage('banner');
    if (!canChange) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                "You've reached the limit of $MAX_CHANGES_PER_DAY banner changes per day")),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    File? image = await pickSingleImage();
    if (image == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    String? imageUrl = await uploadImageToSupabase(image, folder: 'banners');
    if (imageUrl == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      await supabase
          .from('clubs')
          .update({'banner_url': imageUrl}).eq('id', _clubId!);

      await incrementChangeCount('banner');
      setState(() {
        _bannerUrl = imageUrl;
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Club banner updated successfully")),
      );
    } catch (error) {
      debugPrint("Error updating banner: $error");
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Failed to update club banner: ${error.toString()}")),
      );
    }
  }

  Future<void> changeClubLogo() async {
    if (_clubId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("You don't have permission to manage any club")),
      );
      return;
    }

    bool canChange = await canChangeImage('logo');
    if (!canChange) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                "You've reached the limit of $MAX_CHANGES_PER_DAY logo changes per day")),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    File? image = await pickSingleImage();
    if (image == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    String? imageUrl = await uploadImageToSupabase(image, folder: 'logos');
    if (imageUrl == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      await supabase
          .from('clubs')
          .update({'logo_url': imageUrl}).eq('id', _clubId!);

      await incrementChangeCount('logo');
      setState(() {
        _logoUrl = imageUrl;
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Club logo updated successfully")),
      );
    } catch (error) {
      debugPrint("Error updating logo: $error");
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Failed to update club logo: ${error.toString()}")),
      );
    }
  }

  Future<String?> fetchUserClubId(String userId) async {
    final response = await http.get(Uri.parse(
        'https://raw.githubusercontent.com/Academia-IGIT/DATA_hub/main/allowed.json'));

    if (response.statusCode == 200) {
      List<dynamic> jsonData = jsonDecode(response.body);

      for (var entry in jsonData) {
        if (entry['user_id'] == userId) {
          return entry['club_id'];
        }
      }
    }
    return null;
  }

  Future<void> createPost() async {
    if (titleController.text.isEmpty || _images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Title and at least one image are required")),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    final user = supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("You need to be logged in to post")),
      );
      setState(() {
        isLoading = false;
      });
      return;
    }

    String userId = user.id;

    if (_clubId == null) {
      _clubId = await fetchUserClubId(userId);
      if (_clubId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("You are not authorized to post in any club")),
        );
        setState(() {
          isLoading = false;
        });
        return;
      }
    }

    List<String> imageUrls = await uploadImagesToSupabase();
    if (imageUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Image upload failed")),
      );
      setState(() {
        isLoading = false;
      });
      return;
    }

    final response = await supabase.from('club_posts').insert({
      'club_id': _clubId,
      'user_id': userId,
      'title': titleController.text,
      'body': bodyController.text,
      'images': imageUrls,
      'created_at': DateTime.now().toIso8601String(),
    }).select();

    if (response.isNotEmpty) {
      debugPrint("Post Created Successfully: $response");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Post uploaded successfully!")),
      );
      titleController.clear();
      bodyController.clear();
      setState(() {
        _images = [];
      });
    } else {
      debugPrint("Post creation failed.");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to create post")),
      );
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1D1E),
      resizeToAvoidBottomInset: false,
      body: isClubDataLoading
          ? Center(child: CircularProgressIndicator(color: Colors.white))
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 200,
                  floating: false,
                  pinned: true,
                  elevation: 0,
                  iconTheme: IconThemeData(color: Colors.white),
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(
                      _clubName != null
                          ? "Club: $_clubName"
                          : "Create Club Post",
                      style: TextStyle(
                          fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        _bannerUrl != null
                            ? Image.network(
                                _bannerUrl!,
                                fit: BoxFit.cover,
                              )
                            : Image.network(
                                "https://static1.anpoimages.com/wordpress/wp-content/uploads/2020/12/15/Google-Pay-GPay-dark-mode4.jpg",
                                fit: BoxFit.cover,
                              ),
                      ],
                    ),
                  ),
                  backgroundColor: Color(0xFF1A1D1E),
                  centerTitle: true,
                  bottom: const PreferredSize(
                    preferredSize: Size.fromHeight(1),
                    child: Divider(height: 1, color: Colors.white24),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_clubId != null)
                          Card(
                            color: Colors.white.withOpacity(0.1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 0.8),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Club Management",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Column(
                                        children: [
                                          Container(
                                            width: 80,
                                            height: 80,
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.white.withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              border: Border.all(
                                                color: Colors.white
                                                    .withOpacity(0.2),
                                                width: 0.8,
                                              ),
                                            ),
                                            child: _logoUrl != null
                                                ? ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            14),
                                                    child: Image.network(
                                                      _logoUrl!,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  )
                                                : Icon(
                                                    Icons.image,
                                                    color: Colors.white,
                                                    size: 40,
                                                  ),
                                          ),
                                          SizedBox(height: 8),
                                          ElevatedButton(
                                            onPressed: changeClubLogo,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.white,
                                              foregroundColor: Colors.black,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                              ),
                                              padding: EdgeInsets.symmetric(
                                                vertical: 8,
                                                horizontal: 16,
                                              ),
                                              elevation: 2,
                                            ),
                                            child: Text(
                                              "Change Logo",
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Rate Limit Info:",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            SizedBox(height: 8),
                                            Text(
                                              "You can change the club's logo and banner up to $MAX_CHANGES_PER_DAY times per day. Max file size: 3MB",
                                              style: TextStyle(
                                                color: Colors.white70,
                                                fontSize: 12,
                                              ),
                                            ),
                                            SizedBox(height: 8),
                                            ElevatedButton(
                                              onPressed: changeClubBanner,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.white,
                                                foregroundColor: Colors.black,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(14),
                                                ),
                                                padding: EdgeInsets.symmetric(
                                                  vertical: 8,
                                                  horizontal: 16,
                                                ),
                                                elevation: 2,
                                              ),
                                              child: Text(
                                                "Change Banner",
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        SizedBox(height: 20),
                        Text(
                          "Create New Post",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 0.8),
                          ),
                          child: TextField(
                            controller: titleController,
                            style: TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: "Title",
                              labelStyle:
                                  TextStyle(color: Colors.grey.shade400),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 14),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 0.8),
                          ),
                          child: TextField(
                            controller: bodyController,
                            style: TextStyle(color: Colors.white),
                            maxLines: 4,
                            decoration: InputDecoration(
                              labelText: "Body",
                              labelStyle:
                                  TextStyle(color: Colors.grey.shade400),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 14),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 0.8),
                          ),
                          child: CheckboxListTile(
                            title: Text(
                              "Compress images (recommended)",
                              style: TextStyle(color: Colors.white),
                            ),
                            subtitle: Text(
                              "Reduces file size and improves upload speed",
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 12),
                            ),
                            value: compressImages,
                            onChanged: (bool? value) {
                              setState(() {
                                compressImages = value ?? true;
                              });
                            },
                            activeColor: Colors.white,
                            checkColor: Colors.black,
                            tileColor: Colors.transparent,
                          ),
                        ),
                        SizedBox(height: 12),
                        _images.isNotEmpty
                            ? Wrap(
                                spacing: 10,
                                children: _images
                                    .map((img) => Container(
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(14),
                                            border: Border.all(
                                                color: Colors.white
                                                    .withOpacity(0.2),
                                                width: 0.8),
                                          ),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(14),
                                            child: Image.file(img,
                                                height: 100,
                                                width: 100,
                                                fit: BoxFit.cover),
                                          ),
                                        ))
                                    .toList(),
                              )
                            : Center(
                                child: Text("No images selected",
                                    style: TextStyle(color: Colors.white70)),
                              ),
                        SizedBox(height: 20),
                        Center(
                          child: Column(
                            children: [
                              ElevatedButton(
                                onPressed: pickImages,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14)),
                                  padding: EdgeInsets.symmetric(
                                      vertical: 14, horizontal: 32),
                                  elevation: 2,
                                ),
                                child: Text("Pick Images (Max 3MB each)",
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600)),
                              ),
                              SizedBox(height: 12),
                              isLoading
                                  ? Center(
                                      child: CircularProgressIndicator(
                                          color: Colors.white))
                                  : ElevatedButton(
                                      onPressed: createPost,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: Colors.black,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(14)),
                                        padding: EdgeInsets.symmetric(
                                            vertical: 14, horizontal: 32),
                                        elevation: 2,
                                      ),
                                      child: Text("Upload Post",
                                          style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600)),
                                    ),
                            ],
                          ),
                        ),
                        SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
