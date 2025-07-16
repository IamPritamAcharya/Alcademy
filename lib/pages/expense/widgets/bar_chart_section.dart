import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class BarChartSection extends StatelessWidget {
  final List<Map<String, dynamic>> expenses;

  const BarChartSection({
    Key? key,
    required this.expenses,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    
    final last7Days = List.generate(7, (index) {
      final day = now.subtract(Duration(days: index));
      final dailyExpenses = expenses.where((e) {
        final date = DateTime.tryParse(e['date'] ?? '');
        return date != null &&
            date.year == day.year &&
            date.month == day.month &&
            date.day == day.day;
      }).fold(0.0, (sum, e) => sum + (e['value'] as double? ?? 0.0));

      return {
        'day': day,
        'value': dailyExpenses,
      };
    }).reversed.toList(); 

    
    final maxY = (last7Days.isNotEmpty
            ? last7Days
                .map((data) => data['value'] as double)
                .reduce((a, b) => a > b ? a : b)
            : 0.0) +
        50;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        decoration: BoxDecoration(
          color:
              const Color.fromARGB(255, 31, 34, 35), 
          borderRadius: BorderRadius.circular(16), 
        ),
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          height: 300, 
          child: BarChart(
            BarChartData(
              maxY: maxY, 
              barGroups: last7Days.map((data) {
                final index = last7Days.indexOf(data);
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: data['value'] as double,
                      color: Colors.white,
                      width: 16,
                      borderRadius:
                          BorderRadius.circular(16), 
                    ),
                  ],
                );
              }).toList(),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles:
                      SideTitles(showTitles: false), 
                ),
                topTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < last7Days.length) {
                        final day = last7Days[index]['day'] as DateTime;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _getDayLetter(day),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),
              gridData: FlGridData(
                show: false, 
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getDayLetter(DateTime date) {
    
    const weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    return weekdays[date.weekday % 7];
  }
}
