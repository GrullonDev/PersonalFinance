import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:personal_finance/core/error/exceptions.dart';
import 'package:personal_finance/features/accounts/data/models/account_model.dart';

abstract class AccountRemoteDataSource {
  Future<List<AccountModel>> getAccounts();
  Future<AccountModel> getAccount(String id);
  Future<AccountModel> createAccount(AccountModel account);
  Future<AccountModel> updateAccount(AccountModel account);
  Future<void> deleteAccount(String id);
}

class AccountRemoteDataSourceImpl implements AccountRemoteDataSource {
  AccountRemoteDataSourceImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) {
      throw ApiException(message: 'User not authenticated', statusCode: 401);
    }
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _accountsCollection =>
      _firestore.collection('users').doc(_uid).collection('accounts');

  @override
  Future<List<AccountModel>> getAccounts() async {
    try {
      final snapshot = await _accountsCollection.get();
      return snapshot.docs
          .map((doc) => AccountModel.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      throw ApiException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<AccountModel> getAccount(String id) async {
    try {
      final doc = await _accountsCollection.doc(id).get();
      if (!doc.exists) {
        throw ApiException(message: 'Account not found', statusCode: 404);
      }
      return AccountModel.fromJson({...doc.data()!, 'id': doc.id});
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<AccountModel> createAccount(AccountModel account) async {
    try {
      final docRef = _accountsCollection.doc();
      final data = account.toJson()..remove('id'); // Firestore generates ID
      await docRef.set(data);
      return AccountModel.fromJson({...data, 'id': docRef.id});
    } catch (e) {
      throw ApiException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<AccountModel> updateAccount(AccountModel account) async {
    try {
      if (account.id.isEmpty) {
        throw ApiException(message: 'Account ID is empty', statusCode: 400);
      }
      final data = account.toJson()..remove('id');
      await _accountsCollection.doc(account.id).update(data);
      return account;
    } catch (e) {
      throw ApiException(message: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<void> deleteAccount(String id) async {
    try {
      await _accountsCollection.doc(id).delete();
    } catch (e) {
      throw ApiException(message: e.toString(), statusCode: 500);
    }
  }
}
