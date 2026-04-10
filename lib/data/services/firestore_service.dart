// lib/data/services/firestore_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  FirestoreService(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _expenses(String gid) =>
      _db.collection('groups').doc(gid).collection('expenses');
  CollectionReference<Map<String, dynamic>> _categories(String gid) =>
      _db.collection('groups').doc(gid).collection('categories');
  CollectionReference<Map<String, dynamic>> _recurring(String gid) =>
      _db.collection('groups').doc(gid).collection('recurring_expenses');

  Future<void> createUserDocument({required String uid, required Map<String, dynamic> data}) =>
      _db.collection('users').doc(uid).set(data, SetOptions(merge: true));

  Stream<QuerySnapshot<Map<String, dynamic>>> watchExpenses({
    required String groupId, DateTime? from, DateTime? to, String? categoryId,
  }) {
    Query<Map<String, dynamic>> q = _expenses(groupId).orderBy('date', descending: true);
    if (from != null) q = q.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(from));
    if (to != null) q = q.where('date', isLessThanOrEqualTo: Timestamp.fromDate(to));
    if (categoryId != null) q = q.where('categoryId', isEqualTo: categoryId);
    return q.snapshots();
  }

  Future<void> setExpense(String gid, String id, Map<String, dynamic> data) =>
      _expenses(gid).doc(id).set(data);
  Future<void> deleteExpense(String gid, String id) => _expenses(gid).doc(id).delete();

  Stream<QuerySnapshot<Map<String, dynamic>>> watchCategories(String gid) =>
      _categories(gid).orderBy('name').snapshots();
  Future<void> setCategory(String gid, String id, Map<String, dynamic> data) =>
      _categories(gid).doc(id).set(data, SetOptions(merge: true));
  Future<void> deleteCategory(String gid, String id) => _categories(gid).doc(id).delete();

  Stream<QuerySnapshot<Map<String, dynamic>>> watchRecurring(String gid) =>
      _recurring(gid).snapshots();
  Future<QuerySnapshot<Map<String, dynamic>>> getRecurring(String gid) =>
      _recurring(gid).get();
  Future<void> setRecurring(String gid, String id, Map<String, dynamic> data) =>
      _recurring(gid).doc(id).set(data, SetOptions(merge: true));
  Future<void> updateRecurring(String gid, String id, Map<String, dynamic> data) =>
      _recurring(gid).doc(id).update(data);
  Future<void> deleteRecurring(String gid, String id) => _recurring(gid).doc(id).delete();
}
