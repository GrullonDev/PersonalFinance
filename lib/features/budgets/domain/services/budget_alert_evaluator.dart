import 'package:personal_finance/core/constants/enums.dart';
import 'package:personal_finance/features/budgets/domain/entities/budget.dart';
import 'package:personal_finance/features/quick_finance/domain/entities/transaction_entity.dart';
import 'package:personal_finance/features/quick_finance/domain/services/transaction_categorizer.dart';

/// Aviso de que un gasto empujó un presupuesto a un umbral.
class BudgetAlert {
  const BudgetAlert({
    required this.budget,
    required this.spent,
    required this.limit,
    required this.threshold,
  });

  final Budget budget;
  final double spent;
  final double limit;

  /// Porcentaje cruzado (80 o 100).
  final int threshold;

  double get percent => limit <= 0 ? 0 : spent / limit * 100;

  bool get exceeded => threshold >= 100;

  /// Clave para avisar una sola vez por presupuesto, umbral y periodo.
  String get key =>
      '${budget.id}|$threshold|${budget.fechaInicio.millisecondsSinceEpoch}';
}

/// Calcula qué presupuestos afecta un gasto nuevo y si cruzó un umbral.
///
/// Un presupuesto con categorías vinculadas sólo suma esos gastos; sin
/// categorías suma todos los gastos del periodo (presupuesto general).
class BudgetAlertEvaluator {
  const BudgetAlertEvaluator();

  /// Presupuestos vigentes a los que pertenece [expense].
  List<Budget> budgetsFor(
    TransactionEntity expense,
    List<Budget> budgets,
    Map<String, Set<String>> categoryKeysByBudget,
  ) {
    if (expense.type != TransactionType.expense) return const [];
    return budgets
        .where(
          (b) =>
              b.deletedAt == null &&
              _inPeriod(expense.createdAt, b) &&
              _belongs(expense, categoryKeysByBudget[b.id]),
        )
        .toList();
  }

  /// Umbrales que [expense] hizo cruzar. [thresholds] en porcentaje, p. ej.
  /// `[80, 100]` (Pro) o `[100]` (gratis). Sólo se devuelve el más alto.
  List<BudgetAlert> evaluate({
    required TransactionEntity expense,
    required List<Budget> budgets,
    required Map<String, Set<String>> categoryKeysByBudget,
    required List<TransactionEntity> transactions,
    List<int> thresholds = const [100],
  }) {
    final alerts = <BudgetAlert>[];
    for (final budget in budgetsFor(expense, budgets, categoryKeysByBudget)) {
      final limit = double.tryParse(budget.montoTotal) ?? 0;
      if (limit <= 0) continue;
      final keys = categoryKeysByBudget[budget.id];

      var spent = 0.0;
      var counted = false;
      for (final t in transactions) {
        if (t.deletedAt != null || t.type != TransactionType.expense) continue;
        if (!_inPeriod(t.createdAt, budget) || !_belongs(t, keys)) continue;
        if (t.id == expense.id) counted = true;
        spent += t.amount;
      }
      // El gasto recién guardado puede no haber llegado aún al listado.
      if (!counted) spent += expense.amount;
      final before = spent - expense.amount;

      final crossed =
          thresholds
              .where(
                (p) => before < limit * p / 100 && spent >= limit * p / 100,
              )
              .toList();
      if (crossed.isEmpty) continue;
      alerts.add(
        BudgetAlert(
          budget: budget,
          spent: spent,
          limit: limit,
          threshold: crossed.reduce((a, b) => a > b ? a : b),
        ),
      );
    }
    return alerts;
  }

  /// Claves con las que se reconocen los gastos de las categorías
  /// vinculadas: el id guardado y su nombre normalizado.
  static Set<String> keysFor(
    List<String> linkedIds, {
    Map<String, String> categoryNamesById = const {},
  }) {
    final keys = <String>{};
    for (final id in linkedIds) {
      keys.add(TransactionCategorizer.normalize(id) ?? id);
      keys.add(id);
      final name = categoryNamesById[id];
      if (name != null) {
        keys.add(TransactionCategorizer.normalize(name) ?? name.toLowerCase());
      }
    }
    return keys;
  }

  static bool _inPeriod(DateTime date, Budget b) {
    final start = DateTime(
      b.fechaInicio.year,
      b.fechaInicio.month,
      b.fechaInicio.day,
    );
    final end = DateTime(b.fechaFin.year, b.fechaFin.month, b.fechaFin.day + 1);
    return !date.isBefore(start) && date.isBefore(end);
  }

  static bool _belongs(TransactionEntity t, Set<String>? keys) {
    if (keys == null || keys.isEmpty) return true;
    final category = t.categoryId;
    if (category == null || category.isEmpty) return false;
    return keys.contains(category) ||
        keys.contains(TransactionCategorizer.normalize(category));
  }
}
