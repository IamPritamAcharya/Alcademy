import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'dialogs/add_item_dialog.dart';
import 'dialogs/budget_dialog.dart';
import 'dialogs/edit_item_dialog.dart';
import 'widgets/bar_chart_section.dart';
import 'widgets/budget_section.dart';
import 'widgets/expense_list.dart';
import 'widgets/pie_chart_section.dart';

class ExpenseTrackerPage extends StatefulWidget {
  const ExpenseTrackerPage({Key? key}) : super(key: key);

  @override
  State<ExpenseTrackerPage> createState() => _ExpenseTrackerPageState();
}

class _ExpenseTrackerPageState extends State<ExpenseTrackerPage> {
  List<Map<String, dynamic>> expenses = [];
  double budget = 1000.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedExpenses = prefs.getString('expenses') ?? '[]';
    final savedBudget = prefs.getDouble('budget') ?? 1000.0;

    setState(() {
      expenses = List<Map<String, dynamic>>.from(jsonDecode(savedExpenses));
      budget = savedBudget;
    });
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('expenses', jsonEncode(expenses));
    await prefs.setDouble('budget', budget);
  }

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
      setState(() {
        expenses.add(result);
      });
      _saveData();
    }
  }

  void _editBudget() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => BudgetSection(
          budget: budget,
          todaysExpense: _calculateTodaysExpenses(),
          last7DaysExpense: _calculateLast7DaysExpenses(),
          onUpdateBudget: (newBudget) async {
            final updatedBudget = await showDialog<double>(
              context: context,
              builder: (context) => BudgetDialog(initialBudget: budget),
            );

            if (updatedBudget != null) {
              setState(() {
                budget = updatedBudget;
              });
              await _saveData(); // Save the updated budget
            }
          },
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const curve = Curves.easeOutBack;
          var curvedAnimation =
              CurvedAnimation(parent: animation, curve: curve);

          return ScaleTransition(
            scale: curvedAnimation,
            alignment: Alignment.center,
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1D1E),
      appBar: AppBar(
        title: const Text(
          'EXPENSES',
          style: TextStyle(
              fontSize: 24,
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontFamily: 'ProductSans',
              letterSpacing: 4),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.white.withOpacity(0.2),
            height: 1,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        backgroundColor: const Color(0xFF1A1D1E),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: () {
              setState(() {
                expenses.clear();
              });
              _saveData();
            },
            color: Colors.white,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: 250,
              child: PageView(
                children: [
                  PieChartSection(expenses: expenses, budget: budget),
                  BarChartSection(expenses: expenses),
                ],
              ),
            ),
            BudgetSection(
              budget: budget,
              todaysExpense: _calculateTodaysExpenses(),
              last7DaysExpense: _calculateLast7DaysExpenses(),
              onUpdateBudget: (newBudget) async {
                setState(() {
                  budget = newBudget;
                });
                await _saveData(); // Save the updated budget
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
        backgroundColor: const Color.fromRGBO(0, 255, 127, 1),
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }
}
