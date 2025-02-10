import 'package:flutter/material.dart';

import '../dialogs/budget_dialog.dart';

class BudgetSection extends StatelessWidget {
  final double budget;
  final double todaysExpense;
  final double last7DaysExpense;
  final Future<void> Function(double newBudget) onUpdateBudget;

  const BudgetSection({
    Key? key,
    required this.budget,
    required this.todaysExpense,
    required this.last7DaysExpense,
    required this.onUpdateBudget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 31, 34, 35), // Card background color
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05), // Minimal shadow
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Budget Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Current Budget",
                        style: TextStyle(
                          fontFamily: 'ProductSans',
                          fontSize: 16,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '₹${budget.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontFamily: 'ProductSans',
                          fontSize: 24,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.edit,
                    color: Colors.grey.shade400,
                    size: 24,
                  ),
                  onPressed: () async {
                    final newBudget = await showDialog<double>(
                      context: context,
                      builder: (context) => BudgetDialog(initialBudget: budget),
                    );

                    if (newBudget != null) {
                      await onUpdateBudget(newBudget);
                    }
                  },
                  splashRadius: 20,
                  tooltip: 'Edit Budget',
                ),
              ],
            ),
            const Divider(
              color: Colors.grey,
              thickness: 0.5,
              height: 24,
            ),
            // Today's Expense and Last 7 Days Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: _buildExpenseItem(
                    title: "Today's Expense",
                    value: '₹${todaysExpense.toStringAsFixed(2)}',
                    color: Colors.redAccent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildExpenseItem(
                    title: "Last 7 Days",
                    value: '₹${last7DaysExpense.toStringAsFixed(2)}',
                    color: Colors.blueAccent,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseItem({
    required String title,
    required String value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'ProductSans',
            fontSize: 16,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'ProductSans',
            fontSize: 20,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
