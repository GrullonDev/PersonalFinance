import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import 'package:personal_finance/features/dashboard/domain/entities/dashboard_models.dart';
import 'package:personal_finance/features/transactions/domain/repositories/transaction_backend_repository.dart';

class ReportsLogic extends ChangeNotifier {
  List<ChartData> _chartData = <ChartData>[];
  double _totalIncomes = 0;
  double _totalExpenses = 0;
  bool _loading = false;
  String? _error;
  bool _hasData = false;

  // Getters
  bool get hasData => _hasData;
  bool get isLoading => _loading;
  String? get error => _error;
  List<ChartData> get chartData => _chartData;
  double get totalIncomes => _totalIncomes;
  double get totalExpenses => _totalExpenses;

  // Private methods
  void _setLoading(bool loading) {
    _loading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() => _setError(null);

  static const List<Color> _chartColors = <Color>[
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.amber,
  ];

  // Public methods
  Future<void> loadReportData() async {
    _setLoading(true);
    _clearError();

    try {
      final repo = GetIt.instance<TransactionBackendRepository>();
      final result = await repo.list();

      result.fold(
        (failure) {
          _setError('Error al cargar datos: ${failure.message}');
        },
        (transactions) {
          _totalIncomes = transactions
              .where((tx) => tx.tipo == 'ingreso')
              .fold(0, (sum, tx) => sum + tx.montoAsDouble);

          _totalExpenses = transactions
              .where((tx) => tx.tipo == 'gasto')
              .fold(0, (sum, tx) => sum + tx.montoAsDouble);

          // Agrupar gastos por categoría
          final Map<String, double> categoryTotals = <String, double>{};
          for (final tx in transactions.where((tx) => tx.tipo == 'gasto')) {
            final String cat = tx.categoriaId.isNotEmpty ? tx.categoriaId : 'Otros';
            categoryTotals[cat] = (categoryTotals[cat] ?? 0.0) + tx.montoAsDouble;
          }

          // Ordenar de mayor a menor y construir ChartData
          final List<MapEntry<String, double>> sorted = categoryTotals.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          _chartData = sorted.indexed
              .map(
                (entry) => ChartData(
                  category: entry.$2.key,
                  amount: entry.$2.value,
                  color: _chartColors[entry.$1 % _chartColors.length],
                ),
              )
              .toList();

          _hasData = _chartData.isNotEmpty || _totalIncomes > 0;
          notifyListeners();
        },
      );
    } catch (e) {
      _setError('Error al cargar datos: $e');
    } finally {
      _setLoading(false);
    }
  }

  @override
  void dispose() {
    _chartData.clear();
    super.dispose();
  }
}
