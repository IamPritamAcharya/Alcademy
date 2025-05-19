import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:line_icons/line_icons.dart';
import 'package:port/ai_chatbot/another/chat.dart';
import 'package:port/pages/expense/expense.dart';
import 'package:port/onboarding/user_data.dart';

import 'package:port/pages/user/userinfo.dart';
import 'package:line_icons/line_icon.dart';
import 'package:port/test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/refresh_tracker.dart';
import '../widgets/custom_snackbar.dart';
import '../widgets/tabs_widget.dart';
import 'ExtendedAppBarWithSlidingEffect.dart';
import 'shimmer_grid.dart';
import 'subject_service.dart';
import 'subject_model.dart';
import 'subject_details_page.dart';
import 'subject_grid_view.dart';
import 'utils.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class FirstPage extends StatefulWidget {
  final GlobalKey<ScaffoldState>? scaffoldKey;

  const FirstPage({Key? key, this.scaffoldKey}) : super(key: key);

  @override
  _FirstPageState createState() => _FirstPageState();
}

class _FirstPageState extends State<FirstPage>
    with AutomaticKeepAliveClientMixin {
  // Keep state alive when navigating between tabs
  @override
  bool get wantKeepAlive => true;

  final SubjectService subjectService = SubjectService('');
  List<Subject> subjects = [];
  bool isLoading = true;
  String? errorMessage;
  late String currentSentence;

  // Cache user name to avoid repeated async calls
  String? _cachedUserName;

  // Use a separate notifier for profile image to avoid full rebuilds
  final ValueNotifier<String?> profileImagePathNotifier = ValueNotifier(null);

  // List of colors to choose from for the gradient - moved to static to avoid recreating
  static final List<Color> gradientColors = [
    Color(0xFFB0BEC5), // Light Blue-Grey
    Color(0xFFD1C4E9), // Soft Lavender Purple
    Color(0xFFA5D6A7), // Pastel Green
    Color(0xFFFFCC80), // Soft Orange
    Color(0xFFF8BBD0), // Light Pink
    Color(0xFF80DEEA), // Bright Cyan
    Color(0xFF80CBC4), // Light Teal
    Color(0xFF9FA8DA), // Soft Indigo
  ];

  // Store the random color here
  late Color randomColor;

  // Connectivity status
  ValueNotifier<bool> _isOnlineNotifier = ValueNotifier(true);
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    // Initialize values
    currentSentence = getRandomSentence();
    randomColor = _getRandomColor();

    // Schedule heavy operations for after frame render
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initConnectivity();
      _loadUserData();
      _fetchSelectedYearAndSubjects();
    });
  }

  @override
  void dispose() {
    profileImagePathNotifier.dispose();
    _isOnlineNotifier.dispose();
    _connectivitySubscription.cancel();
    super.dispose();
  }

  // Load user data in a separate method
  Future<void> _loadUserData() async {
    _cachedUserName = await UserData.getUserName();
    if (_cachedUserName == null || _cachedUserName!.isEmpty) {
      _cachedUserName = 'User';
    } else {
      _cachedUserName = _cachedUserName!.split(' ').first; // Extract first name
    }
    if (mounted) setState(() {});
  }

  Future<void> _initConnectivity() async {
    try {
      final results = await Connectivity().checkConnectivity();
      _updateConnectionStatus(results);

      // Set up subscription to connectivity changes
      _connectivitySubscription =
          Connectivity().onConnectivityChanged.listen(_updateConnectionStatus);
    } catch (e) {
      // If we can't check connectivity, assume we're offline
      _updateConnectionStatus([]); // Empty list means no connectivity
    }
  }

  // Update connection status - updated to handle List<ConnectivityResult>
  void _updateConnectionStatus(List<ConnectivityResult> results) {
    final isOnline = results.isNotEmpty &&
        results.any((result) => result != ConnectivityResult.none);

    // Only update if changed to avoid rebuilds
    if (_isOnlineNotifier.value != isOnline) {
      _isOnlineNotifier.value = isOnline;
    }
  }

  // Function to generate a random color from the list
  Color _getRandomColor() {
    final random = Random();
    return gradientColors[random.nextInt(gradientColors.length)];
  }

  // Memoized subject fetching to prevent redundant calls
  Future<void> _fetchSelectedYearAndSubjects() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final selectedYearUrl = prefs.getString('selectedYearUrl') ??
          'https://raw.githubusercontent.com/Academia-IGIT/DATA_hub/main/firstyear.json';

      subjectService.url = selectedYearUrl;

      // Fetch subjects in a separate isolate or compute function if possible
      final fetchedSubjects = await subjectService.fetchSubjects();

      if (!mounted) return;

      setState(() {
        subjects = fetchedSubjects;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = 'Failed to load subjects. Please try again.';
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

  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    return Scaffold(
      key: scaffoldKey,
      body: RefreshIndicator(
        color: Colors.white,
        backgroundColor: const Color(0xFF181818),
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

          // Update the random color and sentence
          setState(() {
            randomColor = _getRandomColor();
            currentSentence = getRandomSentence();
          });

          await _fetchSelectedYearAndSubjects();
        },
        child: Container(
          color: const Color(0xFF1A1D1E),
          child: _buildScrollView(),
        ),
      ),
    );
  }

  // Extract scroll view building for better organization
  Widget _buildScrollView() {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        _buildHeader(context, widget.scaffoldKey!),
        
        if (isLoading)
          const ShimmerGrid()
        else if (errorMessage != null)
          SliverToBoxAdapter(child: _buildErrorState())
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
    );
  }

  // Simplified to use cached username
  String _getFormattedUserName() {
    return _cachedUserName ?? 'User';
  }

  // Method to launch a URL
  Future<void> _launchURL(String url) async {
    Uri uri = Uri.parse(url);
    if (await canLaunch(uri.toString())) {
      await launch(uri.toString());
    } else {
      throw 'Could not launch $url';
    }
  }

  Widget _buildHeader(
      BuildContext context, GlobalKey<ScaffoldState> scaffoldKey) {
    return SliverAppBar(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(30),
        ),
      ),
      expandedHeight: 350,
      pinned: true,
      stretch: true,
      automaticallyImplyLeading: false,
      backgroundColor: randomColor,
      flexibleSpace: FlexibleSpaceBar(
        background: ClipRRect(
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(30),
          ),
          child: Stack(
            children: [
              // Gradient overlay with improved colors
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        randomColor.withOpacity(0.9),
                        HSLColor.fromColor(randomColor)
                            .withLightness(
                                HSLColor.fromColor(randomColor).lightness *
                                    0.65)
                            .toColor()
                            .withOpacity(0.95),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),

              // Content area
              Positioned.fill(
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Top row with Actions
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Year Selector Button
                            _buildActionButton(
                              icon: LineIcons.book,
                              onTap: () => context.push('/year'),
                            ),

                            // Menu Button
                            _buildActionButton(
                              icon: LineIcons.bars,
                              onTap: () =>
                                  scaffoldKey.currentState?.openDrawer(),
                            ),
                          ],
                        ),

                        // Centered Online Status Indicator with glass effect
                        ValueListenableBuilder<bool>(
                          valueListenable: _isOnlineNotifier,
                          builder: (context, isOnline, _) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(50),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: isOnline
                                          ? Colors.greenAccent
                                          : Colors.redAccent,
                                      borderRadius: BorderRadius.circular(5),
                                      boxShadow: [
                                        BoxShadow(
                                          color: (isOnline
                                                  ? Colors.greenAccent
                                                  : Colors.redAccent)
                                              .withOpacity(0.5),
                                          blurRadius: 6,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    isOnline ? "Online" : "Offline",
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.95),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 20),

                        // Centered User greeting - optimized to avoid FutureBuilder
                        Column(
                          children: [
                            AutoSizeText(
                              "Hey, ${_getFormattedUserName()}",
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Message container with glass effect
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: AutoSizeText(
                                currentSentence,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withOpacity(0.95),
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Empty space to prevent overflow
                        const Spacer(flex: 1),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(24),
        child: Column(
          children: [
            SizedBox(
              height: 70,
              child: TabsWidget(
                onTabPressed: (tabName) {
                  // Avoid print in production code - it's a performance drain
                },
              ),
            ),
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // Helper method to build action buttons
  Widget _buildActionButton(
      {required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }



    Widget _buildCardsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your cards',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22.0,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'ProductSans',
                ),
              ),
              GlassButton(
                onPressed: () {},
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14.0, vertical: 8.0),
                  child: Text(
                    '+ New card',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.0,
                      fontFamily: 'ProductSans',
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          SizedBox(
            height: 240.0,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildCard(),
                const SizedBox(width: 16.0),
                _buildCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard() {
    return GlassCard(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.pinkAccent.withOpacity(0.3),
            Colors.blueAccent.withOpacity(0.3),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SizedBox(
          width: 300.0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '\$2,986.12',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32.0,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'ProductSans',
                    ),
                  ),
                  Icon(LineIcons.creditCard, color: Colors.white70),
                ],
              ),
              Text(
                '**** 6543',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 20.0,
                  fontFamily: 'ProductSans',
                ),
              ),
              GlassButton(
                onPressed: () {},
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 10.0),
                  child: Text(
                    'Card details',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.0,
                      fontFamily: 'ProductSans',
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
}
