import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import 'package:personal_finance/features/alerts/alert_item.dart';

class AlertsProvider extends ChangeNotifier {
  AlertsProvider() {
    _loadAlerts();
  }

  final Box<AlertItem> _alertBox = Hive.box<AlertItem>('alerts');
  final List<AlertItem> _alerts = <AlertItem>[];

  List<AlertItem> get alerts => List.unmodifiable(_alerts);

  void _loadAlerts() {
    _alerts
      ..clear()
      ..addAll(_alertBox.values);
  }

  Future<void> addAlert(AlertItem alert) async {
    await _alertBox.add(alert);
    _alerts.add(alert);
    notifyListeners();
  }
}
