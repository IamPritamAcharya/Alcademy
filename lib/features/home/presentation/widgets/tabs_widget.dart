import 'package:flutter/material.dart';
import 'package:port/core/config/app_config.dart';
import 'package:port/features/blog/presentation/blog_page.dart';
import 'package:port/features/success_stories/presentation/success_stories_page.dart';
import 'package:port/features/expenses/presentation/expense_tracker_page.dart';
import 'package:port/features/college_resources/presentation/erp_page.dart';
import 'package:port/features/home/presentation/widgets/first_tab_page.dart';
import 'package:port/shared/theme/app_style.dart';
import 'package:port/features/home/presentation/widgets/home_pressable.dart';

class TabsWidget extends StatelessWidget {
  final Function(String) onTabPressed;
  const TabsWidget({super.key, required this.onTabPressed});

  @override
  Widget build(BuildContext context) {
    final tabs =
        <({String name, IconData icon, Color accent, Widget Function() page})>[
          if (showFirstTab)
            (
              name: nameFirstTab,
              icon: Icons.auto_stories_outlined,
              accent: AppStyle.lilac,
              page: () => const FirstTabPage(),
            ),
          (
            name: 'Expenses',
            icon: Icons.account_balance_wallet_outlined,
            accent: AppStyle.gold,
            page: () => const ExpenseTrackerPage(),
          ),
          (
            name: 'ERP',
            icon: Icons.school_outlined,
            accent: AppStyle.blue,
            page: () => AcademicWebViewPage(),
          ),
          (
            name: 'Blog',
            icon: Icons.article_outlined,
            accent: AppStyle.accent,
            page: () => MarkdownListPage(),
          ),
          (
            name: 'Success stories',
            icon: Icons.emoji_events_outlined,
            accent: AppStyle.gold,
            page: () => SuccessStoriesPage(),
          ),
        ];
    Widget tool(int index) {
      final tab = tabs[index];
      final label = Text(
        tab.name,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppStyle.text,
          fontSize: 13,
          fontWeight: FontWeight.w500,
          height: 1.2,
        ),
      );
      final icon = Container(
        width: 48,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppStyle.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppStyle.rule),
        ),
        child: Icon(tab.icon, color: tab.accent, size: 27),
      );
      return HomePressable(
        entranceOrder: index,
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => tab.page()),
          );
          onTabPressed(tab.name);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          child: Column(children: [icon, const SizedBox(height: 10), label]),
        ),
      );
    }

    final fontSize = MediaQuery.textScalerOf(context).scale(13);
    return SizedBox(
      height: 78 + fontSize * 2.4,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        itemCount: tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 4),
        itemBuilder: (_, index) => SizedBox(
          width: (fontSize * 7).clamp(96.0, 180.0),
          child: tool(index),
        ),
      ),
    );
  }
}
