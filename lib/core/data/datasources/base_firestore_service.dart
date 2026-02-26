import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:personal_finance/core/data/models/syncable_model.dart';

abstract class BaseFirestoreService<T extends SyncableModel> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get collectionName;

  T fromFirestore(Map<String, dynamic> json);

  CollectionReference<Map<String, dynamic>> get _userCollection {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection(collectionName);
  }

  Future<void> upsert(T model) async {
    final docRef = _userCollection.doc(model.id);

    // Multi-device: check version/updatedAt before overriding
    final docSnapshot = await docRef.get();
    if (docSnapshot.exists) {
      final existingData = docSnapshot.data()!;
      final existingVersion = existingData['version'] as int? ?? 0;
      final existingUpdatedAt =
          (existingData['updatedAt'] as Timestamp?)?.toDate();

      // Simple conflict resolution: Higher version or newer updatedAt wins
      if (existingVersion > model.version ||
          (existingUpdatedAt != null &&
              existingUpdatedAt.isAfter(model.updatedAt))) {
        // Conflict detected!
        // In a real app, you might want to return the conflict or merge.
        // For now, we follow the "Cero duplicados y sin pisar datos" rule
        // by only allowing updates if our version is newer or equal.
        throw Exception('Conflict detected: remote version is newer');
      }
    }

    await docRef.set(model.toFirestore(), SetOptions(merge: true));
  }

  Future<void> softDelete(String id) async {
    await _userCollection.doc(id).update({
      'deletedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<T>> watchAll() => _userCollection
      .where('deletedAt', isNull: true)
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.docs.map((doc) => fromFirestore(doc.data())).toList(),
      );

  Future<T?> get(String id) async {
    final docSnapshot = await _userCollection.doc(id).get();
    if (!docSnapshot.exists) return null;
    return fromFirestore(docSnapshot.data()!);
  }

  Future<List<T>> getAll() async {
    final snapshot =
        await _userCollection.where('deletedAt', isNull: true).get();
    return snapshot.docs.map((doc) => fromFirestore(doc.data())).toList();
  }
}
