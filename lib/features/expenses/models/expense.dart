class Expense {
  final String item;
  final double amount;
  final DateTime date;
  const Expense({required this.item, required this.amount, required this.date});

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
      item: json['item'] as String,
      amount: (json['value'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String));

  Map<String, dynamic> toJson() =>
      {'item': item, 'value': amount, 'date': date.toIso8601String()};
}
