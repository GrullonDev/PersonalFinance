import 'package:flutter/material.dart';

import 'package:personal_finance/features/alerts/alert_item.dart';

class AlertsLogic extends ChangeNotifier {
  List<AlertItem> _alerts = <AlertItem>[];
  bool _loading = false;
  String? _error;

  // Getters
  List<AlertItem> get alerts => _alerts;
  bool get isLoading => _loading;
  String? get error => _error;
  bool get hasAlerts => _alerts.isNotEmpty;

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
  Future<void> loadAlerts() async {
    _setLoading(true);
    _clearError();

    try {
      // TODO: Implementar carga de alertas desde la base de datos
      _alerts = <AlertItem>[];
      notifyListeners();
    } catch (e) {
      _setError('Error al cargar alertas: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addAlert(AlertItem alert) async {
    try {
      // TODO: Implementar guardado de alerta en la base de datos
      _alerts.add(alert);
      notifyListeners();
    } catch (e) {
      _setError('Error al agregar alerta: $e');
    }
  }

  Future<void> removeAlert(AlertItem alert) async {
    try {
      // TODO: Implementar eliminación de alerta de la base de datos
      _alerts.remove(alert);
      notifyListeners();
    } catch (e) {
      _setError('Error al eliminar alerta: $e');
    }
  }
}
