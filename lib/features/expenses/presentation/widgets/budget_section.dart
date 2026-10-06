import 'package:port/shared/theme/app_style.dart';
import 'package:flutter/material.dart';

import 'package:port/features/expenses/presentation/dialogs/budget_dialog.dart';

class BudgetSection extends StatelessWidget {
  final double budget;
  final double todaysExpense;
  final double last7DaysExpense;
  final Future<void> Function(double newBudget) onUpdateBudget;

  const BudgetSection({
    super.key,
    required this.budget,
    required this.todaysExpense,
    required this.last7DaysExpense,
    required this.onUpdateBudget,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppStyle.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                          color: AppStyle.muted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '₹${budget.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontFamily: 'ProductSans',
                          fontSize: 24,
                          color: AppStyle.text,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.edit, color: AppStyle.muted, size: 24),
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
            const Divider(color: AppStyle.muted, thickness: 0.5, height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: _buildExpenseItem(
                    title: "Today's Expense",
                    value: '₹${todaysExpense.toStringAsFixed(2)}',
                    color: AppStyle.danger,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildExpenseItem(
                    title: "Last 7 Days",
                    value: '₹${last7DaysExpense.toStringAsFixed(2)}',
                    color: AppStyle.blue,
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
            color: AppStyle.muted,
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
