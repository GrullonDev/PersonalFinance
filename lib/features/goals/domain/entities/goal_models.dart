import 'package:flutter/material.dart';

class SavingsGoal {
  final String id;
  final String title;
  final double targetAmount;
  final double currentAmount;
  final DateTime deadline;
  final String? imageUrl;
  final IconData icon;
  final Color color;
  final bool isLinkedToBudget;
  final bool isLinkedToDco;

  const SavingsGoal({
    required this.id,
    required this.title,
    required this.targetAmount,
    required this.currentAmount,
    required this.deadline,
    required this.icon, required this.color, this.imageUrl,
    this.isLinkedToBudget = false,
    this.isLinkedToDco = false,
  });

  double get progress => currentAmount / targetAmount;

  bool get isCompleted => currentAmount >= targetAmount;

  Duration get timeLeft => deadline.difference(DateTime.now());

  String get formattedTimeLeft {
    final int days = timeLeft.inDays;
    if (days > 365) {
      return '${(days / 365).floor()} años';
    } else if (days > 30) {
      return '${(days / 30).floor()} meses';
    } else {
      return '$days días';
    }
  }

  SavingsGoal copyWith({
    String? id,
    String? title,
    double? targetAmount,
    double? currentAmount,
    DateTime? deadline,
    String? imageUrl,
    IconData? icon,
    Color? color,
    bool? isLinkedToBudget,
    bool? isLinkedToDco,
  }) => SavingsGoal(
    id: id ?? this.id,
    title: title ?? this.title,
    targetAmount: targetAmount ?? this.targetAmount,
    currentAmount: currentAmount ?? this.currentAmount,
    deadline: deadline ?? this.deadline,
    imageUrl: imageUrl ?? this.imageUrl,
    icon: icon ?? this.icon,
    color: color ?? this.color,
    isLinkedToBudget: isLinkedToBudget ?? this.isLinkedToBudget,
    isLinkedToDco: isLinkedToDco ?? this.isLinkedToDco,
  );
}
