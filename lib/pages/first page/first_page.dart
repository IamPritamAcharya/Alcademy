import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:line_icons/line_icons.dart';
import 'package:port/onboarding/utils/user_data.dart';
import 'package:port/pages/first%20page/widgets/tabs_widget.dart';
import 'package:port/utils/config.dart';
import 'package:port/pages/stories/stories_widget.dart';

import 'package:port/pages/first%20page/ExpandableHeader.dart';
import 'package:port/pages/first%20page/first_page_background.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/refresh_tracker.dart';
import '../../utils/custom_snackbar.dart';

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
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;

  final SubjectService subjectService = SubjectService('');
  List<Subject> subjects = [];
  bool isLoading = true;
  String? errorMessage;
  late String currentSentence;
  String? _cachedUserName;

  late AnimationController _colorTransitionController;
  late Animation<double> _colorTransition;
  Map<String, dynamic>? _previousTheme;

  static final List<Map<String, dynamic>> creativeThemes = [
    {
      'primary': Color(0xFF667eea),
      'secondary': Color(0xFF764ba2),
      'accent': Color(0xFFf093fb),
      'background': Color(0xFF0a0a0a),
      'surface': Color(0xFF1a1a1a),
      'name': 'Cosmic'
    },
    {
      'primary': Color(0xFF4facfe),
      'secondary': Color(0xFF00f2fe),
      'accent': Color(0xFFa8edea),
      'background': Color(0xFF0a0a0a),
      'surface': Color(0xFF1a1a1a),
      'name': 'Ocean'
    },
    {
      'primary': Color(0xFFfa709a),
      'secondary': Color(0xFFfee140),
      'accent': Color(0xFFfccb90),
      'background': Color(0xFF0a0a0a),
      'surface': Color(0xFF1a1a1a),
      'name': 'Sunset'
    },
    {
      'primary': Color(0xFF43e97b),
      'secondary': Color(0xFF38f9d7),
      'accent': Color(0xFFffeaa7),
      'background': Color(0xFF0a0a0a),
      'surface': Color(0xFF1a1a1a),
      'name': 'Nature'
    },
    {
      'primary': Color(0xFFf76b1c),
      'secondary': Color(0xFFfad961),
      'accent': Color(0xFFa8e6cf),
      'background': Color(0xFF0a0a0a),
      'surface': Color(0xFF1a1a1a),
      'name': 'Aurora'
    },
  ];

  late Map<String, dynamic> currentTheme;
  ValueNotifier<bool> _isOnlineNotifier = ValueNotifier(true);
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    currentSentence = getRandomSentence();
    currentTheme = _getRandomTheme();
    _initAnimations();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initConnectivity();
      _loadUserData();
      _fetchSelectedYearAndSubjects();
    });
  }

  void _initAnimations() {
    _colorTransitionController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _colorTransition = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _colorTransitionController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _colorTransitionController.dispose();
    _isOnlineNotifier.dispose();
    _connectivitySubscription.cancel();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    _cachedUserName = await UserData.getUserName();
    if (_cachedUserName == null || _cachedUserName!.isEmpty) {
      _cachedUserName = 'User';
    } else {
      _cachedUserName = _cachedUserName!.split(' ').first;
    }
    if (mounted) setState(() {});
  }

  Future<void> _initConnectivity() async {
    try {
      final results = await Connectivity().checkConnectivity();
      _updateConnectionStatus(results);
      _connectivitySubscription =
          Connectivity().onConnectivityChanged.listen(_updateConnectionStatus);
    } catch (e) {
      _updateConnectionStatus([]);
    }
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    final isOnline = results.isNotEmpty &&
        results.any((result) => result != ConnectivityResult.none);
    if (_isOnlineNotifier.value != isOnline) {
      _isOnlineNotifier.value = isOnline;
    }
  }

  Map<String, dynamic> _getRandomTheme() {
    final random = Random();
    return creativeThemes[random.nextInt(creativeThemes.length)];
  }

  Color _interpolateColor(Color color1, Color color2, double t) {
    return Color.lerp(color1, color2, t) ?? color1;
  }

  Map<String, dynamic> _getInterpolatedTheme() {
    if (_previousTheme == null) return currentTheme;

    final t = _colorTransition.value;
    return {
      'primary': _interpolateColor(
          _previousTheme!['primary'], currentTheme['primary'], t),
      'secondary': _interpolateColor(
          _previousTheme!['secondary'], currentTheme['secondary'], t),
      'accent': _interpolateColor(
          _previousTheme!['accent'], currentTheme['accent'], t),
      'background': _interpolateColor(
          _previousTheme!['background'], currentTheme['background'], t),
      'surface': _interpolateColor(
          _previousTheme!['surface'], currentTheme['surface'], t),
      'name': t > 0.5 ? currentTheme['name'] : _previousTheme!['name'],
    };
  }

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadUserData();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return AnimatedBuilder(
      animation: _colorTransition,
      builder: (context, child) {
        final theme = _getInterpolatedTheme();

        return Scaffold(
          backgroundColor: theme['background'],
          body: RefreshIndicator(
            color: theme['primary'],
            backgroundColor: theme['surface'],
            onRefresh: () async {
              bool isRefreshAllowed =
                  await RefreshTracker.incrementRefreshCount();
              if (!isRefreshAllowed) {
                ScaffoldMessenger.of(context).showSnackBar(
                  CustomSnackBar.build(
                    isCooldown: true,
                    context: context,
                  ),
                );
                return;
              }

              _previousTheme = Map<String, dynamic>.from(currentTheme);

              setState(() {
                currentTheme = _getRandomTheme();
                currentSentence = getRandomSentence();
              });

              _colorTransitionController.reset();
              _colorTransitionController.forward();

              await Future.wait([
                _fetchSelectedYearAndSubjects(),
                _loadUserData(), 
              ]);
            },
            child: Stack(
              children: [
                Positioned.fill(child: FirstPageBackground()),
                _buildMainContent(theme),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMainContent(Map<String, dynamic> theme) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        ExpandableHeader(
          theme: theme,
          scaffoldKey: widget.scaffoldKey,
          isOnlineNotifier: _isOnlineNotifier,
          userName: _cachedUserName,
          currentSentence: currentSentence,
          subjects: subjects,
        ),
        SliverToBoxAdapter(
          child: Align(
            alignment: Alignment.topLeft,
            child: StoriesWidget(stories: storyUrls),
          ),
        ),
        _buildQuickAccessSection(),
        if (isLoading)
          const ShimmerGrid()
        else if (errorMessage != null)
          SliverToBoxAdapter(child: _buildErrorCard())
        else if (subjects.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            sliver: SubjectGridView(
              subjects: subjects,
              onSubjectTap: _navigateToSubjectDetails,
            ),
          )
        else
          SliverToBoxAdapter(child: _buildEmptyState(theme)),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildQuickAccessSection() {
    return SliverToBoxAdapter(
      child: Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TabsWidget(
              onTabPressed: (tabName) {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(LineIcons.exclamationTriangle, color: Colors.red, size: 48),
          const SizedBox(height: 15),
          Text(
            'Something went wrong',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            errorMessage ?? 'Please try again',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _fetchSelectedYearAndSubjects,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(Map<String, dynamic> theme) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: theme['surface'].withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme['surface'].withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(
            LineIcons.book,
            size: 64,
            color: Colors.white.withOpacity(0.5),
          ),
          const SizedBox(height: 20),
          Text(
            'No subjects available',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Check back later for updates',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
