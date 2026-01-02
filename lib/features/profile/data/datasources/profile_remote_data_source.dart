import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:personal_finance/core/error/exceptions.dart';
import 'package:personal_finance/features/profile/data/models/profile_me_model.dart';

abstract class ProfileRemoteDataSource {
  Future<ProfileMeModel> getMe();
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  ProfileRemoteDataSourceImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  @override
  Future<ProfileMeModel> getMe() async {
    final User? user = _auth.currentUser;
    if (user == null) {
      throw ApiException(message: 'User not authenticated', statusCode: 401);
    }

    try {
      final DocumentSnapshot<Map<String, dynamic>> doc =
          await _firestore.collection('users').doc(user.uid).get();

      if (doc.exists && doc.data() != null) {
        return ProfileMeModel.fromJson(doc.data()!);
      } else {
        // Fallback to Auth data if FS doc is missing
        return ProfileMeModel(
          fullName: user.displayName ?? '',
          email: user.email ?? '',
        );
      }
    } catch (e) {
      throw ApiException(message: e.toString(), statusCode: 500);
    }
  }
}
