import 'package:flutter/material.dart';

class TransactionType {
  static const String expense = 'expense';
  static const String income = 'income';
}

class AddTransactionLogic extends ChangeNotifier {
  // Exponer método público para limpiar errores
  void clearError() => _clearError();
  bool _loading = false;
  String? _error;

  // Getters
  bool get isLoading => _loading;
  String? get error => _error;

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
  Future<void> addTransaction(Map<String, dynamic> data, String type) async {
    _setLoading(true);
    _clearError();

    try {
      // TODO: Implementar guardado de transacción
      await Future<void>.delayed(const Duration(seconds: 1)); // Simulación
      notifyListeners();
    } catch (e) {
      _setError(
        'Error al agregar ${type == TransactionType.expense ? 'gasto' : 'ingreso'}: $e',
      );
    } finally {
      _setLoading(false);
    }
  }
}
