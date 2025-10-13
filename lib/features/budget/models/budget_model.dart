class Budget {
  String title;
  double amount;
  double spent;
  DateTime startDate;
  DateTime endDate;
  String period; // 'semanal', 'mensual'

  Budget({
    required this.title,
    required this.amount,
    required this.startDate,
    required this.endDate,
    this.spent = 0.0,
    this.period = 'semanal',
  });

  double get percentage =>
      amount > 0 ? (spent / amount * 100).clamp(0, 100) : 0;

  double get remaining => amount - spent;

  bool get isOverBudget => spent > amount;

  String get percentageString => '${percentage.toInt()}%';
}
