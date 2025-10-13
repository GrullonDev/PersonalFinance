import 'package:flutter/material.dart';

import 'package:personal_finance/features/goals/models/goal_models.dart';

class GoalsLogic extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  List<SavingsGoal> _goals = <SavingsGoal>[];
  bool _notificationsEnabled = true;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<SavingsGoal> get goals => _goals;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get hasGoals => _goals.isNotEmpty;

  // Para demostración, inicializamos con datos de ejemplo
  Future<void> loadGoals() async {
    _setLoading(true);
    try {
      // Simular carga de datos
      await Future<void>.delayed(const Duration(milliseconds: 800));
      _goals = <SavingsGoal>[
        SavingsGoal(
          id: '1',
          title: 'Viaje a Europa',
          targetAmount: 45000,
          currentAmount: 22500,
          deadline: DateTime.now().add(const Duration(days: 365)),
          icon: Icons.flight,
          color: const Color(0xFF9C27B0),
        ),
        SavingsGoal(
          id: '2',
          title: 'Nueva Laptop',
          targetAmount: 30000,
          currentAmount: 21000,
          deadline: DateTime.now().add(const Duration(days: 180)),
          icon: Icons.laptop_mac,
          color: const Color(0xFF1976D2),
        ),
        SavingsGoal(
          id: '3',
          title: 'Fondo de Emergencia',
          targetAmount: 50000,
          currentAmount: 15000,
          deadline: DateTime.now().add(const Duration(days: 730)),
          icon: Icons.health_and_safety,
          color: const Color(0xFF4CAF50),
        ),
      ];
      _setError(null);
    } catch (e) {
      _setError('Error al cargar las metas: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> toggleNotifications() async {
    _notificationsEnabled = !_notificationsEnabled;
    notifyListeners();
  }

  Future<void> addGoal(SavingsGoal goal) async {
    _setLoading(true);
    try {
      // TODO: Implementar lógica para agregar meta
      _goals.add(goal);
      notifyListeners();
    } catch (e) {
      _setError('Error al agregar meta: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateGoal(SavingsGoal goal) async {
    _setLoading(true);
    try {
      final int index = _goals.indexWhere((SavingsGoal g) => g.id == goal.id);
      if (index != -1) {
        _goals[index] = goal;
        notifyListeners();
      }
    } catch (e) {
      _setError('Error al actualizar meta: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteGoal(String id) async {
    _setLoading(true);
    try {
      _goals.removeWhere((SavingsGoal goal) => goal.id == id);
      notifyListeners();
    } catch (e) {
      _setError('Error al eliminar meta: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Métodos privados
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? value) {
    _error = value;
    if (value != null) {
      notifyListeners();
    }
  }
}
