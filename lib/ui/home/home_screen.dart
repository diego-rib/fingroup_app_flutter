// lib/ui/home/home_screen.dart
//
// Shell da aplicação após autenticação.
// Usa IndexedStack para manter o estado de cada tab viva em memória
// (não reconstrói ao trocar de tab — comportamento esperado pelo usuário).
//
// Docs: "views contain only simple routing logic" — a lógica de qual tab
// está ativa é puramente de UI, então fica aqui e não no ViewModel.

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/router/app_router.dart';
import '../categories/views/categories_screen.dart';
import '../dashboard/views/dashboard_screen.dart';
import '../expenses/views/add_expense_bottom_sheet.dart';
import '../history/views/history_screen.dart';
import '../recurring/views/recurring_screen.dart';

final _currentTabProvider = StateProvider<int>((_) => 0);

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const _tabs = [
    _TabConfig(
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard_rounded,
    ),
    _TabConfig(
      label: 'Categorias',
      icon: Icons.category_outlined,
      activeIcon: Icons.category_rounded,
    ),
    _TabConfig(
      label: 'Recorrentes',
      icon: Icons.repeat_outlined,
      activeIcon: Icons.repeat_rounded,
    ),
    _TabConfig(
      label: 'Histórico',
      icon: Icons.history_outlined,
      activeIcon: Icons.history_rounded,
    ),
  ];

  static const _pages = [
    DashboardScreen(),
    CategoriesScreen(),
    RecurringScreen(),
    HistoryScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTab = ref.watch(_currentTabProvider);
    final theme = Theme.of(context);

    return Scaffold(
      // IndexedStack mantém todas as páginas vivas —
      // o estado não é perdido ao trocar de tab
      body: IndexedStack(
        index: currentTab,
        children: _pages,
      ),

      // FAB global — disponível em qualquer tab
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddExpense(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Despesa'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      bottomNavigationBar: NavigationBar(
        selectedIndex: currentTab,
        onDestinationSelected: (index) =>
            ref.read(_currentTabProvider.notifier).state = index,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: _tabs
            .map((t) => NavigationDestination(
                  icon: Icon(t.icon),
                  selectedIcon: Icon(t.activeIcon),
                  label: t.label,
                ))
            .toList(),
      ),
    );
  }

  void _openAddExpense(BuildContext context, WidgetRef ref) {
    final groupId = ref.read(currentGroupIdProvider);
    if (groupId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sessão expirada. Faça login novamente.')),
      );
      Navigator.of(context).pushReplacementNamed(AppRouter.login);
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const AddExpenseBottomSheet(),
    );
  }
}

class _TabConfig {
  const _TabConfig({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
}
