import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:personal_finance/features/profile/domain/profile_repository.dart';
import 'package:personal_finance/features/profile/model/user_profile.dart';

class ProfileProvider extends ChangeNotifier {
  ProfileProvider({required this.repository});

  final ProfileRepository repository;

  UserProfile? _profile;
  bool _loading = false;

  UserProfile? get profile => _profile;
  bool get isLoading => _loading;

  Future<void> loadProfile() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    _setLoading(true);
    try {
      _profile = await repository.getProfile(user.uid);
    } catch (e) {
      debugPrint('Error al cargar perfil: $e');
      // Crear un perfil por defecto si hay error de permisos
      _profile = UserProfile(
        id: user.uid,
        firstName: user.displayName ?? 'Usuario',
        lastName: user.displayName ?? '',
        email: user.email ?? '',
        photoUrl: user.photoURL ?? '',
        username: user.displayName ?? '',
        birthDate: DateTime.now(),
      );
    }
    _setLoading(false);
  }

  Future<void> uploadPhoto(File image) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    _setLoading(true);
    try {
      final String url = await repository.uploadProfilePicture(user.uid, image);
      if (_profile != null) {
        _profile = _profile!.copyWith(photoUrl: url);
        try {
          await repository.saveProfile(_profile!);
        } catch (e) {
          debugPrint('Error al guardar perfil: $e');
          // Continuar sin guardar en Firestore
        }
      }
    } catch (e) {
      debugPrint('Error al subir foto: $e');
      // Mostrar mensaje de error si es necesario
    }
    _setLoading(false);
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }
}
