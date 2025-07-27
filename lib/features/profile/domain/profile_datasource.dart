import 'dart:io';

import '../model/user_profile.dart';

abstract class ProfileDataSource {
  Future<void> saveProfile(UserProfile profile);
  Future<UserProfile?> getProfile(String uid);
  Future<String> uploadProfilePicture(String uid, File image);
}
