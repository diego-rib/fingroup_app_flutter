// lib/domain/entities/recurring_expense.dart

import 'package:freezed_annotation/freezed_annotation.dart';

part 'recurring_expense.freezed.dart';

enum RecurringFrequency { daily, weekly, monthly }

enum RecurringStatus { pending, completed, overdue }

@freezed
class RecurringExpense with _$RecurringExpense {
  const factory RecurringExpense({
    required String id,
    required String groupId,
    required String categoryId,
    required String description,
    required double amount,
    required RecurringFrequency frequency,
    required DateTime cycleStartDate,
    DateTime? completedAt,
    @Default(RecurringStatus.pending) RecurringStatus status,
  }) = _RecurringExpense;

  const RecurringExpense._();

  DateTime get cycleDeadline {
    return switch (frequency) {
      RecurringFrequency.daily =>
        cycleStartDate.add(const Duration(days: 1)),
      RecurringFrequency.weekly =>
        cycleStartDate.add(const Duration(days: 7)),
      RecurringFrequency.monthly => DateTime(
          cycleStartDate.year,
          cycleStartDate.month + 1,
          cycleStartDate.day,
        ),
    };
  }

  Duration get timeUntilDeadline => cycleDeadline.difference(DateTime.now());

  bool get isNearingDeadline {
    if (status == RecurringStatus.completed) return false;
    final total = cycleDeadline.difference(cycleStartDate).inSeconds;
    final remaining = timeUntilDeadline.inSeconds;
    if (remaining < 0) return true;
    return remaining < total * 0.2;
  }

  String get frequencyLabel => switch (frequency) {
        RecurringFrequency.daily => 'Diário',
        RecurringFrequency.weekly => 'Semanal',
        RecurringFrequency.monthly => 'Mensal',
      };
}
