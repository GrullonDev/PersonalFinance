import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import 'package:personal_finance/features/alerts/domain/entities/alert_item.dart';

class AlertsLogic extends ChangeNotifier {
  List<AlertItem> _alerts = <AlertItem>[];
  bool _loading = false;
  String? _error;

  // Getters
  List<AlertItem> get alerts => _alerts;
  bool get isLoading => _loading;
  String? get error => _error;
  bool get hasAlerts => _alerts.isNotEmpty;

  Box<AlertItem> get _alertBox => Hive.box<AlertItem>('alerts');

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
      _alerts = _alertBox.values.toList();
      notifyListeners();
    } catch (e) {
      _setError('Error al cargar alertas: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addAlert(AlertItem alert) async {
    try {
      await _alertBox.add(alert);
      _alerts = _alertBox.values.toList();
      notifyListeners();
    } catch (e) {
      _setError('Error al agregar alerta: $e');
    }
  }

  Future<void> removeAlert(AlertItem alert) async {
    try {
      final int? key = _alertBox.keys.cast<int?>().firstWhere(
        (k) => _alertBox.get(k) == alert,
        orElse: () => null,
      );
      if (key != null) {
        await _alertBox.delete(key);
      }
      _alerts = _alertBox.values.toList();
      notifyListeners();
    } catch (e) {
      _setError('Error al eliminar alerta: $e');
    }
  }
}
