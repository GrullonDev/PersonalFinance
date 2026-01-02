import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:personal_finance/core/error/exceptions.dart';
import 'package:personal_finance/features/goals/data/models/goal_model.dart';

abstract class GoalRemoteDataSource {
  Future<List<GoalModel>> getGoals();
  Future<GoalModel> createGoal(GoalModel goal);
  Future<GoalModel> updateGoal(String id, GoalModel goal);
  Future<void> deleteGoal(String id);
}

class GoalRemoteDataSourceImpl implements GoalRemoteDataSource {
  GoalRemoteDataSourceImpl({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String get _uid {
    final User? user = _auth.currentUser;
    if (user == null) {
      throw ApiException(message: 'User not authenticated', statusCode: 401);
    }
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _goalsCollection =>
      _firestore.collection('users').doc(_uid).collection('goals');

  @override
  Future<List<GoalModel>> getGoals() async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await _goalsCollection.orderBy('fecha_limite').get();
      return snapshot.docs
          .map(
            (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                GoalModel.fromJson({...doc.data(), 'id': doc.id}),
          )
          .toList();
    } catch (e) {
      throw ApiException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<GoalModel> createGoal(GoalModel goal) async {
    try {
      final DocumentReference<Map<String, dynamic>> docRef =
          _goalsCollection.doc();
      final Map<String, dynamic> data = goal.toJson()..remove('id');
      await docRef.set(data);
      return GoalModel.fromJson({...data, 'id': docRef.id});
    } catch (e) {
      throw ApiException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<GoalModel> updateGoal(String id, GoalModel goal) async {
    try {
      final Map<String, dynamic> data = goal.toJson()..remove('id');
      await _goalsCollection.doc(id).update(data);
      return GoalModel.fromJson({...data, 'id': id});
    } catch (e) {
      throw ApiException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<void> deleteGoal(String id) async {
    try {
      await _goalsCollection.doc(id).delete();
    } catch (e) {
      throw ApiException(message: e.toString(), statusCode: 500);
    }
  }
}
