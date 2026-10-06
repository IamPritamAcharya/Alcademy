import 'package:port/shared/theme/app_style.dart';
import 'package:port/shared/widgets/app_bar_divider.dart';
import 'package:port/features/expenses/data/expenses_repository.dart';
import 'package:port/features/expenses/models/expense.dart';
import 'package:flutter/material.dart';

import 'package:port/features/expenses/presentation/dialogs/add_item_dialog.dart';
import 'package:port/features/expenses/presentation/dialogs/edit_item_dialog.dart';
import 'package:port/features/expenses/presentation/widgets/graph_section.dart';
import 'package:port/features/expenses/presentation/widgets/budget_section.dart';
import 'package:port/features/expenses/presentation/widgets/expense_list.dart';

class ExpenseTrackerPage extends StatefulWidget {
  const ExpenseTrackerPage({super.key});

  @override
  State<ExpenseTrackerPage> createState() => _ExpenseTrackerPageState();
}

class _ExpenseTrackerPageState extends State<ExpenseTrackerPage> {
  final _repository = ExpensesRepository();
  List<Map<String, dynamic>> expenses = [];
  double budget = 1000.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await _repository.load();
    if (!mounted) return;
    setState(() {
      expenses = data.expenses.map((expense) => expense.toJson()).toList();
      budget = data.budget;
    });
  }

  Future<void> _saveData() =>
      _repository.save(expenses.map(Expense.fromJson).toList(), budget);

  double _calculateTodaysExpenses() {
    final today = DateTime.now();
    return expenses
        .where((expense) {
          final expenseDate = DateTime.parse(expense['date']);
          return expenseDate.year == today.year &&
              expenseDate.month == today.month &&
              expenseDate.day == today.day;
        })
        .map((e) => e['value'] as double)
        .fold(0.0, (a, b) => a + b);
  }

  double _calculateLast7DaysExpenses() {
    final today = DateTime.now();
    final last7Days = today.subtract(const Duration(days: 7));

    return expenses
        .where((expense) {
          final expenseDate = DateTime.parse(expense['date']);
          return expenseDate.isAfter(last7Days) && expenseDate.isBefore(today);
        })
        .map((e) => e['value'] as double)
        .fold(0.0, (a, b) => a + b);
  }

  void _addExpense() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const AddItemDialog(),
    );

    if (result != null) {
      if (mounted) {
        setState(() {
          expenses.add(result);
        });
      }
      _saveData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyle.background,
      appBar: AppBar(
        title: const Text(
          'Expenses',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 22,
            color: AppStyle.text,
            fontWeight: FontWeight.bold,
            fontFamily: 'ProductSans',
            letterSpacing: -.5,
          ),
        ),
        bottom: const AppBarDivider(),
        iconTheme: const IconThemeData(color: AppStyle.text),
        centerTitle: false,
        backgroundColor: AppStyle.background,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: () {
              setState(() {
                expenses.clear();
              });
              _saveData();
            },
            color: AppStyle.text,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            GraphSection(expenses: expenses, budget: budget),
            BudgetSection(
              budget: budget,
              todaysExpense: _calculateTodaysExpenses(),
              last7DaysExpense: _calculateLast7DaysExpenses(),
              onUpdateBudget: (newBudget) async {
                setState(() {
                  budget = newBudget;
                });
                await _saveData();
              },
            ),
            const SizedBox(height: 10),
            ExpenseListSection(
              expenses: expenses,
              onEditExpense: (index) async {
                final expense = expenses[index];
                final result = await showDialog<Map<String, dynamic>>(
                  context: context,
                  builder: (context) => EditItemDialog(
                    initialItem: expense['item'],
                    initialValue: expense['value'],
                    initialDate: DateTime.parse(expense['date']),
                  ),
                );

                if (result != null) {
                  setState(() {
                    expenses[index] = result;
                  });
                  _saveData();
                }
              },
              onDeleteExpense: (index) {
                setState(() {
                  expenses.removeAt(index);
                });
                _saveData();
              },
            ),
            const SizedBox(height: 35),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addExpense,
        backgroundColor: AppStyle.accent,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }
}
