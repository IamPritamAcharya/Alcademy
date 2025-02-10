import 'package:flutter/material.dart';
import 'pie_chart_section.dart';
import 'bar_chart_section.dart';

class GraphSection extends StatelessWidget {
  final List<Map<String, dynamic>> expenses;
  final double budget;

  const GraphSection({
    Key? key,
    required this.expenses,
    required this.budget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 250,
      child: PageView(
        children: [
          PieChartSection(expenses: expenses, budget: budget),
          BarChartSection(expenses: expenses),
        ],
      ),
    );
  }
}
