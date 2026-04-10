// lib/domain/repositories/expense_repository.dart

import '../entities/expense.dart';

abstract class ExpenseRepository {
  Stream<List<Expense>> watchExpenses({
    required String groupId,
    DateTime? from,
    DateTime? to,
    String? categoryId,
  });

  Future<void> addExpense(Expense expense);
  Future<void> updateExpense(Expense expense);
  Future<void> deleteExpense({required String groupId, required String id});
}


// ─────────────────────────────────────────────────────────────────────────────
// lib/domain/repositories/category_repository.dart

import '../entities/category.dart';

abstract class CategoryRepository {
  Stream<List<Category>> watchCategories({required String groupId});
  Future<void> addCategory(Category category);
  Future<void> updateCategory(Category category);
  Future<void> deleteCategory({required String groupId, required String id});
}


// ─────────────────────────────────────────────────────────────────────────────
// lib/domain/repositories/recurring_expense_repository.dart

import '../entities/recurring_expense.dart';

abstract class RecurringExpenseRepository {
  Stream<List<RecurringExpense>> watchRecurringExpenses({
    required String groupId,
  });

  Future<void> addRecurringExpense(RecurringExpense recurring);

  Future<void> markCompleted({
    required String groupId,
    required String recurringId,
  });

  Future<void> rolloverOverdueCycles({required String groupId});

  Future<void> deleteRecurringExpense({
    required String groupId,
    required String id,
  });
}
