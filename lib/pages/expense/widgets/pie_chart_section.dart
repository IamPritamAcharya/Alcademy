import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class PieChartSection extends StatefulWidget {
  final List<Map<String, dynamic>> expenses;
  final double budget;

  const PieChartSection({
    Key? key,
    required this.expenses,
    required this.budget,
  }) : super(key: key);

  @override
  State<PieChartSection> createState() => _PieChartSectionState();
}

class _PieChartSectionState extends State<PieChartSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    _animation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutQuad),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalExpenses =
        widget.expenses.fold(0.0, (sum, e) => sum + e['value']);
    final remainingBudget =
        (widget.budget - totalExpenses).clamp(0.0, widget.budget) as double;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        decoration: BoxDecoration(
          color: const Color.fromARGB(
              255, 31, 34, 35), // Match BarChart's background
          borderRadius: BorderRadius.circular(16), // Rounded corners
        ),
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          height: 300, // Match the height with BarChart
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Transform.scale(
                scale: _animation.value,
                child: PieChart(
                  PieChartData(
                    sections: [
                      PieChartSectionData(
                        radius: 40,
                        value: totalExpenses,
                        title: totalExpenses > 0
                            ? '₹${totalExpenses.toStringAsFixed(0)}'
                            : '',
                        color: Colors.redAccent,
                        titleStyle: const TextStyle(
                          fontFamily: 'ProductSans',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      PieChartSectionData(
                        radius: 43,
                        value: remainingBudget,
                        title: remainingBudget > 0
                            ? '₹${remainingBudget.toStringAsFixed(0)}'
                            : '',
                        color: const Color.fromRGBO(0, 255, 127, 1),
                        titleStyle: const TextStyle(
                          fontFamily: 'ProductSans',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                    centerSpaceRadius: 55,
                    sectionsSpace: 4,
                    borderData: FlBorderData(show: false),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
