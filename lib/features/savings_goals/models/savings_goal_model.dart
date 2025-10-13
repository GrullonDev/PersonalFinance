class SavingsGoal {
  String title;
  double targetAmount;
  double currentAmount;
  String imageUrl;
  String emoji;
  DateTime createdAt;
  DateTime? targetDate;

  SavingsGoal({
    required this.title,
    required this.targetAmount,
    required this.createdAt,
    this.currentAmount = 0.0,
    this.imageUrl = '',
    this.emoji = '🎯',
    this.targetDate,
  });

  double get percentage =>
      targetAmount > 0 ? (currentAmount / targetAmount * 100).clamp(0, 100) : 0;

  double get remaining => targetAmount - currentAmount;

  bool get isCompleted => currentAmount >= targetAmount;

  String get percentageString => '${percentage.toInt()}%';

  String get progressText =>
      '\$${currentAmount.toStringAsFixed(0)} / \$${targetAmount.toStringAsFixed(0)}';
}
