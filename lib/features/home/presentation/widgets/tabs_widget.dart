import 'package:flutter/material.dart';
import 'package:port/core/config/app_config.dart';
import 'package:port/features/ai_chat/presentation/chat_page.dart';
import 'package:port/features/blog/presentation/blog_page.dart';
import 'package:port/features/success_stories/presentation/success_stories_page.dart';
import 'package:port/features/expenses/presentation/expense_tracker_page.dart';
import 'package:port/features/college_resources/presentation/erp_page.dart';
import 'package:port/features/home/presentation/widgets/first_tab_page.dart';
import 'package:port/features/home/presentation/widgets/home_style.dart';

class TabsWidget extends StatelessWidget {
  final Function(String) onTabPressed;
  const TabsWidget({super.key, required this.onTabPressed});

  @override
  Widget build(BuildContext context) {
    final tabs = <({String name, IconData icon, Widget Function() page})>[
      if (showFirstTab)
        (
          name: nameFirstTab,
          icon: Icons.auto_stories_outlined,
          page: () => const FirstTabPage(),
        ),
      (
        name: 'Expenses',
        icon: Icons.account_balance_wallet_outlined,
        page: () => const ExpenseTrackerPage(),
      ),
      (
        name: 'ERP',
        icon: Icons.school_outlined,
        page: () => AcademicWebViewPage(),
      ),
      (
        name: 'Blog',
        icon: Icons.article_outlined,
        page: () => MarkdownListPage(),
      ),
      (
        name: 'Success stories',
        icon: Icons.emoji_events_outlined,
        page: () => SuccessStoriesPage(),
      ),
      (
        name: 'AI chat',
        icon: Icons.chat_bubble_outline_rounded,
        page: () => const AiChatPage(),
      ),
    ];
    return SizedBox(
      height: 112,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
        itemCount: tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final tab = tabs[index];
          return SizedBox(
            width: 108,
            child: Material(
              color: HomeStyle.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => tab.page()),
                  );
                  onTabPressed(tab.name);
                },
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(tab.icon, color: HomeStyle.text, size: 23),
                      Text(
                        tab.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: HomeStyle.text,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
