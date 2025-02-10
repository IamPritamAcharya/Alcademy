import 'dart:io';
import 'dart:math';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:port/ai_chatbot/another/chat.dart';
import 'package:port/pages/expense/expense.dart';
import 'package:port/onboarding/user_data.dart';
import 'package:port/pages/user/userinfo.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/refresh_tracker.dart';
import '../widgets/custom_snackbar.dart';
import '../widgets/tabs_widget.dart';
import 'page_navigator_dropdown.dart';
import 'shimmer_grid.dart';
import 'subject_service.dart';
import 'subject_model.dart';
import 'subject_details_page.dart';
import 'subject_grid_view.dart';
import 'utils.dart'; // Import the new widget

class FirstPage extends StatefulWidget {
  @override
  _FirstPageState createState() => _FirstPageState();
}

class _FirstPageState extends State<FirstPage> {
  final SubjectService subjectService = SubjectService('');
  List<Subject> subjects = [];
  bool isLoading = true;
  String? errorMessage;
  String currentSentence =
      getRandomSentence(); // Initialize with a random sentence

  final ValueNotifier<String?> profileImagePathNotifier = ValueNotifier(null);

  // List of colors to choose from for the gradient
  final List<Color> gradientColors = [
    Colors.blueGrey, // Subtle blue-grey
    Colors.deepPurple, // Deep purple (darker shade)
    Colors.green, // Soft green
    Colors.orange, // Soft orange
    Colors.pinkAccent, // Light pink accent
    Colors.cyan, // Cyan
    Colors.teal, // Teal
    Colors.indigo, // Indigo
  ];

  // Store the random color here
  late Color randomColor;

  @override
  void initState() {
    super.initState();
    randomColor =
        _getRandomColor(); // Generate the color once when the page is first loaded
    _fetchSelectedYearAndSubjects();
    _loadProfileImagePath();
  }

  @override
  void dispose() {
    profileImagePathNotifier.dispose();
    super.dispose();
  }

  // Function to generate a random color from the list
  Color _getRandomColor() {
    final random = Random();
    return gradientColors[random.nextInt(gradientColors.length)];
  }

  Future<void> _fetchSelectedYearAndSubjects() async {
    final prefs = await SharedPreferences.getInstance();
    final selectedYearUrl = prefs.getString('selectedYearUrl') ??
        'https://raw.githubusercontent.com/Academia-IGIT/DATA_hub/main/firstyear.json'; // Default URL

    subjectService.url = selectedYearUrl;

    // Update the random sentence only once during refresh
    setState(() {
      currentSentence = getRandomSentence();
    });
    _fetchSubjects();
  }

  Future<void> _fetchSubjects() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
      final fetchedSubjects = await subjectService.fetchSubjects();
      setState(() {
        subjects = fetchedSubjects;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load subjects. Please try again.';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _navigateToSubjectDetails(
      BuildContext context, Subject subject) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SubjectDetailsPage(subject: subject),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 50),
          const SizedBox(height: 10),
          Text(
            errorMessage ?? 'Something went wrong.',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _fetchSelectedYearAndSubjects,
            child: Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white12,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadProfileImagePath() async {
    final prefs = await SharedPreferences.getInstance();
    final savedImagePath = prefs.getString('profile_image_path');
    profileImagePathNotifier.value = savedImagePath;
  }

  Future<void> _updateProfileImagePath(String newPath) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_image_path', newPath);
    profileImagePathNotifier.value = newPath;
  }

  Widget _buildProfileImage() {
    return ValueListenableBuilder<String?>(
      valueListenable: profileImagePathNotifier,
      builder: (context, profileImagePath, child) {
        if (profileImagePath == null || profileImagePath.isEmpty) {
          return Hero(
            tag: 'profileImageHero', // Consistent Hero tag
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Colors.white24, Colors.white10],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.person_outline_rounded,
                  color: Colors.white,
                  size: 48, // Adjusted size to better fit the space
                ),
              ),
            ),
          );
        } else {
          final profileImageFile = File(profileImagePath);
          if (profileImageFile.existsSync()) {
            return Hero(
              tag: 'profileImageHero',
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: Image.file(
                    profileImageFile,
                    fit: BoxFit.cover,
                    width: double.infinity, // Fill the parent container
                    height: double.infinity, // Fill the parent container
                  ),
                ),
              ),
            );
          } else {
            return Hero(
              tag: 'profileImageHero',
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red.shade400,
                ),
                child: const Center(
                  child: Icon(
                    Icons.error,
                    color: Colors.white,
                    size: 48, // Adjusted size for visibility
                  ),
                ),
              ),
            );
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        color: Colors.white,
        backgroundColor: const Color(0xFF1A1D1E),
        onRefresh: () async {
          bool isRefreshAllowed = await RefreshTracker.incrementRefreshCount();
          if (!isRefreshAllowed) {
            // Show cooldown snack bar
            ScaffoldMessenger.of(context).showSnackBar(
              CustomSnackBar.build(
                isCooldown: true,
                context: context,
              ),
            );
            return;
          }

          // Update the random color and refresh data
          setState(() {
            randomColor =
                _getRandomColor(); // Update the random color on refresh
          });
          await _fetchSelectedYearAndSubjects();
        },
        child: Container(
          color:
              const Color(0xFF1A1D1E), // Background color for the entire screen
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent:
                  AlwaysScrollableScrollPhysics(), // Combine bounce and always-scrollable
            ),
            slivers: [
              _buildHeader(context),
              if (isLoading)
                const ShimmerGrid()
              else if (errorMessage != null)
                SliverToBoxAdapter(
                  child: _buildErrorState(),
                )
              else if (subjects.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                  sliver: SubjectGridView(
                    subjects: subjects,
                    onSubjectTap: _navigateToSubjectDetails,
                  ),
                )
              else
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      "No subjects found.",
                      style: TextStyle(
                        fontFamily: 'ProductSans',
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 90),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      expandedHeight: 441,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Stack(
          clipBehavior: Clip.none,
          children: [
            // Background gradient
            Positioned.fill(
              child: AnimatedContainer(
                duration: const Duration(seconds: 1),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      randomColor.withOpacity(0.95),
                      randomColor.withOpacity(0.7),
                      const Color(0xFF1A1D1E),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            ExtendedAppBarWithSlidingEffect(
              themeColor: randomColor,
            ),
            // Floating content
            Positioned.fill(
              top: 125,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UserProfilePage(),
                        ),
                      ).then((_) => _loadProfileImagePath());
                    },
                    child: Container(
                      width: 104, // Matches `CircleAvatar` radius (52 * 2)
                      height: 104,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.5),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: _buildProfileImage(),
                      ), // Updated function ensures it fills the area
                    ),
                  ),

                  const SizedBox(height: 20),
                  // Greeting Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        FutureBuilder<String>(
                          future: _getFormattedUserName(),
                          builder: (context, snapshot) {
                            return AutoSizeText(
                              "Hello, ${snapshot.data} 👋",
                              maxLines: 1,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'ProductSans',
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w600,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 6),
                        AutoSizeText(
                          currentSentence,
                          maxLines: 1,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'ProductSans',
                            color: Colors.white70,
                            fontSize: 16,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),
                  // Search Bar Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: GestureDetector(
                      onTap: () async {
                        final userQuery = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AiChatPage(initialQuery: ""),
                          ),
                        );
                        if (userQuery != null && userQuery.isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  AiChatPage(initialQuery: userQuery),
                            ),
                          );
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 20),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.search,
                              color: Colors.white70,
                              size: 22,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              "Ask Gemini AI...",
                              style: const TextStyle(
                                fontFamily: 'ProductSans',
                                color: Colors.white54,
                                fontSize: 16,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  // Tabs Section
                  TabsWidget(
                    onTabPressed: (tabName) {
                      print("Tab pressed: $tabName");
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Method to fetch user name for greeting
  Future<String> _getFormattedUserName() async {
    final userName = await UserData.getUserName();
    if (userName == null || userName.isEmpty) {
      return 'User'; // Default if no username is available
    }
    final firstName = userName.split(' ').first; // Extract first name
    return firstName;
  }

  // Method to launch a URL
  void _launchURL(String url) async {
    Uri uri = Uri.parse(url);
    if (await canLaunch(uri.toString())) {
      await launch(uri.toString());
    } else {
      throw 'Could not launch $url';
    }
  }
}
