import 'package:crystal_navigation_bar/crystal_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:port/pages/club/clubspage.dart';
import 'package:port/pages/first%20page/ExtendedAppBarWithSlidingEffect.dart';
import 'package:port/pages/notice/notice_page.dart';
import 'package:port/pages/first%20page/first_page.dart';
import 'package:port/pages/widgets/refresh_tracker.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;
  Color? receivedColor; // Store the color received from FirstPage

  void updateColor(Color newColor) {
    setState(() {
      receivedColor = newColor; // Update the color
    });
  }

  @override
  void initState() {
    super.initState();
    RefreshTracker.init(); // Load the saved state from SharedPreferences
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      FirstPage(
        scaffoldKey: _scaffoldKey,
      ), // Pass the key to FirstPage
      
      ClubsPage(),
      NoticePage(),
    ];

    return Scaffold(
      extendBody: true,
      key: _scaffoldKey,
      drawer: UniqueDrawer(themeColor: const Color(0xFF1A1D1E)),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: CrystalNavigationBar(
        marginR: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
        paddingR: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
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
