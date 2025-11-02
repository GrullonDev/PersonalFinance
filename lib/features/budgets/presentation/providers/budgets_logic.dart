import 'package:flutter/material.dart';
import 'package:personal_finance/features/budgets/domain/entities/budget_models.dart';

class BudgetsLogic extends ChangeNotifier {
  BudgetSummary summary = const BudgetSummary(
    incomes: 2500,
    expenses: 1800,
    incomesChange: 0.10,
    expensesChange: -0.05,
  );

  List<BudgetCategory> categories = const <BudgetCategory>[
    BudgetCategory(
      name: 'Comida',
      color: Color(0xFF2196F3),
      spent: 720,
      limit: 1000,
    ),
    BudgetCategory(
      name: 'Transporte',
      color: Color(0xFFE91E63),
      spent: 540,
      limit: 800,
    ),
    BudgetCategory(
      name: 'Ocio',
      color: Color(0xFF9C27B0),
      spent: 360,
      limit: 600,
    ),
    BudgetCategory(
      name: 'Otros',
      color: Color(0xFF00BCD4),
      spent: 180,
      limit: 400,
    ),
  ];

  List<UserBudget> budgets = const <UserBudget>[
    UserBudget(
      name: 'Gastos Mensuales',
      spent: 1800,
      limit: 2400,
      color: Color(0xFF03A9F4),
      icon: Icons.attach_money,
    ),
    UserBudget(
      name: 'Viaje a Europa',
      spent: 1500,
      limit: 3000,
      color: Color(0xFF9C27B0),
      icon: Icons.flight,
    ),
    UserBudget(
      name: 'Nuevo Portátil',
      spent: 400,
      limit: 1600,
      color: Color(0xFFE91E63),
      icon: Icons.laptop_mac,
    ),
  ];

  List<BudgetAlert> alerts = <BudgetAlert>[
    const BudgetAlert(category: 'Comida', threshold: 90, enabled: true),
    const BudgetAlert(category: 'Transporte', threshold: 85, enabled: false),
    const BudgetAlert(category: 'Ocio', threshold: 95, enabled: true),
  ];

  void toggleAlert(String category, {required bool isEnabled}) {
    final int idx = alerts.indexWhere(
      (BudgetAlert a) => a.category == category,
    );
    if (idx != -1) {
      alerts[idx] = BudgetAlert(
        category: alerts[idx].category,
        threshold: alerts[idx].threshold,
        enabled: isEnabled,
      );
      notifyListeners();
    }
  }

  void editAlert(String category, int newThreshold) {
    final int idx = alerts.indexWhere(
      (BudgetAlert a) => a.category == category,
    );
    if (idx != -1) {
      alerts[idx] = BudgetAlert(
        category: alerts[idx].category,
        threshold: newThreshold,
        enabled: alerts[idx].enabled,
      );
      notifyListeners();
    }
  }
}
