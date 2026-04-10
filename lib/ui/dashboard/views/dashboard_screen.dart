// lib/ui/dashboard/views/dashboard_screen.dart
//
// Docs: "views are the primary method of rendering UI and shouldn't
//        contain any business logic; passed all data from the view model."

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../viewmodels/dashboard_viewmodel.dart';
import '../../core/widgets/dashboard_widgets.dart';
import '../../../domain/entities/recurring_expense.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardViewModelProvider);
    final vm = ref.read(dashboardViewModelProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () async => vm.changeMonth(state.displayMonth),
                child: CustomScrollView(
                  slivers: [
                    // ── App bar com seletor de mês ────────────────────────
                    SliverAppBar(
                      floating: true,
                      snap: true,
                      title: _MonthSelector(
                        current: state.displayMonth,
                        onChanged: vm.changeMonth,
                      ),
                      actions: [
                        IconButton(
                          icon: const Icon(Icons.person_outline_rounded),
                          tooltip: 'Perfil',
                          onPressed: () {}, // TODO: perfil
                        ),
                      ],
                    ),

                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          // ── Banner de erro ────────────────────────────
                          if (state.error != null) ...[
                            _ErrorBanner(
                              message: state.error!,
                              onDismiss: vm.clearError,
                            ),
                            const SizedBox(height: 12),
                          ],

                          // ── Card principal: total vs orçamento ────────
                          BudgetSummaryCard(
                            totalSpent: state.totalSpent,
                            totalBudget: state.totalBudget,
                            usageRatio: state.budgetUsageRatio,
                            isOverBudget: state.isOverBudget,
                            hasBudget: state.hasBudgetDefined,
                            month: state.displayMonth,
                          ),
                          const SizedBox(height: 16),

                          // ── Alertas de recorrentes ─────────────────────
                          if (state.alertRecurring.isNotEmpty) ...[
                            RecurringAlertsCard(
                                items: state.alertRecurring),
                            const SizedBox(height: 16),
                          ],

                          // ── Gráfico de gastos por categoria ────────────
                          if (state.categorySpendingList.isNotEmpty) ...[
                            CategorySpendingCard(
                              items: state.categorySpendingList,
                              totalSpent: state.totalSpent,
                            ),
                            const SizedBox(height: 16),
                          ],

                          // ── Últimas despesas ───────────────────────────
                          if (state.recentExpenses.isNotEmpty) ...[
                            RecentExpensesCard(
                              expenses: state.recentExpenses,
                              categories: state.categories,
                              onDelete: vm.deleteExpense,
                            ),
                          ],

                          // Empty state quando não há nada
                          if (!state.isLoading &&
                              state.expenses.isEmpty &&
                              state.categorySpendingList.isEmpty)
                            _EmptyState(month: state.displayMonth),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

// ── Sub-widgets privados (sem lógica) ─────────────────────────────────────────

class _MonthSelector extends StatelessWidget {
  const _MonthSelector({required this.current, required this.onChanged});

  final DateTime current;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final label = DateFormat('MMMM yyyy', 'pt_BR').format(current);
    final now = DateTime.now();
    final isCurrentMonth =
        current.year == now.year && current.month == now.month;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left_rounded),
          visualDensity: VisualDensity.compact,
          onPressed: () => onChanged(
            DateTime(current.year, current.month - 1),
          ),
        ),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: current,
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
              initialEntryMode: DatePickerEntryMode.calendarOnly,
              helpText: 'Selecionar mês',
            );
            if (picked != null) {
              onChanged(DateTime(picked.year, picked.month));
            }
          },
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right_rounded),
          visualDensity: VisualDensity.compact,
          onPressed: isCurrentMonth
              ? null
              : () => onChanged(
                    DateTime(current.year, current.month + 1),
                  ),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onDismiss});
  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return MaterialBanner(
      content: Text(message),
      leading: const Icon(Icons.warning_amber_rounded),
      backgroundColor: Theme.of(context).colorScheme.errorContainer,
      actions: [
        TextButton(onPressed: onDismiss, child: const Text('OK')),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.month});
  final DateTime month;

  @override
  Widget build(BuildContext context) {
    final monthLabel = DateFormat('MMMM', 'pt_BR').format(month);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhuma despesa em $monthLabel',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Toque no botão + para registrar sua primeira despesa',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
          ),
        ],
      ),
    );
  }
}
