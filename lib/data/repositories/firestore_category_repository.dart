// lib/data/repositories/firestore_category_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/domain_repositories.dart';
import '../services/firestore_service.dart';

class FirestoreCategoryRepository implements CategoryRepository {
  FirestoreCategoryRepository(this._svc);
  final FirestoreService _svc;

  @override
  Stream<List<Category>> watchCategories({required String groupId}) =>
      _svc.watchCategories(groupId).map(
            (snap) => snap.docs.map((d) => _fromDoc(d)).toList(),
          );

  @override
  Future<void> addCategory(Category c) =>
      _svc.setCategory(c.groupId, c.id, _toMap(c));

  @override
  Future<void> updateCategory(Category c) =>
      _svc.setCategory(c.groupId, c.id, _toMap(c));

  @override
  Future<void> deleteCategory({required String groupId, required String id}) =>
      _svc.deleteCategory(groupId, id);

  Category _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return Category(
      id: doc.id,
      groupId: d['groupId'] as String,
      name: d['name'] as String,
      iconCode: d['iconCode'] as int,
      colorValue: d['colorValue'] as int,
      budgetLimit: (d['budgetLimit'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> _toMap(Category c) => {
        'groupId': c.groupId,
        'name': c.name,
        'iconCode': c.iconCode,
        'colorValue': c.colorValue,
        'budgetLimit': c.budgetLimit,
      };
}
