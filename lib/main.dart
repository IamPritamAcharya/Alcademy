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
import 'package:port/pages/forums/forum_page.dart';
import 'package:port/notification/notification_history_page.dart';
import 'package:port/notification/notification_service.dart';
import 'package:port/onboarding/pages/onboarding.dart';
import 'package:port/pages/about/aboutpage.dart';
import 'package:port/pages/amenities/amenities_page.dart.dart';
import 'package:port/pages/club/club_detail_page.dart';
import 'package:port/pages/club/club_post_detail.dart';
import 'package:port/pages/club/upload/CreateClubPostPage.dart';
import 'package:port/pages/college_res/Academic_calender_page.dart';
import 'package:port/pages/college_res/holiday_list_page.dart';
import 'package:port/pages/notice/notice_page.dart';
import 'package:port/pages/college_res/results_page.dart';
import 'package:port/pages/user/userinfo.dart';

import 'package:port/sgpa/branch_selector.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pages/ai_chatbot/another/apikey.dart';
import 'mainhome.dart';
import 'pages/college_res/syllabus.dart';

@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  print('Background message received: ${message.messageId}');
  print('Message data: ${message.data}');
  print(
      'Message notification: ${message.notification?.title} - ${message.notification?.body}');

  try {
    String title = message.notification?.title?.trim() ?? '';
    String body = message.notification?.body?.trim() ?? '';

    print('Extracted - Title: "$title", Body: "$body"');

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
      print('Background message has no valid title or body, rejecting');
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

    print('Saving notification data: $notificationData');

    final prefs = await SharedPreferences.getInstance();

    List<String> backgroundQueue =
        prefs.getStringList('background_notification_queue') ?? [];
    print('Current queue size: ${backgroundQueue.length}');

    bool alreadyQueued = false;
    for (String queuedJson in backgroundQueue) {
      try {
        final queuedData = jsonDecode(queuedJson);
        if (queuedData['id'] == id) {
          alreadyQueued = true;
          print('Notification already in queue: $id');
          break;
        }
      } catch (e) {
        print('Error checking queue item: $e');
      }
    }

    if (!alreadyQueued) {
      if (backgroundQueue.length >= 50) {
        backgroundQueue = backgroundQueue.sublist(backgroundQueue.length - 40);
        print('Cleaned background queue to ${backgroundQueue.length} items');
      }

      backgroundQueue.add(jsonEncode(notificationData));

      await prefs.setStringList(
          'background_notification_queue', backgroundQueue);
      await prefs.setInt('last_background_notification',
          DateTime.now().millisecondsSinceEpoch);
      await prefs.setBool('has_new_notification', true);

      print(
          "Background notification queued successfully: $title (Queue size: ${backgroundQueue.length})");

      final savedQueue =
          prefs.getStringList('background_notification_queue') ?? [];
      print("Queue verification - Saved ${savedQueue.length} items");
    } else {
      print("Background notification already queued: $title");
    }
  } catch (e) {
    print("Critical error in background handler: $e");

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

      print("Emergency notification saved: $title");
    } catch (emergencyError) {
      print("Emergency save also failed: $emergencyError");
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.linux) {
    print('Skipping Firebase initialization on Linux');
  } else {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);
    print('Background message handler registered');
  }

  await Supabase.initialize(
    url: 'https://uyrsftytepfamdrrjnst.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InV5cnNmdHl0ZXBmYW1kcnJqbnN0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzQ1NzgzNzgsImV4cCI6MjA1MDE1NDM3OH0.b-aorUVNH0bvRfn-h34Wa7YHUvRVJjofkAllQ7cYhp0',
  );

  if (!kIsWeb && defaultTargetPlatform != TargetPlatform.linux) {
    try {
      final notificationService = NotificationService();
      await notificationService.initialize();
      print('Notification service initialized successfully');
    } catch (e) {
      print('Failed to initialize notification service: $e');
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
  const MyApp({Key? key, required this.isOnboardingComplete}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
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
        GoRoute(
          path: "/club/:id",
          builder: (context, state) {
            final clubId = state.pathParameters['id']!;
            return ClubDetailPageFromLink(clubId: clubId);
          },
        ),
        GoRoute(
          path: "/post/:id",
          builder: (context, state) {
            final postId = state.pathParameters['id']!;
            return ClubPostDetailPage(postId: postId);
          },
        ),
        GoRoute(path: "/club", builder: (context, state) => HomePage()),
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
        GoRoute(path: "/forum", builder: (context, state) => const ForumPage()),
        GoRoute(path: "/about", builder: (context, state) => AboutPage()),
        GoRoute(
            path: "/chatbot", builder: (context, state) => const AiChatPage()),
        GoRoute(path: "/api", builder: (context, state) => const ApiKeyPage()),
        GoRoute(
            path: "/holiday", builder: (context, state) => HolidayListPage()),
        GoRoute(
            path: "/calendar",
            builder: (context, state) => AcademicCalendarPage()),
        GoRoute(
            path: "/upload", builder: (context, state) => CreateClubPostPage()),
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
        print(
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
          print("Navigating to notifications from home page");
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

    print('App lifecycle state changed to: $state');

    if (state == AppLifecycleState.resumed) {
      _handleAppResumed();
    } else if (state == AppLifecycleState.paused) {
      _handleAppPaused();
    }
  }

  Future<void> _handleAppResumed() async {
    print('App resumed - syncing notifications globally');

    if (!kIsWeb && defaultTargetPlatform != TargetPlatform.linux) {
      try {
        final notificationService = NotificationService();
        await notificationService.syncNotifications();

        await Future.delayed(Duration(milliseconds: 200));

        final selectedNotificationId =
            NotificationService.getSelectedNotificationId();
        if (selectedNotificationId != null &&
            selectedNotificationId.isNotEmpty) {
          print("App resumed via notification, navigating to notifications");

          final currentLocation =
              _router.routerDelegate.currentConfiguration.fullPath;
          if (currentLocation != "/notifications") {
            _router.go("/notifications");
          }
        }
      } catch (e) {
        print('Error handling app resume: $e');
      }
    }
  }

  void _handleAppPaused() {
    print('App paused - saving state');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Alcademy',
      debugShowCheckedModeBanner: false,
      scrollBehavior: _CustomScrollBehavior(),
      theme: ThemeData(
        fontFamily: 'ProductSans',
        inputDecorationTheme:
            const InputDecorationTheme(focusColor: Colors.white),
        textSelectionTheme:
            const TextSelectionThemeData(cursorColor: Colors.white),
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
