import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:port/core/config/daily_stories_service.dart';
import 'package:port/core/config/local_stories_preview.dart';
import 'package:flutter/material.dart';
import 'package:port/shared/theme/app_style.dart';
import 'package:go_router/go_router.dart';
import 'package:port/features/notifications/data/notification_service.dart';
import 'package:port/features/onboarding/presentation/onboarding_page.dart';

import 'package:port/features/home/presentation/home_page.dart';

import 'router.dart';
import 'theme.dart';

class MyApp extends StatefulWidget {
  final bool isOnboardingComplete;
  const MyApp({super.key, required this.isOnboardingComplete});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeRouter();
    if (!LocalStoriesPreview.enabled) {
      unawaited(DailyStoriesService.startUpdates());
    }
    NotificationService.navigationRequests.addListener(
      _handleNotificationNavigation,
    );
  }

  void _initializeRouter() {
    _router = createAppRouter(
      initialLocation: _getInitialLocation(),
      buildHome: _buildHomePage,
    );
  }

  String _getInitialLocation() {
    if (!kIsWeb && defaultTargetPlatform != TargetPlatform.linux) {
      final selectedRoute = NotificationService.takeSelectedNotificationRoute();
      final selectedNotificationId =
          NotificationService.getSelectedNotificationId();
      if (selectedNotificationId != null && selectedNotificationId.isNotEmpty) {
        debugPrint(
          "App opened via notification, navigating to notifications page",
        );
        return selectedRoute ?? "/notifications";
      }
    }

    return "/";
  }

  Widget _buildHomePage() {
    if (!kIsWeb && defaultTargetPlatform != TargetPlatform.linux) {
      final selectedRoute = NotificationService.takeSelectedNotificationRoute();
      final selectedNotificationId =
          NotificationService.getSelectedNotificationId();
      if (selectedNotificationId != null && selectedNotificationId.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          debugPrint("Navigating to notifications from home page");
          _router.go(selectedRoute ?? "/notifications");
        });
      }
    }

    return widget.isOnboardingComplete ? HomePage() : OnboardingScreen();
  }

  @override
  void dispose() {
    NotificationService.navigationRequests.removeListener(
      _handleNotificationNavigation,
    );
    DailyStoriesService.stopUpdates();
    _router.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _handleNotificationNavigation() {
    final route = NotificationService.takeSelectedNotificationRoute();
    final id = NotificationService.getSelectedNotificationId();
    if (id == null || id.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _router.go(route ?? '/notifications');
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    debugPrint('App lifecycle state changed to: $state');

    if (state == AppLifecycleState.resumed) {
      if (!LocalStoriesPreview.enabled) {
        unawaited(DailyStoriesService.startUpdates());
      }
      _handleAppResumed();
    } else if (state == AppLifecycleState.paused) {
      DailyStoriesService.stopUpdates();
      _handleAppPaused();
    }
  }

  Future<void> _handleAppResumed() async {
    debugPrint('App resumed - syncing notifications globally');

    if (!kIsWeb && defaultTargetPlatform != TargetPlatform.linux) {
      try {
        final notificationService = NotificationService();
        await notificationService.syncNotifications();

        await Future.delayed(Duration(milliseconds: 200));
        if (!mounted) return;

        final selectedRoute =
            NotificationService.takeSelectedNotificationRoute();
        final selectedNotificationId =
            NotificationService.getSelectedNotificationId();
        if (selectedNotificationId != null &&
            selectedNotificationId.isNotEmpty) {
          debugPrint(
            "App resumed via notification, navigating to notifications",
          );

          final currentLocation =
              _router.routerDelegate.currentConfiguration.fullPath;
          final destination = selectedRoute ?? "/notifications";
          if (currentLocation != destination) {
            _router.go(destination);
          }
        }
      } catch (e) {
        debugPrint('Error handling app resume: $e');
      }
    }
  }

  void _handleAppPaused() {
    debugPrint('App paused - saving state');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Alcademy',
      debugShowCheckedModeBanner: false,
      color: AppStyle.background,
      scrollBehavior: AppScrollBehavior(),
      theme: buildAppTheme(),
      routerConfig: _router,
    );
  }
}
