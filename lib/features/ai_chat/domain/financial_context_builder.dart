import 'package:personal_finance/core/constants/enums.dart';
import 'package:personal_finance/features/quick_finance/domain/entities/transaction_entity.dart';
import 'package:personal_finance/features/quick_finance/domain/services/transaction_categorizer.dart';

/// Resume los movimientos del mes para que la IA responda con los números
/// reales del usuario en lugar de consejos genéricos.
class FinancialContextBuilder {
  const FinancialContextBuilder();

  String? build(
    List<TransactionEntity> transactions, {
    required String currencySymbol,
    DateTime? now,
  }) {
    final today = now ?? DateTime.now();
    final month =
        transactions
            .where(
              (t) =>
                  t.deletedAt == null &&
                  t.createdAt.year == today.year &&
                  t.createdAt.month == today.month,
            )
            .toList();
    if (month.isEmpty) return null;

    double income = 0;
    double expenses = 0;
    final byCategory = <String, double>{};
    for (final t in month) {
      if (t.type == TransactionType.income) {
        income += t.amount;
      } else {
        expenses += t.amount;
        final category = TransactionCategorizer.displayName(
          TransactionCategorizer.normalize(t.categoryId) ?? 'sin_categoria',
        );
        byCategory[category] = (byCategory[category] ?? 0) + t.amount;
      }
    }

    String money(double v) => '$currencySymbol${v.toStringAsFixed(2)}';
    final top =
        byCategory.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final topText = top
        .take(5)
        .map((e) {
          final pct = expenses > 0 ? (e.value / expenses * 100).round() : 0;
          return '${e.key} ${money(e.value)} ($pct%)';
        })
        .join(', ');

    return [
      'Datos del usuario en el mes actual (día ${today.day}):',
      'Ingresos: ${money(income)}.',
      'Gastos: ${money(expenses)} en ${month.length - month.where((t) => t.type == TransactionType.income).length} movimientos.',
      'Balance: ${money(income - expenses)}.',
      if (topText.isNotEmpty) 'Gastos por categoría: $topText.',
    ].join('\n');
  }
}
