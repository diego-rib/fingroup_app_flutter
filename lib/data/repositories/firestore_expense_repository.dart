// lib/data/repositories/firestore_expense_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/expense.dart';
import '../../domain/repositories/domain_repositories.dart';
import '../services/firestore_service.dart';

class FirestoreExpenseRepository implements ExpenseRepository {
  FirestoreExpenseRepository(this._svc);
  final FirestoreService _svc;

  @override
  Stream<List<Expense>> watchExpenses({
    required String groupId, DateTime? from, DateTime? to, String? categoryId,
  }) =>
      _svc
          .watchExpenses(groupId: groupId, from: from, to: to, categoryId: categoryId)
          .map((snap) => snap.docs.map((d) => _fromDoc(d)).toList());

  @override
  Future<void> addExpense(Expense e) =>
      _svc.setExpense(e.groupId, e.id, _toMap(e));

  @override
  Future<void> updateExpense(Expense e) =>
      _svc.setExpense(e.groupId, e.id, _toMap(e));

  @override
  Future<void> deleteExpense({required String groupId, required String id}) =>
      _svc.deleteExpense(groupId, id);

  Expense _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return Expense(
      id: doc.id,
      groupId: d['groupId'] as String,
      userId: d['userId'] as String,
      amount: (d['amount'] as num).toDouble(),
      categoryId: d['categoryId'] as String,
      date: (d['date'] as Timestamp).toDate(),
      note: d['note'] as String?,
      isRecurring: d['isRecurring'] as bool? ?? false,
      recurringExpenseId: d['recurringExpenseId'] as String?,
    );
  }

  Map<String, dynamic> _toMap(Expense e) => {
        'groupId': e.groupId,
        'userId': e.userId,
        'amount': e.amount,
        'categoryId': e.categoryId,
        'date': Timestamp.fromDate(e.date),
        'note': e.note,
        'isRecurring': e.isRecurring,
        'recurringExpenseId': e.recurringExpenseId,
      };
}
