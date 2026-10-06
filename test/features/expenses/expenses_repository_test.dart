import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:port/features/expenses/data/expenses_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
      'Existing integer amounts load and malformed entries preserve valid expenses',
      () async {
    SharedPreferences.setMockInitialValues({
      'expenses':
          '[{"item":"Lunch","value":30,"date":"2026-10-06T12:00:00.000"},{"item":"Invalid"}]',
      'budget': 1500.0,
    });
    final repository = ExpensesRepository();
    final data = await repository.load();
    expect(data.expenses.single.item, 'Lunch');
    expect(data.expenses.single.amount, 30.0);
    expect(data.budget, 1500.0);
    await repository.save(data.expenses, data.budget);
    final prefs = await SharedPreferences.getInstance();
    final saved = jsonDecode(prefs.getString('expenses')!) as List;
    expect(saved.single['value'], 30.0);
    expect(saved.single['date'], '2026-10-06T12:00:00.000');
    expect(prefs.getDouble('budget'), 1500.0);
  });
}
