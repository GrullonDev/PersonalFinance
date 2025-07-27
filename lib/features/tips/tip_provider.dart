import 'dart:math';

import 'package:flutter/material.dart';

/// Simple provider to deliver daily financial tips.
class TipProvider extends ChangeNotifier {
  TipProvider();

  final List<String> _tips = <String>[
    'Ahorra al menos el 10% de cada ingreso que recibas.',
    'Registra tus gastos diariamente para detectar hábitos.',
    'Establece metas de ahorro mensuales realistas.',
    'Evita compras impulsivas esperando 24 horas antes de decidir.',
    'Revisa tus suscripciones y cancela las que no uses.',
  ];

  late final String _todayTip =
      _tips[Random(DateTime.now().day).nextInt(_tips.length)];

  String get todayTip => _todayTip;
}
