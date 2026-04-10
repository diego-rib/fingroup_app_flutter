// lib/ui/core/widgets/dashboard_widgets.dart
//
// Widgets de apresentação do Dashboard.
// Docs: "write reusable, lean widgets that hold as little logic as possible."
// Esses widgets recebem dados prontos do ViewModel — não fazem cálculos.

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';

import '../../../domain/entities/category.dart';
import '../../../domain/entities/expense.dart';
import '../../../domain/entities/recurring_expense.dart';
import '../../dashboard/viewmodels/dashboard_viewmodel.dart';

final _currencyFmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
final _shortDateFmt = DateFormat('dd/MM', 'pt_BR');

// ── BudgetSummaryCard ─────────────────────────────────────────────────────────

class BudgetSummaryCard extends StatelessWidget {
  const BudgetSummaryCard({
    super.key,
    required this.totalSpent,
    required this.totalBudget,
    required this.usageRatio,
    required this.isOverBudget,
    required this.hasBudget,
    required this.month,
  });

  final double totalSpent;
  final double totalBudget;
  final double usageRatio;
  final bool isOverBudget;
  final bool hasBudget;
  final DateTime month;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final progressColor = isOverBudget ? cs.error : cs.primary;
    final monthLabel = DateFormat('MMMM yyyy', 'pt_BR').format(month);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total em $monthLabel',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: cs.outline,
                  ),
                ),
                if (isOverBudget)
                  Chip(
                    label: const Text('Acima do limite'),
                    labelStyle: TextStyle(
                        color: cs.onErrorContainer, fontSize: 11),
                    backgroundColor: cs.errorContainer,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // ── Valor gasto ──────────────────────────────────────────────
            Text(
              _currencyFmt.format(totalSpent),
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: isOverBudget ? cs.error : cs.onSurface,
              ),
            ),

            if (hasBudget) ...[
              const SizedBox(height: 4),
              Text(
                'de ${_currencyFmt.format(totalBudget)} orçados',
                style: theme.textTheme.bodySmall?.copyWith(color: cs.outline),
              ),
              const SizedBox(height: 16),

              // ── Barra de progresso ─────────────────────────────────────
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: usageRatio,
                  minHeight: 10,
                  backgroundColor: cs.surfaceContainerHighest,
                  color: progressColor,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(usageRatio * 100).toStringAsFixed(0)}% utilizado',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: progressColor),
                  ),
                  Text(
                    'Disponível: ${_currencyFmt.format((totalBudget - totalSpent).clamp(0, double.infinity))}',
                    style:
                        theme.textTheme.bodySmall?.copyWith(color: cs.outline),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 8),
              Text(
                'Defina orçamentos nas categorias para acompanhar seu limite',
                style: theme.textTheme.bodySmall?.copyWith(color: cs.outline),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── RecurringAlertsCard ───────────────────────────────────────────────────────

class RecurringAlertsCard extends StatelessWidget {
  const RecurringAlertsCard({super.key, required this.items});
  final List<RecurringExpense> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.errorContainer, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.notification_important_rounded,
                    size: 18, color: cs.error),
                const SizedBox(width: 8),
                Text(
                  'Atenção: despesas recorrentes',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(color: cs.error, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...items.map((r) => _RecurringAlertTile(item: r)),
          ],
        ),
      ),
    );
  }
}

class _RecurringAlertTile extends StatelessWidget {
  const _RecurringAlertTile({required this.item});
  final RecurringExpense item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isOverdue = item.status == RecurringStatus.overdue ||
        item.timeUntilDeadline.isNegative;

    final timeLabel = isOverdue
        ? 'Vencida há ${(-item.timeUntilDeadline.inDays).abs()}d'
        : 'Vence em ${item.timeUntilDeadline.inHours < 24 ? '${item.timeUntilDeadline.inHours}h' : '${item.timeUntilDeadline.inDays}d'}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            isOverdue ? Icons.error_rounded : Icons.schedule_rounded,
            size: 16,
            color: isOverdue ? cs.error : cs.tertiary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              item.description,
              style: theme.textTheme.bodyMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _currencyFmt.format(item.amount),
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isOverdue ? cs.errorContainer : cs.tertiaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              timeLabel,
              style: theme.textTheme.labelSmall?.copyWith(
                color: isOverdue ? cs.onErrorContainer : cs.onTertiaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── CategorySpendingCard ──────────────────────────────────────────────────────

class CategorySpendingCard extends StatelessWidget {
  const CategorySpendingCard({
    super.key,
    required this.items,
    required this.totalSpent,
  });

  final List<CategorySpending> items;
  final double totalSpent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Por categoria', style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            ...items.take(6).map((item) => _CategoryBar(item: item)),
            if (items.length > 6) ...[
              const SizedBox(height: 8),
              Center(
                child: Text(
                  '+ ${items.length - 6} categorias',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  const _CategoryBar({required this.item});
  final CategorySpending item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final catColor = Color(item.category.colorValue);
    final isOver = item.isOverBudget;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Ícone da categoria
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: catColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(
                  IconData(item.category.iconCode,
                      fontFamily: 'MaterialIcons'),
                  size: 16,
                  color: catColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.category.name,
                  style: theme.textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Valores
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _currencyFmt.format(item.spent),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isOver ? cs.error : null,
                    ),
                  ),
                  if (item.category.hasBudgetLimit)
                    Text(
                      'de ${_currencyFmt.format(item.category.budgetLimit!)}',
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: cs.outline),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Barra de progresso da categoria
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: item.category.hasBudgetLimit
                  ? (item.spent / item.category.budgetLimit!).clamp(0.0, 1.0)
                  : item.percentOfTotal,
              minHeight: 6,
              backgroundColor: cs.surfaceContainerHighest,
              color: isOver ? cs.error : catColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ── RecentExpensesCard ────────────────────────────────────────────────────────

class RecentExpensesCard extends StatelessWidget {
  const RecentExpensesCard({
    super.key,
    required this.expenses,
    required this.categories,
    required this.onDelete,
  });

  final List<Expense> expenses;
  final List<Category> categories;
  final void Function(String id) onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final catMap = {for (final c in categories) c.id: c};

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Últimas despesas', style: theme.textTheme.titleMedium),
                TextButton(
                  onPressed: () {}, // TODO: navegar para histórico completo
                  child: const Text('Ver tudo'),
                ),
              ],
            ),
          ),
          ...expenses.map((e) {
            final cat = catMap[e.categoryId];
            return _ExpenseTile(
              expense: e,
              category: cat,
              onDelete: () => onDelete(e.id),
            );
          }),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  const _ExpenseTile({
    required this.expense,
    required this.category,
    required this.onDelete,
  });

  final Expense expense;
  final Category? category;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final catColor =
        category != null ? Color(category!.colorValue) : cs.primary;

    return Slidable(
      key: ValueKey(expense.id),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.25,
        children: [
          SlidableAction(
            onPressed: (_) => _confirmDelete(context),
            backgroundColor: cs.errorContainer,
            foregroundColor: cs.onErrorContainer,
            icon: Icons.delete_outline_rounded,
            label: 'Excluir',
            borderRadius: const BorderRadius.horizontal(
              right: Radius.circular(16),
            ),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: catColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: category != null
              ? Icon(
                  IconData(category!.iconCode, fontFamily: 'MaterialIcons'),
                  size: 20,
                  color: catColor,
                )
              : Icon(Icons.receipt_outlined, size: 20, color: catColor),
        ),
        title: Text(
          expense.note ?? category?.name ?? 'Despesa',
          style: theme.textTheme.bodyMedium,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${category?.name ?? '—'} · ${_shortDateFmt.format(expense.date)}',
          style:
              theme.textTheme.bodySmall?.copyWith(color: cs.outline),
        ),
        trailing: Text(
          _currencyFmt.format(expense.amount),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: cs.error,
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir despesa?'),
        content: const Text('Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              onDelete();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }
}
