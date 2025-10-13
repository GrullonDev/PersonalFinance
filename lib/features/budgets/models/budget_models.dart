import 'package:flutter/material.dart';

class BudgetCategory {
  final String name;
  final Color color;
  final double spent;
  final double limit;

  const BudgetCategory({
    required this.name,
    required this.color,
    required this.spent,
    required this.limit,
  });
}

class BudgetAlert {
  final String category;
  final int threshold;
  final bool enabled;

  const BudgetAlert({
    required this.category,
    required this.threshold,
    required this.enabled,
  });
}

class BudgetSummary {
  final double incomes;
  final double expenses;
  final double incomesChange;
  final double expensesChange;

  const BudgetSummary({
    required this.incomes,
    required this.expenses,
    required this.incomesChange,
    required this.expensesChange,
  });
}

class UserBudget {
  final String name;
  final double spent;
  final double limit;
  final Color color;
  final IconData icon;

  const UserBudget({
    required this.name,
    required this.spent,
    required this.limit,
    required this.color,
    required this.icon,
  });

  double get percent => limit == 0 ? 0 : spent / limit;
}
