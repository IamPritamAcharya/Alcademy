import 'package:port/shared/theme/app_style.dart';

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';

class ExpenseListSection extends StatelessWidget {
  final List<Map<String, dynamic>> expenses;
  final Function(int) onEditExpense;
  final Function(int) onDeleteExpense;

  const ExpenseListSection({
    super.key,
    required this.expenses,
    required this.onEditExpense,
    required this.onDeleteExpense,
  });

  void _showExpenseDetails(
    BuildContext context,
    Map<String, dynamic> expense,
    String formattedDate,
  ) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              color: AppStyle.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppStyle.rule, width: 1.5),
            ),
            child: Padding(
              padding: const EdgeInsets.only(
                top: 25.0,
                left: 25,
                right: 25,
                bottom: 15,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense['item'],
                    style: const TextStyle(
                      fontFamily: 'ProductSans',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppStyle.text,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Amount: ₹${expense['value'].toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontFamily: 'ProductSans',
                      fontSize: 16,
                      color: AppStyle.accent,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Date: $formattedDate',
                    style: const TextStyle(
                      fontFamily: 'ProductSans',
                      fontSize: 16,
                      color: AppStyle.blue,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        'Close',
                        style: TextStyle(
                          fontFamily: 'ProductSans',
                          color: AppStyle.muted,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: expenses.length,
      itemBuilder: (context, index) {
        final expense = expenses[index];
        final formattedDate = DateFormat(
          'dd/MM/yyyy',
        ).format(DateTime.parse(expense['date']));

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: GestureDetector(
            onTap: () => _showExpenseDetails(context, expense, formattedDate),
            child: Slidable(
              endActionPane: ActionPane(
                motion: const DrawerMotion(),
                children: [
                  SlidableAction(
                    onPressed: (_) => onEditExpense(index),
                    backgroundColor: AppStyle.accent,
                    foregroundColor: AppStyle.surface,
                    icon: Icons.edit_rounded,
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  SlidableAction(
                    onPressed: (_) => onDeleteExpense(index),
                    backgroundColor: AppStyle.danger,
                    foregroundColor: AppStyle.text,
                    icon: Icons.delete_outline_rounded,
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                ],
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: AppStyle.text.withValues(alpha: 0.035),
                  borderRadius: BorderRadius.circular(16.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 14.0,
                    horizontal: 25.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              expense['item'],
                              style: const TextStyle(
                                fontFamily: 'ProductSans',
                                color: AppStyle.text,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today_outlined,
                                  size: 12,
                                  color: AppStyle.muted,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  formattedDate,
                                  style: const TextStyle(
                                    fontFamily: 'ProductSans',
                                    color: AppStyle.muted,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '₹${expense['value'].toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontFamily: 'ProductSans',
                          color: AppStyle.accent,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
