import 'package:flutter/material.dart';
import 'package:personal_finance/features/dashboard/domain/entities/dashboard_models.dart';
import 'package:personal_finance/features/transactions/domain/entities/transaction_backend.dart';
import 'package:personal_finance/features/transactions/domain/repositories/transaction_backend_repository.dart';

class TrendAnalyzerService {
  final TransactionBackendRepository _repository;

  TrendAnalyzerService(this._repository);

  Future<List<RecommendationItem>> analyzeTrends({String? profileType}) async {
    final now = DateTime.now();
    final twoMonthsAgoStart = DateTime(now.year, now.month - 2, 1);

    final result = await _repository.list(
      fechaDesde: twoMonthsAgoStart,
      fechaHasta: now,
      tipo: 'gasto',
      profileType: profileType,
    );

    return result.fold(
      (_) => [],
      (transactions) => _processTransactions(transactions, now),
    );
  }

  List<RecommendationItem> _processTransactions(
    List<TransactionBackend> transactions,
    DateTime now,
  ) {
    final List<RecommendationItem> trends = [];

    // Group transactions by month and category
    final Map<int, Map<String, double>> monthCategoryData = {};

    for (var tx in transactions) {
      final month = tx.fecha.month;
      final category =
          tx.categoriaId; // Assuming categoriaId is the label or id we want to track
      final amount = tx.montoAsDouble;

      monthCategoryData.putIfAbsent(month, () => {});
      monthCategoryData[month]![category] =
          (monthCategoryData[month]![category] ?? 0) + amount;
    }

    final currentMonth = now.month;
    final lastMonth = now.month - 1 <= 0 ? 12 + (now.month - 1) : now.month - 1;

    final currentData = monthCategoryData[currentMonth] ?? {};
    final lastMonthData = monthCategoryData[lastMonth] ?? {};

    currentData.forEach((category, currentAmount) {
      final lastAmount = lastMonthData[category] ?? 0;

      if (lastAmount > 0) {
        final increase = (currentAmount - lastAmount) / lastAmount;
        if (increase >= 0.20) {
          trends.add(
            RecommendationItem(
              icon: '📈',
              title: 'Aumento en $category',
              description:
                  'He notado que este mes tus gastos en "$category" han subido un ${(increase * 100).toStringAsFixed(0)}%. ¿Quieres crear una alerta de presupuesto?',
              actionLabel: 'Crear alerta',
              accentColor: Colors.orange,
              actionType: RecommendationActionType.createBudgetAlert,
              metadata: {'category': category, 'increase': increase},
            ),
          );
        }
      }
    });

    return trends;
  }
}
