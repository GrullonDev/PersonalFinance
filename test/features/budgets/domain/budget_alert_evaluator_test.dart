import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance/core/constants/enums.dart';
import 'package:personal_finance/features/budgets/domain/entities/budget.dart';
import 'package:personal_finance/features/budgets/domain/services/budget_alert_evaluator.dart';
import 'package:personal_finance/features/quick_finance/domain/entities/transaction_entity.dart';

Budget _budget(String id, String name, String amount) => Budget(
  id: id,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
  deviceId: 'test',
  version: 1,
  nombre: name,
  montoTotal: amount,
  fechaInicio: DateTime(2026, 10),
  fechaFin: DateTime(2026, 10, 31),
);

TransactionEntity _tx(
  String id,
  double amount, {
  String? category,
  DateTime? at,
  TransactionType type = TransactionType.expense,
}) => TransactionEntity(
  id: id,
  userId: 'u',
  type: type,
  amount: amount,
  note: 'x',
  categoryId: category,
  createdAt: at ?? DateTime(2026, 10, 15),
  updatedAt: DateTime(2026, 10, 15),
  syncStatus: SyncStatus.pending,
  version: 1,
  deviceId: 'd',
);

void main() {
  const evaluator = BudgetAlertEvaluator();
  final comida = _budget('b1', 'Comida', '1000');
  final general = _budget('b2', 'Mensual', '5000');
  final keys = {
    'b1': BudgetAlertEvaluator.keysFor(['comida']),
    'b2': <String>{},
  };

  test('el gasto pertenece al presupuesto de su categoría y al general', () {
    final tx = _tx('t', 50, category: 'comida');
    expect(evaluator.budgetsFor(tx, [comida, general], keys), [
      comida,
      general,
    ]);
    final other = _tx('o', 50, category: 'transporte');
    expect(evaluator.budgetsFor(other, [comida, general], keys), [general]);
  });

  test('fuera del periodo no cuenta', () {
    final tx = _tx('t', 50, category: 'comida', at: DateTime(2026, 11, 1));
    expect(evaluator.budgetsFor(tx, [comida], keys), isEmpty);
  });

  test('avisa al cruzar el 100 %', () {
    final history = [_tx('a', 900, category: 'comida')];
    final tx = _tx('t', 150, category: 'comida');
    final alerts = evaluator.evaluate(
      expense: tx,
      budgets: [comida],
      categoryKeysByBudget: keys,
      transactions: [...history, tx],
    );
    expect(alerts.single.threshold, 100);
    expect(alerts.single.spent, 1050);
    expect(alerts.single.exceeded, isTrue);
  });

  test('con Pro avisa al 80 %; sin Pro no', () {
    final history = [_tx('a', 700, category: 'comida')];
    final tx = _tx('t', 120, category: 'comida');
    final pro = evaluator.evaluate(
      expense: tx,
      budgets: [comida],
      categoryKeysByBudget: keys,
      transactions: history,
      thresholds: const [80, 100],
    );
    expect(pro.single.threshold, 80);
    expect(pro.single.spent, 820);

    final free = evaluator.evaluate(
      expense: tx,
      budgets: [comida],
      categoryKeysByBudget: keys,
      transactions: history,
    );
    expect(free, isEmpty);
  });

  test('no repite si ya estaba sobre el umbral', () {
    final history = [_tx('a', 1200, category: 'comida')];
    final tx = _tx('t', 10, category: 'comida');
    expect(
      evaluator.evaluate(
        expense: tx,
        budgets: [comida],
        categoryKeysByBudget: keys,
        transactions: history,
      ),
      isEmpty,
    );
  });

  test('los ingresos no generan alertas', () {
    final tx = _tx('t', 5000, type: TransactionType.income);
    expect(
      evaluator.evaluate(
        expense: tx,
        budgets: [general],
        categoryKeysByBudget: keys,
        transactions: const [],
      ),
      isEmpty,
    );
  });
}
