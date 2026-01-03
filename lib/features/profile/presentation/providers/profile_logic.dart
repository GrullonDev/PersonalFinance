import 'package:flutter/material.dart';

import 'package:personal_finance/features/profile/domain/entities/user_profile.dart';

enum ActivityType { expense, income, goal, budget }

class ActivityItem {
  ActivityItem({
    required this.title,
    required this.amount,
    required this.timestamp,
    required this.type,
    this.description,
  });

  final String title;
  final String? description;
  final double amount;
  final DateTime timestamp;
  final ActivityType type;
}

class ProfileLogic extends ChangeNotifier {
  UserProfile? _profile;
  bool _isLoading = false;
  String? _error;
  List<ActivityItem> _recentActivity = <ActivityItem>[];

  UserProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<ActivityItem> get recentActivity => _recentActivity;

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() => _setError(null);

  Future<void> updateProfile({String? name, String? email}) async {
    _isLoading = true;
    _clearError();
    notifyListeners();

    try {
      // TODO: Implementar actualización real del perfil en el backend
      await Future<void>.delayed(const Duration(seconds: 1));

      if (_profile != null) {
        final String resolvedName = name ?? _profile!.name;
        final List<String> nameParts = resolvedName.trim().split(' ');
        final String updatedFirstName =
            nameParts.isNotEmpty ? nameParts.first : _profile!.firstName;
        final String updatedLastName =
            nameParts.length > 1
                ? nameParts.sublist(1).join(' ')
                : _profile!.lastName;

        _profile = _profile!.copyWith(
          firstName: updatedFirstName,
          lastName: updatedLastName,
          email: email ?? _profile!.email,
        );
        notifyListeners();
      }
    } catch (e) {
      _setError('Error al actualizar perfil: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    _clearError();
    notifyListeners();

    try {
      // TODO: Implementar cierre de sesión real
      await Future<void>.delayed(const Duration(seconds: 1));
      _profile = null;
      _recentActivity = <ActivityItem>[];
      notifyListeners();
    } catch (e) {
      _setError('Error al cerrar sesión: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadProfile() async {
    _isLoading = true;
    _clearError();
    notifyListeners();

    try {
      // TODO: Implementar carga real del perfil desde el backend
      await Future<void>.delayed(const Duration(seconds: 1));

      _profile = UserProfile(
        id: 'demo-user',
        firstName: 'Sofia',
        lastName: 'Ramirez',
        birthDate: DateTime(1990, 5, 12),
        username: 'sofia.ramirez',
        email: 'sofia.ramirez@gmail.com',
      );

      _recentActivity = <ActivityItem>[
        ActivityItem(
          title: 'Compra en línea',
          amount: -28.50,
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          type: ActivityType.expense,
        ),
        ActivityItem(
          title: 'Meta "Viaje de Verano"',
          description: 'actualizada',
          amount: 150,
          timestamp: DateTime.now().subtract(const Duration(hours: 4)),
          type: ActivityType.goal,
        ),
        ActivityItem(
          title: 'Presupuesto "Comida"',
          description: 'ajustado',
          amount: -20,
          timestamp: DateTime.now().subtract(const Duration(days: 3)),
          type: ActivityType.budget,
        ),
      ];

      notifyListeners();
    } catch (e) {
      _setError('Error al cargar perfil: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
