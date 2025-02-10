import 'package:crystal_navigation_bar/crystal_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:port/forums/forum_page.dart';
import 'package:port/pages/user/google_auth_widget.dart';
import 'package:port/pages/yearpage.dart';
import 'pages/notice/notice_page.dart';
import 'pages/first page/first_page.dart';
import 'pages/widgets/refresh_tracker.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  @override
  void initState() {
    super.initState();
    RefreshTracker.init(); // Load the saved state from SharedPreferences
  }

  final List<Widget> _pages = [
    FirstPage(),
    ForumPage(),
    NoticePage(),
  ];

  void _onNavBarTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Necessary for floating CrystalNavigationBar

      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: CrystalNavigationBar(
        marginR: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
        paddingR: const EdgeInsets.symmetric(
            horizontal: 10, vertical: 10), // Additional padding
        currentIndex: _selectedIndex,
        onTap: _onNavBarTapped,
        items: [
          CrystalNavigationBarItem(
            icon: Icons.home_work_rounded,
            selectedColor: Colors.white,
          ),
          CrystalNavigationBarItem(
            icon: Icons.local_fire_department_rounded,
            selectedColor: Colors.red,
          ),
          CrystalNavigationBarItem(
            icon: Icons.event_note_outlined,
            selectedColor: Colors.greenAccent,
          ),
        ],
        backgroundColor: const Color(0xFF191B1A).withOpacity(0.5),
        unselectedItemColor: Colors.grey,
        height: 70,
        borderRadius: 30,
        splashBorderRadius: 30,
      ),
    );
  }
}
