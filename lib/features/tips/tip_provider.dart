import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:personal_finance/core/services/vertex_ai_service.dart';

class TipProvider extends ChangeNotifier {
  TipProvider() {
    _loadTip();
  }

  static const List<String> _fallbacks = [
    'Ahorra al menos el 10% de cada ingreso que recibas.',
    'Registra tus gastos diariamente para detectar hábitos.',
    'Establece metas de ahorro mensuales realistas.',
    'Evita compras impulsivas esperando 24 horas antes de decidir.',
    'Revisa tus suscripciones y cancela las que no uses.',
  ];

  String _tip = '';
  bool _isLoading = false;

  String get todayTip =>
      _tip.isNotEmpty
          ? _tip
          : _fallbacks[DateTime.now().day % _fallbacks.length];
  bool get isLoading => _isLoading;

  Future<void> _loadTip() async {
    _isLoading = true;
    notifyListeners();
    try {
      final service = GetIt.instance<VertexAiService>();
      // Sin contexto de transacciones devuelve un consejo general personalizado
      _tip = await service.getPersonalizedTip([], []);
    } catch (e) {
      developer.log('TipProvider: error cargando consejo Gemini: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fuerza recargar un nuevo consejo desde Gemini.
  Future<void> refresh() => _loadTip();
}
