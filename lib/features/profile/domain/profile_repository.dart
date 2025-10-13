import 'dart:io';

import '../model/user_profile.dart';
import 'profile_datasource.dart';

abstract class ProfileRepository {
  Future<void> saveProfile(UserProfile profile);
  Future<UserProfile?> getProfile(String uid);
  Future<String> uploadProfilePicture(String uid, File image);
}

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileDataSource dataSource;

  ProfileRepositoryImpl(this.dataSource);

  @override
  Future<void> saveProfile(UserProfile profile) =>
      dataSource.saveProfile(profile);

  @override
  Future<UserProfile?> getProfile(String uid) => dataSource.getProfile(uid);

  @override
  Future<String> uploadProfilePicture(String uid, File image) =>
      dataSource.uploadProfilePicture(uid, image);
}
