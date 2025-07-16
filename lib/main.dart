import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';
import 'package:port/ai_chatbot/another/chat.dart';
import 'package:port/config/config_loader.dart';
import 'package:port/firebase_options.dart';
import 'package:port/forums/forum_page.dart';
import 'package:port/onboarding/onboarding.dart';
import 'package:port/pages/aboutpage.dart';
import 'package:port/pages/amenities/amenities_page.dart.dart';
import 'package:port/pages/club/club_detail_page.dart';
import 'package:port/pages/club/club_post_detail.dart';
import 'package:port/pages/club/clubspage.dart';
import 'package:port/pages/club/upload/CreateClubPostPage.dart';
import 'package:port/pages/college_res/Academic_calender_page.dart';
import 'package:port/pages/college_res/holiday_list_page.dart';
import 'package:port/pages/expense/expense.dart';
import 'package:port/pages/notice/notice_page.dart';
import 'package:port/pages/pin%20page/screens/pinpage.dart';
import 'package:port/pages/results/results_page.dart';
import 'package:port/pages/user/google_auth_widget.dart';
import 'package:port/pages/user/userinfo.dart';
import 'package:port/pages/yearpage.dart';
import 'package:port/sgpa/branch_selector.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'ai_chatbot/another/apikey.dart';
import 'notification_service.dart';
import 'mainhome.dart';
import 'pages/syllabus.dart';
import 'config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.linux) {
    // Skip Firebase initialization on Linux
  } else {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  await Supabase.initialize(
    url: 'https://uyrsftytepfamdrrjnst.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InV5cnNmdHl0ZXBmYW1kcnJqbnN0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzQ1NzgzNzgsImV4cCI6MjA1MDE1NDM3OH0.b-aorUVNH0bvRfn-h34Wa7YHUvRVJjofkAllQ7cYhp0',
  );

  // final notificationService = NotificationService();
  // await notificationService.initialize();

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

    _router = GoRouter(
      initialLocation: "/",
      routes: [
        GoRoute(
            path: "/",
            builder: (context, state) =>
                widget.isOnboardingComplete ? HomePage() : OnboardingScreen()),
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
        GoRoute(path: "/year", builder: (context, state) => YearPage()),
        GoRoute(path: "/pin", builder: (context, state) => PinPage()),
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
      ],
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
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
      routerConfig: _router, // ✅ Now uses preserved instance
    );
  }
}

// Custom Scroll Behavior for Desktop and Web Mouse Scrolling
class _CustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };
}
