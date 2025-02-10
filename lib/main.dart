import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:port/ai_chatbot/another/chat.dart';
import 'package:port/config/config_loader.dart';
import 'package:port/firebase_options.dart';
import 'package:port/forums/forum_page.dart';
import 'package:port/onboarding/onboarding.dart';
import 'package:port/pages/aboutpage.dart';
import 'package:port/pages/amenities/amenities_page.dart.dart';
import 'package:port/pages/college_res/Academic_calender_page.dart';
import 'package:port/pages/college_res/holiday_list_page.dart';
import 'package:port/pages/expense/expense.dart';
import 'package:port/pages/pin%20page/screens/pinpage.dart';
import 'package:port/pages/user/google_auth_widget.dart';
import 'package:port/pages/user/userinfo.dart';
import 'package:port/pages/yearpage.dart';
import 'package:port/sgpa/branch_selector.dart';
import 'package:port/test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'ai_chatbot/another/apikey.dart';
import 'notification_service.dart';
import 'mainhome.dart';
import 'pages/syllabus.dart';
import 'config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await Supabase.initialize(
    url:
        '', 
    anonKey:
        '', 
  );

  final notificationService = NotificationService();
  await notificationService.initialize();

  // Check if onboarding is complete
  final prefs = await SharedPreferences.getInstance();
  final bool isOnboardingComplete =
      prefs.getBool('onboarding_complete') ?? false;

  // Fetch configuration once
  await ConfigService.fetchAndUpdateConfig();

  runApp(MyApp(isOnboardingComplete: isOnboardingComplete));
}

class MyApp extends StatelessWidget {
  final bool isOnboardingComplete;

  MyApp({required this.isOnboardingComplete});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Alcademy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'ProductSans',
        inputDecorationTheme: InputDecorationTheme(
          focusColor: Colors.white,
        ),
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: Colors.white, // Sets the cursor color to white
        ),
      ),
      home: isOnboardingComplete ? HomePage() : HomePage(),
      routes: {
        '/home': (context) => HomePage(),
        '/amenities': (context) => AmenitiesPage(),
        '/syllabus': (context) => SyllabusPage(),
        '/sgpa': (context) => BranchSelector(),
        '/user': (context) => UserProfilePage(),
        '/year': (context) => YearPage(),
        '/pin': (context) => PinPage(),
        '/forum': (context) => ForumPage(),
        '/about': (context) => AboutPage(),
        '/chatbot': (context) => AiChatPage(),
        '/api': (context) => ApiKeyPage(),
        '/holiday': (context) => HolidayListPage(),
        '/calendar': (context) => AcademicCalendarPage(),
        '/hello': (context) => HelloPage(),
      },
    );
  }
}
