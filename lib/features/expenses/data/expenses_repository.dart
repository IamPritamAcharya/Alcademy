import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/storage/preferences_cache.dart';
import '../models/expense.dart';

class ExpenseData {
  final List<Expense> expenses;
  final double budget;
  const ExpenseData({required this.expenses, required this.budget});
}

class ExpensesRepository {
  Future<ExpenseData> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = PreferencesCache(prefs).readJson('expenses');
    final expenses = <Expense>[];
    if (saved is List) {
      for (final item in saved) {
        try {
          expenses
              .add(Expense.fromJson(Map<String, dynamic>.from(item as Map)));
        } on FormatException {
          // A malformed entry should not hide the user's other expenses.
        } on TypeError {
          // Skip incompatible legacy entries.
        }
      }
    }
    return ExpenseData(
        expenses: expenses, budget: prefs.getDouble('budget') ?? 1000);
  }

  Future<void> save(List<Expense> expenses, double budget) async {
    final prefs = await SharedPreferences.getInstance();
    await PreferencesCache(prefs).writeJson(
        'expenses', expenses.map((expense) => expense.toJson()).toList());
    await prefs.setDouble('budget', budget);
  }
}
