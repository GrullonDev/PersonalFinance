import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../domain/profile_datasource.dart';
import '../model/user_profile.dart';

class FirebaseProfileService implements ProfileDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  @override
  Future<UserProfile?> getProfile(String uid) async {
    final DocumentSnapshot<Map<String, dynamic>> doc =
        await _firestore.collection('users').doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return UserProfile.fromMap(doc.id, doc.data()!);
    }
    return null;
  }

  @override
  Future<void> saveProfile(UserProfile profile) async {
    await _firestore.collection('users').doc(profile.id).set(profile.toMap());
  }

  @override
  Future<String> uploadProfilePicture(String uid, File image) async {
    final Reference ref = _storage.ref().child('profile_pictures/$uid.jpg');
    await ref.putFile(image);
    return ref.getDownloadURL();
  }
}
