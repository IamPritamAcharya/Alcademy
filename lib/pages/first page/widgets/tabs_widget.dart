import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:port/pages/ai_chatbot/another/chat.dart';
import 'package:port/utils/config.dart';
import 'package:port/pages/blog/blog.dart';
import '../../Success stories page/pages/success_stories_page.dart';
import '../../expense/expense.dart';
import '../../college_res/igiterp.dart';
import 'first_tab_widget.dart';

class TabsWidget extends StatelessWidget {
  final Function(String) onTabPressed;

  const TabsWidget({Key? key, required this.onTabPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> tabs = [
      {
        'name': 'Expense Tracker',
        'icon': LineIcons.wallet,
        'page': ExpenseTrackerPage(),
      },
      {
        'name': 'ERP',
        'icon': LineIcons.userCog,
        'page': AcademicWebViewPage(),
      },
      {
        'name': 'Blog',
        'icon': LineIcons.newspaper,
        'page': MarkdownListPage(),
      },
      {
        'name': 'Success Stories',
        'icon': LineIcons.trophy,
        'page': SuccessStoriesPage(),
      },
      {
        'name': 'AI Chat',
        'icon': LineIcons.rocketChat,
        'page': AiChatPage(),
      }
    ];

    return SizedBox(
      height: 75,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length + (showFirstTab ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        itemBuilder: (context, index) {
          if (showFirstTab && index == 0) {
            return FirstTabWidget();
          }

          final tabIndex = showFirstTab ? index - 1 : index;
          final String name = tabs[tabIndex]['name'] as String;
          final IconData icon = tabs[tabIndex]['icon'] as IconData;
          final Widget page = tabs[tabIndex]['page'] as Widget;

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => page),
              );
              onTabPressed(name);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: Colors.white.withOpacity(0.1),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    color: Colors.white.withOpacity(0.9),
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    name,
                    style: const TextStyle(
                      fontFamily: 'ProductSans',
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
