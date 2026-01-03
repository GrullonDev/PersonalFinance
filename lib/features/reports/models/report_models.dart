class ReportData {
  final String title;
  final double amount;
  final DateTime date;

  const ReportData({
    required this.title,
    required this.amount,
    required this.date,
  });
}

class ReportSummary {
  final double totalIncome;
  final double totalExpenses;
  final double balance;
  final Map<String, double> categoryDistribution;

  const ReportSummary({
    required this.totalIncome,
    required this.totalExpenses,
    required this.balance,
    required this.categoryDistribution,
  });
}
