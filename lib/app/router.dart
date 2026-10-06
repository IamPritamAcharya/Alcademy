import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:port/features/notes/presentation/notes_selector_page.dart';
import 'package:port/features/notifications/presentation/notification_history_page.dart';
import 'package:port/features/about/presentation/about_page.dart';
import 'package:port/features/amenities/presentation/amenities_page.dart';
import 'package:port/features/college_resources/presentation/academic_calendar_page.dart';
import 'package:port/features/college_resources/presentation/holiday_list_page.dart';
import 'package:port/features/notices/presentation/notice_page.dart';
import 'package:port/features/college_resources/presentation/results_page.dart';
import 'package:port/features/profile/presentation/profile_page.dart';

import 'package:port/features/sgpa/presentation/branch_selector.dart';
import 'package:port/features/home/presentation/home_page.dart';
import 'package:port/features/college_resources/presentation/syllabus_page.dart';

GoRouter createAppRouter({
  required String initialLocation,
  required Widget Function() buildHome,
}) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    GoRoute(path: "/", builder: (context, state) => buildHome()),
    GoRoute(path: "/home", builder: (context, state) => HomePage()),
    GoRoute(path: "/notice", builder: (context, state) => NoticePage()),
    GoRoute(path: "/amenities", builder: (context, state) => AmenitiesPage()),
    GoRoute(path: "/syllabus", builder: (context, state) => SyllabusPage()),
    GoRoute(path: "/sgpa", builder: (context, state) => const BranchSelector()),
    GoRoute(
      path: "/user",
      builder: (context, state) => const UserProfilePage(),
    ),
    GoRoute(path: "/year", builder: (context, state) => NotesSelector()),
    GoRoute(path: "/about", builder: (context, state) => AboutPage()),
    GoRoute(path: "/holiday", builder: (context, state) => HolidayListPage()),
    GoRoute(
      path: "/calendar",
      builder: (context, state) => AcademicCalendarPage(),
    ),
    GoRoute(path: "/result", builder: (context, state) => ResultWebView()),
    GoRoute(
      path: "/notifications",
      builder: (context, state) => NotificationHistoryPage(),
    ),
  ],
);
