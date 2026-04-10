// lib/data/repositories/firestore_recurring_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/recurring_expense.dart';
import '../../domain/repositories/domain_repositories.dart';
import '../services/firestore_service.dart';

class FirestoreRecurringRepository implements RecurringExpenseRepository {
  FirestoreRecurringRepository(this._svc);
  final FirestoreService _svc;

  @override
  Stream<List<RecurringExpense>> watchRecurringExpenses(
          {required String groupId}) =>
      _svc
          .watchRecurring(groupId)
          .map((snap) => snap.docs.map(_fromDoc).toList());

  @override
  Future<void> addRecurringExpense(RecurringExpense r) =>
      _svc.setRecurring(r.groupId, r.id, _toMap(r));

  @override
  Future<void> markCompleted(
      {required String groupId, required String recurringId}) =>
      _svc.updateRecurring(groupId, recurringId, {
        'completedAt': Timestamp.fromDate(DateTime.now()),
        'status': RecurringStatus.completed.name,
      });

  // ⚠️ Roda client-side no MVP — mover para Cloud Function em produção
  @override
  Future<void> rolloverOverdueCycles({required String groupId}) async {
    final snap = await _svc.getRecurring(groupId);
    final now = DateTime.now();
    for (final doc in snap.docs) {
      final r = _fromDoc(doc);
      if (r.status != RecurringStatus.completed &&
          r.cycleDeadline.isBefore(now)) {
        await _svc.updateRecurring(groupId, r.id, {
          'cycleStartDate': Timestamp.fromDate(r.cycleDeadline),
          'completedAt': null,
          'status': RecurringStatus.pending.name,
        });
      } else if (r.status == RecurringStatus.pending && r.isNearingDeadline) {
        await _svc.updateRecurring(groupId, r.id, {
          'status': RecurringStatus.overdue.name,
        });
      }
    }
  }

  @override
  Future<void> deleteRecurringExpense(
          {required String groupId, required String id}) =>
      _svc.deleteRecurring(groupId, id);

  RecurringExpense _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return RecurringExpense(
      id: doc.id,
      groupId: d['groupId'] as String,
      categoryId: d['categoryId'] as String,
      description: d['description'] as String,
      amount: (d['amount'] as num).toDouble(),
      frequency: RecurringFrequency.values.byName(d['frequency'] as String),
      cycleStartDate: (d['cycleStartDate'] as Timestamp).toDate(),
      completedAt: (d['completedAt'] as Timestamp?)?.toDate(),
      status: RecurringStatus.values.byName(
          d['status'] as String? ?? RecurringStatus.pending.name),
    );
  }

  Map<String, dynamic> _toMap(RecurringExpense r) => {
        'groupId': r.groupId,
        'categoryId': r.categoryId,
        'description': r.description,
        'amount': r.amount,
        'frequency': r.frequency.name,
        'cycleStartDate': Timestamp.fromDate(r.cycleStartDate),
        'completedAt':
            r.completedAt != null ? Timestamp.fromDate(r.completedAt!) : null,
        'status': r.status.name,
      };
}
