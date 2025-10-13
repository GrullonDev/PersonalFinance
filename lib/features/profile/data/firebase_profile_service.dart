import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:personal_finance/utils/firebase_error_handler.dart';

import '../domain/profile_datasource.dart';
import '../model/user_profile.dart';

class FirebaseProfileService implements ProfileDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  @override
  Future<UserProfile?> getProfile(String uid) async =>
      FirebaseErrorHandler.handleOperation<UserProfile>(
        operation: () async {
          final DocumentSnapshot<Map<String, dynamic>> doc =
              await _firestore.collection('users').doc(uid).get();
          if (doc.exists && doc.data() != null) {
            return UserProfile.fromMap(doc.id, doc.data()!);
          }
          return null;
        },
        errorMessage: 'Error al obtener perfil de usuario',
      );

  @override
  Future<void> saveProfile(UserProfile profile) async {
    await FirebaseErrorHandler.handleVoidOperation(
      operation: () async {
        await _firestore
            .collection('users')
            .doc(profile.id)
            .set(profile.toMap());
      },
      errorMessage: 'Error al guardar perfil de usuario',
    );
  }

  @override
  Future<String> uploadProfilePicture(String uid, File image) async {
    final String? result = await FirebaseErrorHandler.handleOperation<String>(
      operation: () async {
        final Reference ref = _storage.ref().child('profile_pictures/$uid.jpg');
        await ref.putFile(image);
        return await ref.getDownloadURL();
      },
      errorMessage: 'Error al subir foto de perfil',
      defaultValue: '',
    );

    return result ?? '';
  }
}
