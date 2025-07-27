import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../domain/profile_repository.dart';
import '../model/user_profile.dart';

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
    _profile = await repository.getProfile(user.uid);
    _setLoading(false);
  }

  Future<void> uploadPhoto(File image) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    _setLoading(true);
    final String url = await repository.uploadProfilePicture(user.uid, image);
    if (_profile != null) {
      _profile = _profile!.copyWith(photoUrl: url);
      await repository.saveProfile(_profile!);
    }
    _setLoading(false);
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }
}
