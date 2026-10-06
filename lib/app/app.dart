import 'package:flutter/foundation.dart';
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
  }

  void _initializeRouter() {
    _router = createAppRouter(
      initialLocation: _getInitialLocation(),
      buildHome: _buildHomePage,
    );
  }

  String _getInitialLocation() {
    if (!kIsWeb && defaultTargetPlatform != TargetPlatform.linux) {
      final selectedNotificationId =
          NotificationService.getSelectedNotificationId();
      if (selectedNotificationId != null && selectedNotificationId.isNotEmpty) {
        debugPrint(
          "App opened via notification, navigating to notifications page",
        );
        return "/notifications";
      }
    }

    return "/";
  }

  Widget _buildHomePage() {
    if (!kIsWeb && defaultTargetPlatform != TargetPlatform.linux) {
      final selectedNotificationId =
          NotificationService.getSelectedNotificationId();
      if (selectedNotificationId != null && selectedNotificationId.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          debugPrint("Navigating to notifications from home page");
          _router.go("/notifications");
        });
      }
    }

    return widget.isOnboardingComplete ? HomePage() : OnboardingScreen();
  }

  @override
  void dispose() {
    _router.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    debugPrint('App lifecycle state changed to: $state');

    if (state == AppLifecycleState.resumed) {
      _handleAppResumed();
    } else if (state == AppLifecycleState.paused) {
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

        final selectedNotificationId =
            NotificationService.getSelectedNotificationId();
        if (selectedNotificationId != null &&
            selectedNotificationId.isNotEmpty) {
          debugPrint(
            "App resumed via notification, navigating to notifications",
          );

          final currentLocation =
              _router.routerDelegate.currentConfiguration.fullPath;
          if (currentLocation != "/notifications") {
            _router.go("/notifications");
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
