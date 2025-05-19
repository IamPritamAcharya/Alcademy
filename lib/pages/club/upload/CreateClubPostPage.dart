import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Initialize Supabase
final supabase = Supabase.instance.client;

// Imgur Client ID (Replace if needed)
const String imgurClientId = "bc914a8e52af6ef";

// Constants for shared preferences keys
const String PREFIX_BANNER_CHANGES = "banner_changes_";
const String PREFIX_LOGO_CHANGES = "logo_changes_";
const int MAX_CHANGES_PER_DAY = 3;

class CreateClubPostPage extends StatefulWidget {
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

  @override
  void initState() {
    super.initState();
    _loadUserClubData();
  }

  // Load club data for the current user
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
      // Fetch club data from Supabase
      final response = await supabase
          .from('clubs')
          .select('id, name, banner_url, logo_url')
          .eq('id', allowedClubId)
          .single();

      if (response != null) {
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
    } else {
      setState(() {
        isClubDataLoading = false;
      });
    }
  }

  // Function to pick multiple images for posts
  Future<void> pickImages() async {
    final pickedFiles = await ImagePicker().pickMultiImage();

    if (pickedFiles.isNotEmpty) {
      if (pickedFiles.length > 6) {
        // Show alert if more than 6 images are selected
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

  // Function to pick a single image (for logo or banner)
  Future<File?> pickSingleImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    return null;
  }

  // Function to check if user has reached rate limit for changing logo or banner
  Future<bool> canChangeImage(String type) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final user = supabase.auth.currentUser;
    if (user == null) return false;

    String userId = user.id;
    String prefix =
        type == 'banner' ? PREFIX_BANNER_CHANGES : PREFIX_LOGO_CHANGES;
    String key = prefix + userId;

    // Get today's date in yyyyMMdd format
    String today =
        DateTime.now().toString().substring(0, 10).replaceAll('-', '');
    String prefKey = key + "_" + today;

    // Get the number of changes made today
    int changes = prefs.getInt(prefKey) ?? 0;

    return changes < MAX_CHANGES_PER_DAY;
  }

  // Function to increment the count of changes
  Future<void> incrementChangeCount(String type) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final user = supabase.auth.currentUser;
    if (user == null) return;

    String userId = user.id;
    String prefix =
        type == 'banner' ? PREFIX_BANNER_CHANGES : PREFIX_LOGO_CHANGES;
    String key = prefix + userId;

    // Get today's date in yyyyMMdd format
    String today =
        DateTime.now().toString().substring(0, 10).replaceAll('-', '');
    String prefKey = key + "_" + today;

    // Get current count and increment it
    int changes = prefs.getInt(prefKey) ?? 0;
    await prefs.setInt(prefKey, changes + 1);
  }

  // Function to upload an image to Imgur and get URL
  Future<String?> uploadImageToImgur(File image) async {
    final uri = Uri.parse("https://api.imgur.com/3/upload");
    var request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Client-ID $imgurClientId'
      ..files.add(await http.MultipartFile.fromPath('image', image.path));

    var response = await request.send();
    if (response.statusCode == 200) {
      var responseData = jsonDecode(await response.stream.bytesToString());
      return responseData['data']['link'];
    } else {
      print("Failed to upload image: ${response.reasonPhrase}");
      return null;
    }
  }

  // Function to upload multiple images to Imgur and get URLs (for posts)
  Future<List<String>> uploadImagesToImgur() async {
    List<String> imageUrls = [];

    for (File image in _images) {
      String? url = await uploadImageToImgur(image);
      if (url != null) {
        imageUrls.add(url);
      }
    }

    return imageUrls;
  }

  // Function to change club banner
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

    String? imageUrl = await uploadImageToImgur(image);
    if (imageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to upload banner image")),
      );
      setState(() {
        isLoading = false;
      });
      return;
    }

    // Update the banner URL in the database - Fixed to properly handle response
    try {
      await supabase
          .from('clubs')
          .update({'banner_url': imageUrl}).eq('id', _clubId!);

      // If no error is thrown, the update was successful
      await incrementChangeCount('banner');
      setState(() {
        _bannerUrl = imageUrl;
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Club banner updated successfully")),
      );
    } catch (error) {
      print("Error updating banner: $error");
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Failed to update club banner: ${error.toString()}")),
      );
    }
  }

// Function to change club logo - Fixed version
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

    String? imageUrl = await uploadImageToImgur(image);
    if (imageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to upload logo image")),
      );
      setState(() {
        isLoading = false;
      });
      return;
    }

    // Update the logo URL in the database - Fixed to properly handle response
    try {
      await supabase
          .from('clubs')
          .update({'logo_url': imageUrl}).eq('id', _clubId!);

      // If no error is thrown, the update was successful
      await incrementChangeCount('logo');
      setState(() {
        _logoUrl = imageUrl;
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Club logo updated successfully")),
      );
    } catch (error) {
      print("Error updating logo: $error");
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Failed to update club logo: ${error.toString()}")),
      );
    }
  }

  // Fetch allowed club ID from GitHub API
  Future<String?> fetchUserClubId(String userId) async {
    final response = await http.get(Uri.parse(
        'https://raw.githubusercontent.com/Academia-IGIT/DATA_hub/main/allowed.json'));

    if (response.statusCode == 200) {
      List<dynamic> jsonData = jsonDecode(response.body);

      for (var entry in jsonData) {
        if (entry['user_id'] == userId) {
          return entry['club_id']; // Return the allowed club ID
        }
      }
    }
    return null; // User not found or unauthorized
  }

  // Function to create a club post (existing functionality)
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

    // Get logged-in user ID
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

    // Fetch user's allowed club ID if not already loaded
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

    // Upload images to Imgur
    List<String> imageUrls = await uploadImagesToImgur();
    if (imageUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Image upload failed")),
      );
      setState(() {
        isLoading = false;
      });
      return;
    }

    // Insert post into Supabase for the assigned club only
    final response = await supabase.from('club_posts').insert({
      'club_id': _clubId,
      'user_id': userId,
      'title': titleController.text,
      'body': bodyController.text,
      'images': imageUrls,
      'created_at': DateTime.now().toIso8601String(),
    }).select();

    if (response != null && response.isNotEmpty) {
      print("Post Created Successfully: $response");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Post uploaded successfully!")),
      );
      titleController.clear();
      bodyController.clear();
      setState(() {
        _images = [];
      });
    } else {
      print("Post creation failed.");
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
                  backgroundColor: Colors.transparent,
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
                          // Club Management Section
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
                                      // Club Logo
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
                                              "You can change the club's logo and banner up to $MAX_CHANGES_PER_DAY times per day.",
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
                                child: Text("Pick Images",
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
