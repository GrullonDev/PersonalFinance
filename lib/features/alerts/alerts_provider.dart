import 'package:flutter/material.dart';

import 'alert_item.dart';

class AlertsProvider extends ChangeNotifier {
  final List<AlertItem> _alerts = <AlertItem>[
    AlertItem(
      title: 'Pago de tarjeta',
      description: 'La fecha límite es el 5 de cada mes.',
      date: DateTime.now(),
    ),
    AlertItem(
      title: 'Recordatorio de ahorro',
      description: 'Ahorra al menos el 10% de tu salario.',
      date: DateTime.now(),
    ),
  ];

  List<AlertItem> get alerts => List.unmodifiable(_alerts);
}
