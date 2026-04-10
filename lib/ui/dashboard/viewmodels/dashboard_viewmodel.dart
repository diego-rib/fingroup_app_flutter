// lib/ui/dashboard/viewmodels/dashboard_viewmodel.dart
//
// Docs: "view model retrieves data from repositories and transforms it
//        for display; maintains UI state; exposes commands to the view."

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../../domain/entities/category.dart';
import '../../../domain/entities/expense.dart';
import '../../../domain/entities/recurring_expense.dart';

// ── UI State (imutável) ───────────────────────────────────────────────────────

class DashboardUiState {
  const DashboardUiState({
    this.isLoading = true,
    this.expenses = const [],
    this.categories = const [],
    this.recurringExpenses = const [],
    this.selectedMonth,
    this.error,
  });

  final bool isLoading;
  final List<Expense> expenses;
  final List<Category> categories;
  final List<RecurringExpense> recurringExpenses;
  final DateTime? selectedMonth;
  final String? error;

  // ── Valores derivados — lógica aqui, NÃO nas Views ───────────────────────

  DateTime get displayMonth =>
      selectedMonth ?? DateTime(DateTime.now().year, DateTime.now().month);

  double get totalSpent =>
      expenses.fold(0.0, (sum, e) => sum + e.amount);

  double get totalBudget => categories
      .where((c) => c.hasBudgetLimit)
      .fold(0.0, (sum, c) => sum + c.budgetLimit!);

  bool get hasBudgetDefined => totalBudget > 0;

  double get budgetUsageRatio =>
      hasBudgetDefined ? (totalSpent / totalBudget).clamp(0.0, 1.0) : 0.0;

  bool get isOverBudget => hasBudgetDefined && totalSpent > totalBudget;

  /// Gasto por categoria — usado no gráfico de barras/pizza
  Map<String, double> get spentPerCategory {
    final map = <String, double>{};
    for (final e in expenses) {
      map[e.categoryId] = (map[e.categoryId] ?? 0) + e.amount;
    }
    return map;
  }

  /// Categorias ordenadas por gasto (decrescente) para o gráfico
  List<CategorySpending> get categorySpendingList {
    return categories.map((cat) {
      final spent = spentPerCategory[cat.id] ?? 0.0;
      return CategorySpending(
        category: cat,
        spent: spent,
        percentOfTotal: totalSpent > 0 ? spent / totalSpent : 0.0,
      );
    })
      ..sort((a, b) => b.spent.compareTo(a.spent));
  }

  /// Recorrentes que precisam de atenção (vencidas ou perto do prazo)
  List<RecurringExpense> get alertRecurring => recurringExpenses
      .where((r) =>
          r.status == RecurringStatus.overdue || r.isNearingDeadline)
      .toList()
    ..sort((a, b) => a.cycleDeadline.compareTo(b.cycleDeadline));

  bool get hasAlerts => alertRecurring.isNotEmpty || isOverBudget;

  /// Últimas 5 despesas para o resumo
  List<Expense> get recentExpenses => expenses.take(5).toList();

  DashboardUiState copyWith({
    bool? isLoading,
    List<Expense>? expenses,
    List<Category>? categories,
    List<RecurringExpense>? recurringExpenses,
    DateTime? selectedMonth,
    String? error,
  }) =>
      DashboardUiState(
        isLoading: isLoading ?? this.isLoading,
        expenses: expenses ?? this.expenses,
        categories: categories ?? this.categories,
        recurringExpenses: recurringExpenses ?? this.recurringExpenses,
        selectedMonth: selectedMonth ?? this.selectedMonth,
        error: error, // null limpa o erro anterior
      );
}

/// DTO para o gráfico de categorias
class CategorySpending {
  const CategorySpending({
    required this.category,
    required this.spent,
    required this.percentOfTotal,
  });

  final Category category;
  final double spent;
  final double percentOfTotal;

  bool get isOverBudget =>
      category.hasBudgetLimit && spent > category.budgetLimit!;
}

// ── ViewModel ─────────────────────────────────────────────────────────────────

class DashboardViewModel extends StateNotifier<DashboardUiState> {
  DashboardViewModel(this._ref) : super(const DashboardUiState()) {
    _init();
  }

  final Ref _ref;
  StreamSubscription<List<Expense>>? _expenseSub;
  StreamSubscription<List<Category>>? _categorySub;
  StreamSubscription<List<RecurringExpense>>? _recurringSub;

  void _init() {
    final groupId = _ref.read(currentGroupIdProvider);
    if (groupId == null) {
      state = state.copyWith(isLoading: false, error: 'Não autenticado.');
      return;
    }

    _subscribeAll(groupId);

    // Roda rollover ao abrir o dashboard
    _ref
        .read(recurringRepositoryProvider)
        .rolloverOverdueCycles(groupId: groupId)
        .ignore();
  }

  void _subscribeAll(String groupId) {
    final now = DateTime.now();
    final monthStart =
        DateTime(state.displayMonth.year, state.displayMonth.month);
    final monthEnd =
        DateTime(state.displayMonth.year, state.displayMonth.month + 1)
            .subtract(const Duration(milliseconds: 1));

    // Expenses do mês selecionado
    _expenseSub = _ref
        .read(expenseRepositoryProvider)
        .watchExpenses(groupId: groupId, from: monthStart, to: monthEnd)
        .listen(
          (expenses) =>
              state = state.copyWith(isLoading: false, expenses: expenses),
          onError: (e) =>
              state = state.copyWith(error: 'Erro ao carregar despesas.'),
        );

    // Todas as categorias
    _categorySub = _ref
        .read(categoryRepositoryProvider)
        .watchCategories(groupId: groupId)
        .listen(
          (cats) => state = state.copyWith(categories: cats),
          onError: (_) =>
              state = state.copyWith(error: 'Erro ao carregar categorias.'),
        );

    // Recorrentes
    _recurringSub = _ref
        .read(recurringRepositoryProvider)
        .watchRecurringExpenses(groupId: groupId)
        .listen(
          (rec) => state = state.copyWith(recurringExpenses: rec),
          onError: (_) => state =
              state.copyWith(error: 'Erro ao carregar despesas recorrentes.'),
        );
  }

  // ── Commands ──────────────────────────────────────────────────────────────

  /// Muda o mês exibido no dashboard e recarrega os dados
  void changeMonth(DateTime newMonth) {
    _expenseSub?.cancel();
    _categorySub?.cancel();
    _recurringSub?.cancel();
    state = state.copyWith(
      selectedMonth: DateTime(newMonth.year, newMonth.month),
      isLoading: true,
    );
    final groupId = _ref.read(currentGroupIdProvider);
    if (groupId != null) _subscribeAll(groupId);
  }

  Future<void> deleteExpense(String expenseId) async {
    final groupId = _ref.read(currentGroupIdProvider);
    if (groupId == null) return;
    try {
      await _ref
          .read(expenseRepositoryProvider)
          .deleteExpense(groupId: groupId, id: expenseId);
    } catch (e) {
      state = state.copyWith(error: 'Não foi possível excluir a despesa.');
    }
  }

  void clearError() => state = state.copyWith();

  @override
  void dispose() {
    _expenseSub?.cancel();
    _categorySub?.cancel();
    _recurringSub?.cancel();
    super.dispose();
  }
}

final dashboardViewModelProvider =
    StateNotifierProvider<DashboardViewModel, DashboardUiState>(
  (ref) => DashboardViewModel(ref),
);
