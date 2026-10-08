import 'dart:async';
import 'package:flutter/material.dart';
import 'package:port/features/profile/data/profile_repository.dart';
import 'package:port/features/home/presentation/widgets/tabs_widget.dart';
import 'package:port/core/config/app_config.dart';
import 'package:port/features/stories/presentation/stories_widget.dart';

import 'package:port/features/home/presentation/widgets/home_header.dart';
import 'package:port/shared/theme/app_style.dart';
import 'package:port/features/home/presentation/widgets/home_subject_list.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:port/core/network/refresh_tracker.dart';
import 'package:port/core/network/github_sources.dart';
import 'package:port/shared/widgets/custom_snackbar.dart';

import 'package:port/features/notes/data/subject_repository.dart';
import 'package:port/features/notes/models/subject.dart';
import 'package:port/features/notes/presentation/subject_details_page.dart';
import 'package:port/features/home/presentation/greetings.dart';

import 'package:connectivity_plus/connectivity_plus.dart';

class HomeContentPage extends StatefulWidget {
  final GlobalKey<ScaffoldState>? scaffoldKey;
  final bool isActive;

  const HomeContentPage({super.key, this.scaffoldKey, this.isActive = true});

  @override
  State<HomeContentPage> createState() => _FirstPageState();
}

class _FirstPageState extends State<HomeContentPage>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  @override
  bool get wantKeepAlive => true;

  final SubjectRepository subjectService = SubjectRepository('');
  List<Subject> subjects = [];
  bool isLoading = true;
  String? errorMessage;
  late String currentSentence;
  String? _cachedUserName;

  final ValueNotifier<bool> _isOnlineNotifier = ValueNotifier(true);
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    AppConfiguration.current.addListener(_onConfigChanged);
    WidgetsBinding.instance.addObserver(this);
    currentSentence = getRandomSentence();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initConnectivity();
      _loadUserData();
      _fetchSelectedYearAndSubjects();
    });
  }

  @override
  void dispose() {
    AppConfiguration.current.removeListener(_onConfigChanged);
    WidgetsBinding.instance.removeObserver(this);
    _isOnlineNotifier.dispose();
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    _cachedUserName = await ProfileRepository.getUserName();
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
      if (!mounted) return;
      _updateConnectionStatus(results);
      _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
        _updateConnectionStatus,
      );
    } catch (e) {
      _updateConnectionStatus([]);
    }
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    if (!mounted) return;
    final isOnline =
        results.isNotEmpty &&
        results.any((result) => result != ConnectivityResult.none);
    if (_isOnlineNotifier.value != isOnline) {
      _isOnlineNotifier.value = isOnline;
    }
  }

  Future<void> _fetchSelectedYearAndSubjects() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final selectedYearUrl =
          prefs.getString('selectedYearUrl') ?? GitHubSources.defaultSubjects;

      subjectService.url = selectedYearUrl;
      final fetchedSubjects = await subjectService.fetchSubjects();

      if (!mounted) return;

      if (mounted) {
        setState(() {
          subjects = fetchedSubjects;
          isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;

      if (mounted) {
        setState(() {
          errorMessage = 'Failed to load subjects. Please try again.';
          isLoading = false;
        });
      }
    }
  }

  Future<void> _navigateToSubjectDetails(
    BuildContext context,
    Subject subject,
  ) async {
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

  void _refreshGreeting() {
    if (mounted) {
      setState(
        () => currentSentence = getRandomSentence(previous: currentSentence),
      );
    }
  }

  @override
  void didUpdateWidget(covariant HomeContentPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) _refreshGreeting();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && widget.isActive) {
      _refreshGreeting();
    }
  }

  void _onConfigChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _refresh() async {
    final allowed = await RefreshTracker.incrementRefreshCount();
    if (!mounted) return;
    if (!allowed) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(CustomSnackBar.build(isCooldown: true, context: context));
      return;
    }
    _refreshGreeting();
    await Future.wait([_fetchSelectedYearAndSubjects(), _loadUserData()]);
  }

  Future<void> _chooseYear() async {
    await context.push('/year');
    if (!mounted) return;
    await _fetchSelectedYearAndSubjects();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: AppStyle.background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppStyle.text,
          backgroundColor: AppStyle.background,
          onRefresh: _refresh,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: HomeHeader(
                  isOnlineNotifier: _isOnlineNotifier,
                  userName: _cachedUserName,
                  resourceCount: isLoading
                      ? null
                      : subjects.fold<int>(
                          0,
                          (total, subject) => total + subject.items.length,
                        ),
                  currentSentence: currentSentence,
                  onNewGreeting: _refreshGreeting,
                  onMenu: () => widget.scaffoldKey?.currentState?.openDrawer(),
                ),
              ),
              if (storyUrls.isNotEmpty) ...[
                const SliverToBoxAdapter(
                  child: _SectionHeading(
                    title: 'Around campus',
                    eyebrow: 'THE NOTICEBOARD',
                  ),
                ),
                SliverToBoxAdapter(child: StoriesWidget(stories: storyUrls)),
              ],
              const SliverToBoxAdapter(
                child: _SectionHeading(
                  title: 'The essentials',
                  eyebrow: 'YOUR CAMPUS TOOLKIT',
                ),
              ),
              SliverToBoxAdapter(
                child: TabsWidget(onTabPressed: (_) => _refreshGreeting()),
              ),
              SliverToBoxAdapter(
                child: _SectionHeading(
                  title: 'Your subjects',
                  eyebrow: 'THE STUDY SHELF',
                  action: TextButton.icon(
                    onPressed: _chooseYear,
                    icon: const Icon(Icons.tune_rounded, size: 16),
                    label: const Text('Change year'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppStyle.accent,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      textStyle: const TextStyle(
                        fontFamily: 'ProductSans',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
              if (isLoading)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppStyle.text,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                )
              else if (errorMessage != null)
                SliverToBoxAdapter(
                  child: _buildState(
                    title: 'The shelf couldn’t load.',
                    message: errorMessage!,
                    retry: true,
                  ),
                )
              else if (subjects.isNotEmpty)
                HomeSubjectList(
                  subjects: subjects,
                  onSubjectTap: _navigateToSubjectDetails,
                )
              else
                SliverToBoxAdapter(
                  child: _buildState(
                    title: 'A fresh shelf.',
                    message:
                        'No subjects available yet. Try another year or check back later.',
                  ),
                ),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(24, 28, 24, 32),
                  child: Text(
                    'ONE CHAPTER AT A TIME.',
                    style: AppStyle.eyebrow,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildState({
    required String title,
    required String message,
    bool retry = false,
  }) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 24),
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: AppStyle.surface,
      borderRadius: BorderRadius.circular(4),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppStyle.text,
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          style: const TextStyle(
            color: AppStyle.muted,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        if (retry) ...[
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _fetchSelectedYearAndSubjects,
            style: TextButton.styleFrom(foregroundColor: AppStyle.text),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Try again'),
          ),
        ],
      ],
    ),
  );
}

class _SectionHeading extends StatelessWidget {
  final String title;
  final String eyebrow;
  final Widget? action;
  const _SectionHeading({
    required this.title,
    required this.eyebrow,
    this.action,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(eyebrow, style: AppStyle.eyebrow),
        const SizedBox(height: 5),
        LayoutBuilder(
          builder: (context, constraints) {
            final heading = Text(
              title,
              style: const TextStyle(
                color: AppStyle.text,
                fontSize: 25,
                letterSpacing: -.6,
                fontWeight: FontWeight.bold,
              ),
            );
            if (action == null) return heading;
            return Row(
              children: [
                Expanded(
                  flex: 3,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: heading,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  flex: 2,
                  child: SizedBox(
                    height: 48,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: action!,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    ),
  );
}
