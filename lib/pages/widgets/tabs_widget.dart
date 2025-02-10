import 'package:flutter/material.dart';
import 'package:port/pages/blog/blog.dart';
import 'package:port/config.dart';
import 'package:port/test.dart';
import '../Success stories page/pages/success_stories_page.dart';
import '../expense/expense.dart';
import '../igiterp.dart';
import 'first_tab_widget.dart';

class TabsWidget extends StatelessWidget {
  final Function(String) onTabPressed;

  const TabsWidget({Key? key, required this.onTabPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> tabs = [
      {
        'name': 'Expense Tracker',
        'icon': Icons
            .account_balance_wallet_rounded, // More relevant to expenses/tracking
        'page': ExpenseTrackerPage()
      },
      {
        'name': 'ERP',
        'icon': Icons
            .person_outline_rounded, // Represents business/enterprise, better fit for ERP
        'page': AcademicWebViewPage()
      },
      {
        'name': 'Blog',
        'icon': Icons.article_rounded, // Icon for articles or blogging
        'page': MarkdownListPage()
      },
      {
        'name': 'Success Stories',
        'icon': Icons.star_border_rounded, // Represents success or achievements
        'page': SuccessStoriesPage()
      }
    ];

    return Container(
      height: 55,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length +
            (showFirstTab ? 1 : 0), // Adjust count based on condition
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          if (showFirstTab && index == 0) {
            // Use FirstTabWidget if showFirstTab is true
            return FirstTabWidget();
          }

          // Adjust index if FirstTabWidget is skipped
          final tabIndex = showFirstTab ? index - 1 : index;
          final String name = tabs[tabIndex]['name'] as String;
          final IconData icon = tabs[tabIndex]['icon'] as IconData;
          final Widget page = tabs[tabIndex]['page'] as Widget;

          return Padding(
            padding: EdgeInsets.only(
              left: index == 0 && !showFirstTab
                  ? 20
                  : 0, // Add left padding if no FirstTabWidget
              top: 6,
              bottom: 8,
            ),
            child: InkWell(
              onTap: () {
                // Navigate to the respective page when tapped
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => page),
                );
                onTabPressed(name);
              },
              borderRadius: BorderRadius.circular(30),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  color: Colors.white.withOpacity(0.05),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15), // Subtle shadow
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      icon,
                      color: Colors.white.withOpacity(0.8),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      name,
                      style: const TextStyle(
                        fontFamily: 'ProductSans',
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
