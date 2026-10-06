import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:go_router/go_router.dart';
import 'package:port/pages/notes_selector_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:port/pages/ai_chatbot/another/chat.dart';
import 'package:port/utils/config_loader.dart';
import 'package:port/firebase_options.dart';
import 'package:port/notification/notification_history_page.dart';
import 'package:port/notification/notification_service.dart';
import 'package:port/onboarding/pages/onboarding.dart';
import 'package:port/pages/about/aboutpage.dart';
import 'package:port/pages/amenities/amenities_page.dart.dart';
import 'package:port/pages/college_res/academic_calendar_page.dart';
import 'package:port/pages/college_res/holiday_list_page.dart';
import 'package:port/pages/notice/notice_page.dart';
import 'package:port/pages/college_res/results_page.dart';
import 'package:port/pages/user/userinfo.dart';

import 'package:port/sgpa/branch_selector.dart';
import 'pages/ai_chatbot/another/apikey.dart';
import 'mainhome.dart';
import 'pages/college_res/syllabus.dart';

@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background message received: ${message.messageId}');
  debugPrint('Message data: ${message.data}');
  debugPrint(
      'Message notification: ${message.notification?.title} - ${message.notification?.body}');

  try {
    String title = message.notification?.title?.trim() ?? '';
    String body = message.notification?.body?.trim() ?? '';

    debugPrint('Extracted - Title: "$title", Body: "$body"');

    if (title.isEmpty && message.data.containsKey('title')) {
      title = message.data['title']?.toString().trim() ?? '';
    }
    if (body.isEmpty) {
      if (message.data.containsKey('body')) {
        body = message.data['body']?.toString().trim() ?? '';
      } else if (message.data.containsKey('message')) {
        body = message.data['message']?.toString().trim() ?? '';
      }
    }

    if (title.isEmpty && body.isEmpty) {
      debugPrint('Background message has no valid title or body, rejecting');
      return;
    }

    if (title.isEmpty) {
      title = 'New Notification';
    }
    if (body.isEmpty) {
      body = 'You have a new notification';
    }

    String id = message.messageId?.trim() ??
        'bg_${DateTime.now().millisecondsSinceEpoch}';

    final notificationData = {
      'id': id,
      'title': title,
      'body': body,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'data': message.data.isNotEmpty
          ? Map<String, dynamic>.from(message.data)
          : <String, dynamic>{},
    };

    debugPrint('Saving notification data: $notificationData');

    final prefs = await SharedPreferences.getInstance();

    List<String> backgroundQueue =
        prefs.getStringList('background_notification_queue') ?? [];
    debugPrint('Current queue size: ${backgroundQueue.length}');

    bool alreadyQueued = false;
    for (String queuedJson in backgroundQueue) {
      try {
        final queuedData = jsonDecode(queuedJson);
        if (queuedData['id'] == id) {
          alreadyQueued = true;
          debugPrint('Notification already in queue: $id');
          break;
        }
      } catch (e) {
        debugPrint('Error checking queue item: $e');
      }
    }

    if (!alreadyQueued) {
      if (backgroundQueue.length >= 50) {
        backgroundQueue = backgroundQueue.sublist(backgroundQueue.length - 40);
        debugPrint(
            'Cleaned background queue to ${backgroundQueue.length} items');
      }

      backgroundQueue.add(jsonEncode(notificationData));

      await prefs.setStringList(
          'background_notification_queue', backgroundQueue);
      await prefs.setInt('last_background_notification',
          DateTime.now().millisecondsSinceEpoch);
      await prefs.setBool('has_new_notification', true);

      debugPrint(
          "Background notification queued successfully: $title (Queue size: ${backgroundQueue.length})");

      final savedQueue =
          prefs.getStringList('background_notification_queue') ?? [];
      debugPrint("Queue verification - Saved ${savedQueue.length} items");
    } else {
      debugPrint("Background notification already queued: $title");
    }
  } catch (e) {
    debugPrint("Critical error in background handler: $e");

    try {
      final title =
          message.notification?.title?.trim() ?? 'Emergency Notification';
      final body =
          message.notification?.body?.trim() ?? 'Notification parsing failed';

      final prefs = await SharedPreferences.getInstance();
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      final emergencyNotification = {
        'id': 'emergency_$timestamp',
        'title': title,
        'body': body,
        'timestamp': timestamp,
        'data': <String, dynamic>{},
      };

      List<String> backgroundQueue =
          prefs.getStringList('background_notification_queue') ?? [];
      backgroundQueue.add(jsonEncode(emergencyNotification));
      await prefs.setStringList(
          'background_notification_queue', backgroundQueue);
      await prefs.setBool('has_new_notification', true);

      debugPrint("Emergency notification saved: $title");
    } catch (emergencyError) {
      debugPrint("Emergency save also failed: $emergencyError");
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.linux) {
    debugPrint('Skipping Firebase initialization on Linux');
  } else {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);
    debugPrint('Background message handler registered');
  }

  if (!kIsWeb && defaultTargetPlatform != TargetPlatform.linux) {
    try {
      final notificationService = NotificationService();
      await notificationService.initialize();
      debugPrint('Notification service initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize notification service: $e');
    }
  }

  final prefs = await SharedPreferences.getInstance();
  final bool isOnboardingComplete =
      prefs.getBool('onboarding_complete') ?? false;

  await ConfigService.fetchAndUpdateConfig();

  runApp(MyApp(isOnboardingComplete: isOnboardingComplete));
}

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
    _router = GoRouter(
      initialLocation: _getInitialLocation(),
      routes: [
        GoRoute(
          path: "/",
          builder: (context, state) => _buildHomePage(),
        ),
        GoRoute(path: "/home", builder: (context, state) => HomePage()),
        GoRoute(path: "/notice", builder: (context, state) => NoticePage()),
        GoRoute(
            path: "/amenities", builder: (context, state) => AmenitiesPage()),
        GoRoute(path: "/syllabus", builder: (context, state) => SyllabusPage()),
        GoRoute(
            path: "/sgpa", builder: (context, state) => const BranchSelector()),
        GoRoute(
            path: "/user",
            builder: (context, state) => const UserProfilePage()),
        GoRoute(path: "/year", builder: (context, state) => NotesSelector()),
        GoRoute(path: "/about", builder: (context, state) => AboutPage()),
        GoRoute(
            path: "/chatbot", builder: (context, state) => const AiChatPage()),
        GoRoute(path: "/api", builder: (context, state) => const ApiKeyPage()),
        GoRoute(
            path: "/holiday", builder: (context, state) => HolidayListPage()),
        GoRoute(
            path: "/calendar",
            builder: (context, state) => AcademicCalendarPage()),
        GoRoute(path: "/result", builder: (context, state) => ResultWebView()),
        GoRoute(
            path: "/notifications",
            builder: (context, state) => NotificationHistoryPage()),
      ],
    );
  }

  String _getInitialLocation() {
    if (!kIsWeb && defaultTargetPlatform != TargetPlatform.linux) {
      final selectedNotificationId =
          NotificationService.getSelectedNotificationId();
      if (selectedNotificationId != null && selectedNotificationId.isNotEmpty) {
        debugPrint(
            "App opened via notification, navigating to notifications page");
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
              "App resumed via notification, navigating to notifications");

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
      color: const Color(0xFF121212),
      scrollBehavior: _CustomScrollBehavior(),
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        canvasColor: const Color(0xFF121212),
        fontFamily: 'ProductSans',
        inputDecorationTheme:
            const InputDecorationTheme(focusColor: Colors.white),
        textSelectionTheme:
            const TextSelectionThemeData(cursorColor: Colors.white),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      routerConfig: _router,
    );
  }
}

class _CustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };
}
