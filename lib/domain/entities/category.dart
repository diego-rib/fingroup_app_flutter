// lib/domain/entities/category.dart

import 'package:freezed_annotation/freezed_annotation.dart';

part 'category.freezed.dart';

@freezed
class Category with _$Category {
  const factory Category({
    required String id,
    required String groupId,
    required String name,
    required int iconCode,
    required int colorValue,
    double? budgetLimit,
  }) = _Category;

  const Category._();

  bool get hasBudgetLimit => budgetLimit != null;
}
