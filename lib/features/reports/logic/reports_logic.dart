import 'package:flutter/material.dart';
import 'package:personal_finance/features/dashboard/logic/dashboard_models.dart';

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

  // Public methods
  Future<void> loadReportData() async {
    _setLoading(true);
    _clearError();

    try {
      // TODO: Implementar lógica para cargar datos del reporte
      // Por ahora usaremos datos de prueba
      _chartData = <ChartData>[
        ChartData(category: 'Alimentación', amount: 1200, color: Colors.blue),
        ChartData(category: 'Transporte', amount: 800, color: Colors.red),
        ChartData(
          category: 'Entretenimiento',
          amount: 500,
          color: Colors.green,
        ),
        ChartData(category: 'Servicios', amount: 900, color: Colors.orange),
        ChartData(category: 'Otros', amount: 300, color: Colors.purple),
      ];

      _totalIncomes = 5000;
      _totalExpenses = 3700;
      _hasData = true;

      notifyListeners();
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
