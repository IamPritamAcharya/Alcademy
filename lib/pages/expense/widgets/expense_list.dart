import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart'; // For date formatting

class ExpenseListSection extends StatelessWidget {
  final List<Map<String, dynamic>> expenses;
  final Function(int) onEditExpense;
  final Function(int) onDeleteExpense;

  const ExpenseListSection({
    Key? key,
    required this.expenses,
    required this.onEditExpense,
    required this.onDeleteExpense,
  }) : super(key: key);

  void _showExpenseDetails(BuildContext context, Map<String, dynamic> expense,
      String formattedDate) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor:
            Colors.transparent, // Transparent background for glass effect
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade800
                    .withOpacity(0.1), // Frosted glass effect
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1.5,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.only(
                    top: 25.0, left: 25, right: 25, bottom: 15),
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
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Amount: ₹${expense['value'].toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontFamily: 'ProductSans',
                        fontSize: 16,
                        color: Colors.greenAccent,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Date: $formattedDate',
                      style: const TextStyle(
                        fontFamily: 'ProductSans',
                        fontSize: 16,
                        color: Colors.blueAccent,
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
                            color: Colors.grey,
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
        final formattedDate =
            DateFormat('dd/MM/yyyy').format(DateTime.parse(expense['date']));

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
                    backgroundColor: const Color.fromRGBO(0, 255, 127, 1),
                    foregroundColor: const Color.fromARGB(255, 31, 34, 35),
                    icon: Icons.edit_rounded,
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  SlidableAction(
                    onPressed: (_) => onDeleteExpense(index),
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    icon: Icons.delete_outline_rounded,
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                ],
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.035),
                  borderRadius: BorderRadius.circular(16.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1), // Minimal shadow
                      blurRadius: 2,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 14.0,
                    horizontal: 25.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Expense Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              expense['item'],
                              style: const TextStyle(
                                fontFamily: 'ProductSans',
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1, // Restrict to a single line
                              overflow: TextOverflow
                                  .ellipsis, // Add ellipsis if text overflows
                            ),
                            const SizedBox(
                                height:
                                    8), // Increased space between name and date
                            Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today_outlined,
                                  size: 12,
                                  color: Colors.white54,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  formattedDate,
                                  style: const TextStyle(
                                    fontFamily: 'ProductSans',
                                    color: Colors.white54,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Expense Amount
                      Text(
                        '₹${expense['value'].toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontFamily: 'ProductSans',
                          color: Color.fromRGBO(0, 255, 127, 1),
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
