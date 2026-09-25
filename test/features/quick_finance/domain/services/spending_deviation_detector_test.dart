import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance/core/constants/enums.dart';
import 'package:personal_finance/features/quick_finance/domain/entities/transaction_entity.dart';
import 'package:personal_finance/features/quick_finance/domain/services/spending_deviation_detector.dart';

int _seq = 0;

TransactionEntity tx(
  double amount,
  DateTime date, {
  TransactionType type = TransactionType.expense,
  String note = '',
  String? category,
  DateTime? deletedAt,
}) => TransactionEntity(
  id: '${_seq++}',
  userId: 'u1',
  type: type,
  amount: amount,
  note: note,
  categoryId: category,
  createdAt: date,
  updatedAt: date,
  deletedAt: deletedAt,
  syncStatus: SyncStatus.synced,
  version: 1,
  deviceId: 'd1',
);

/// Historial estable: 3 meses previos con comida=500 y transporte=300.
List<TransactionEntity> stableHistory(DateTime now) => [
  for (var i = 1; i <= 3; i++) ...[
    tx(500, DateTime(now.year, now.month - i, 10), category: 'comida'),
    tx(300, DateTime(now.year, now.month - i, 12), category: 'transporte'),
  ],
];

void main() {
  const detector = SpendingDeviationDetector();
  final now = DateTime(2026, 9, 20, 12);

  Iterable<SpendingDeviationType> types(List<SpendingDeviation> d) =>
      d.map((e) => e.type);

  test('sin gastos en el mes no hay desvíos', () {
    expect(detector.detect(stableHistory(now), now: now), isEmpty);
  });

  test('un mes normal no genera advertencias', () {
    final result = detector.detect([
      ...stableHistory(now),
      tx(400, DateTime(2026, 9, 5), category: 'comida'),
      tx(200, DateTime(2026, 9, 6), category: 'transporte'),
      tx(2000, DateTime(2026, 9), type: TransactionType.income),
    ], now: now);
    expect(result, isEmpty);
  });

  test('detecta una categoría disparada respecto a su promedio', () {
    final result = detector.detect(
      [
        ...stableHistory(now),
        tx(800, DateTime(2026, 9, 5), category: 'comida'),
      ],
      now: now,
      currencySymbol: 'Q',
    );

    final spike = result.firstWhere(
      (d) => d.type == SpendingDeviationType.categorySpike,
    );
    expect(spike.group, 'comida');
    expect(spike.key, 'categorySpike|2026-09|comida');
    expect(spike.body, contains('60%'));
    expect(spike.body, contains('Q800'));
  });

  test('detecta un gasto nuevo importante sin historial', () {
    final result = detector.detect([
      ...stableHistory(now),
      tx(200, DateTime(2026, 9, 3), category: 'apuestas'),
    ], now: now);
    expect(
      result.any(
        (d) =>
            d.type == SpendingDeviationType.categorySpike &&
            d.group == 'apuestas',
      ),
      isTrue,
    );
  });

  test('advierte cuando los gastos superan los ingresos del mes', () {
    final result = detector.detect([
      tx(1000, DateTime(2026, 9), type: TransactionType.income),
      tx(700, DateTime(2026, 9, 2), category: 'renta'),
      tx(500, DateTime(2026, 9, 3), category: 'comida'),
    ], now: now);
    expect(result.first.type, SpendingDeviationType.spendingAboveIncome);
    expect(result.first.severity, 3);
  });

  test('proyecta el ritmo del mes por encima del promedio', () {
    // Promedio 800/mes; al día 10 ya van 500 → proyección 1500.
    final day10 = DateTime(2026, 9, 10);
    final result = detector.detect([
      ...stableHistory(day10),
      tx(250, DateTime(2026, 9, 2), category: 'comida'),
      tx(250, DateTime(2026, 9, 4), category: 'transporte'),
    ], now: day10);
    expect(
      types(result),
      contains(SpendingDeviationType.monthlyPaceAboveAverage),
    );
  });

  test('no proyecta el ritmo en los primeros días del mes', () {
    final day3 = DateTime(2026, 9, 3);
    final result = detector.detect([
      ...stableHistory(day3),
      tx(300, DateTime(2026, 9, 2), category: 'comida'),
    ], now: day3);
    expect(
      types(result),
      isNot(contains(SpendingDeviationType.monthlyPaceAboveAverage)),
    );
  });

  test('detecta gastos hormiga', () {
    final result = detector.detect([
      ...stableHistory(now),
      for (var d = 1; d <= 10; d++) tx(12, DateTime(2026, 9, d), note: 'café'),
      tx(300, DateTime(2026, 9, 2), category: 'comida'),
    ], now: now);
    final ant = result.firstWhere(
      (d) => d.type == SpendingDeviationType.antExpenses,
    );
    expect(ant.body, contains('10 gastos pequeños'));
  });

  test('detecta concentración del gasto en un solo concepto', () {
    final result = detector.detect([
      tx(900, DateTime(2026, 9), category: 'renta'),
      tx(50, DateTime(2026, 9, 2), category: 'comida'),
      tx(50, DateTime(2026, 9, 3), category: 'comida'),
      tx(50, DateTime(2026, 9, 4), category: 'transporte'),
      tx(50, DateTime(2026, 9, 5), category: 'transporte'),
    ], now: now);
    final c = result.firstWhere(
      (d) => d.type == SpendingDeviationType.categoryConcentration,
    );
    expect(c.group, 'renta');
  });

  test('agrupa por nota cuando no hay categoría e ignora borrados', () {
    expect(
      SpendingDeviationDetector.groupOf(tx(1, now, note: '  Uber   Eats ')),
      'uber eats',
    );
    final result = detector.detect([
      ...stableHistory(now),
      tx(5000, DateTime(2026, 9, 5), category: 'comida', deletedAt: now),
    ], now: now);
    expect(result, isEmpty);
  });

  test('ordena por severidad', () {
    final result = detector.detect([
      ...stableHistory(now),
      tx(500, DateTime(2026, 9), type: TransactionType.income),
      tx(1200, DateTime(2026, 9, 5), category: 'comida'),
    ], now: now);
    final severities = result.map((d) => d.severity).toList();
    expect(severities, [...severities]..sort((a, b) => b.compareTo(a)));
    expect(result.first.type, SpendingDeviationType.spendingAboveIncome);
  });
}
