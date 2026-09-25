import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import 'package:personal_finance/features/auth/domain/auth_datasource.dart';
import 'package:personal_finance/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:personal_finance/features/profile/data/models/profile_me_model.dart';
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
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No hay sesión activa');

      if (name != null) {
        await user.updateDisplayName(name);
      }

      final dataSource = GetIt.instance<ProfileRemoteDataSource>();
      final List<String> nameParts = (name ?? _profile?.name ?? '')
          .trim()
          .split(' ');
      final String updatedFirstName =
          nameParts.isNotEmpty ? nameParts.first : (_profile?.firstName ?? '');
      final String updatedLastName =
          nameParts.length > 1
              ? nameParts.sublist(1).join(' ')
              : (_profile?.lastName ?? '');

      final ProfileMeModel updated = ProfileMeModel(
        fullName: name ?? _profile?.name ?? '',
        email: email ?? _profile?.email ?? user.email ?? '',
        firstName: updatedFirstName,
        lastName: updatedLastName,
        username: _profile?.username,
        phoneNumber: _profile?.phoneNumber,
        address: _profile?.address,
        photoUrl: _profile?.photoUrl,
      );
      await dataSource.updateMe(updated);

      if (_profile != null) {
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
      await GetIt.instance<AuthDataSource>().logout();
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
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _setError('No hay sesión activa');
        return;
      }

      final dataSource = GetIt.instance<ProfileRemoteDataSource>();
      final ProfileMeModel model = await dataSource.getMe();

      final List<String> nameParts = (model.fullName.isNotEmpty
              ? model.fullName
              : user.displayName ?? '')
          .trim()
          .split(' ');
      final String firstName =
          model.firstName?.isNotEmpty == true
              ? model.firstName!
              : (nameParts.isNotEmpty ? nameParts.first : 'Usuario');
      final String lastName =
          model.lastName?.isNotEmpty == true
              ? model.lastName!
              : (nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '');

      _profile = UserProfile(
        id: user.uid,
        firstName: firstName,
        lastName: lastName,
        birthDate: DateTime(2000),
        username: model.username ?? user.displayName ?? '',
        email: model.email.isNotEmpty ? model.email : (user.email ?? ''),
        photoUrl: model.photoUrl ?? user.photoURL,
        phoneNumber: model.phoneNumber,
        address: model.address,
      );

      notifyListeners();
    } catch (e) {
      _setError('Error al cargar perfil: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
