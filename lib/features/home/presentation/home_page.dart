import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:port/features/home/presentation/widgets/app_drawer.dart';
import 'package:port/shared/theme/app_style.dart';
import 'package:port/features/notices/presentation/notice_page.dart';
import 'package:port/features/home/presentation/home_content_page.dart';
import 'package:port/core/network/refresh_tracker.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    RefreshTracker.init();
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.light,
    child: Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppStyle.background,
      drawer: const UniqueDrawer(themeColor: AppStyle.paper),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          TickerMode(
            enabled: _selectedIndex == 0,
            child: HomeContentPage(
              scaffoldKey: _scaffoldKey,
              isActive: _selectedIndex == 0,
            ),
          ),
          NoticePage(),
        ],
      ),
      bottomNavigationBar: HomeNavigation(
        selectedIndex: _selectedIndex,
        onSelected: (index) => setState(() => _selectedIndex = index),
      ),
    ),
  );
}

class HomeNavigation extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  const HomeNavigation({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) => Material(
    color: AppStyle.background,
    child: Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppStyle.rule)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            children: [
              _destination(0, 'Home', Icons.home_outlined),
              const SizedBox(width: 12),
              _destination(1, 'Notices', Icons.article_outlined),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _destination(int index, String label, IconData icon) {
    final selected = index == selectedIndex;
    return Expanded(
      child: Semantics(
        selected: selected,
        child: InkWell(
          onTap: () => onSelected(index),
          borderRadius: BorderRadius.circular(4),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: selected ? AppStyle.cover : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 21,
                  color: selected ? AppStyle.text : AppStyle.muted,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: selected ? AppStyle.text : AppStyle.muted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
