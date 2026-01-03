import 'dart:io';

import 'package:personal_finance/features/profile/domain/entities/user_profile.dart';

abstract class ProfileDataSource {
  Future<void> saveProfile(UserProfile profile);
  Future<UserProfile?> getProfile(String uid);
  Future<String> uploadProfilePicture(String uid, File image);
}
