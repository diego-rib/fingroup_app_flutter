// lib/domain/entities/expense.dart

import 'package:freezed_annotation/freezed_annotation.dart';

part 'expense.freezed.dart';

@freezed
class Expense with _$Expense {
  const factory Expense({
    required String id,
    required String groupId,
    required String userId,
    required double amount,
    required String categoryId,
    required DateTime date,
    String? note,
    @Default(false) bool isRecurring,
    String? recurringExpenseId,
  }) = _Expense;
}
