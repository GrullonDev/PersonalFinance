import 'dart:io';

import 'package:flutter/material.dart';

class ProfileLogic extends ChangeNotifier {
  String? _photoUrl;
  String? _name;
  String? _email;
  bool _loading = false;
  String? _error;

  // Getters
  String? get photoUrl => _photoUrl;
  String? get name => _name;
  String? get email => _email;
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
  Future<void> loadProfile() async {
    _setLoading(true);
    _clearError();

    try {
      // TODO: Implementar carga de datos del perfil
      await Future<void>.delayed(const Duration(seconds: 1)); // Simulación
      _photoUrl = null; // Default to showing the icon instead of a placeholder image
      _name = 'Usuario';
      _email = 'usuario@example.com';
      notifyListeners();
    } catch (e) {
      _setError('Error al cargar perfil: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateProfile({String? name, String? email}) async {
    _setLoading(true);
    _clearError();

    try {
      // TODO: Implementar actualización de perfil
      await Future<void>.delayed(const Duration(seconds: 1)); // Simulación
      if (name != null) _name = name;
      if (email != null) _email = email;
      notifyListeners();
    } catch (e) {
      _setError('Error al actualizar perfil: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> uploadPhoto(File photo) async {
    _setLoading(true);
    _clearError();

    try {
      // TODO: Implementar subida de foto
      await Future<void>.delayed(const Duration(seconds: 1)); // Simulación
      _photoUrl = photo.path;
      notifyListeners();
    } catch (e) {
      _setError('Error al subir foto: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    _clearError();

    try {
      // TODO: Implementar cierre de sesión
      await Future<void>.delayed(const Duration(seconds: 1)); // Simulación
      _photoUrl = null;
      _name = null;
      _email = null;
      notifyListeners();
    } catch (e) {
      _setError('Error al cerrar sesión: $e');
    } finally {
      _setLoading(false);
    }
  }
}
