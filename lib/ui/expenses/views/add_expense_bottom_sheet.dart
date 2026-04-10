// lib/ui/expenses/views/add_expense_bottom_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../core/providers.dart';
import '../../../domain/entities/category.dart';
import '../../../domain/entities/expense.dart';
import '../../core/widgets/auth_widgets.dart';

// ── ViewModel local (autoDispose — descartado ao fechar o sheet) ───────────────

class _AddExpenseState {
  const _AddExpenseState({
    this.isSaving = false,
    this.saved = false,
    this.error,
    this.categories = const [],
    this.selectedCategory,
    this.selectedDate,
  });

  final bool isSaving;
  final bool saved;
  final String? error;
  final List<Category> categories;
  final Category? selectedCategory;
  final DateTime? selectedDate;

  DateTime get date => selectedDate ?? DateTime.now();

  _AddExpenseState copyWith({
    bool? isSaving,
    bool? saved,
    String? error,
    List<Category>? categories,
    Category? selectedCategory,
    DateTime? selectedDate,
  }) =>
      _AddExpenseState(
        isSaving: isSaving ?? this.isSaving,
        saved: saved ?? this.saved,
        error: error,
        categories: categories ?? this.categories,
        selectedCategory: selectedCategory ?? this.selectedCategory,
        selectedDate: selectedDate ?? this.selectedDate,
      );
}

class _AddExpenseViewModel extends StateNotifier<_AddExpenseState> {
  _AddExpenseViewModel(this._ref) : super(const _AddExpenseState()) {
    _loadCategories();
  }

  final Ref _ref;
  static const _uuid = Uuid();

  void _loadCategories() {
    final groupId = _ref.read(currentGroupIdProvider);
    if (groupId == null) return;

    _ref
        .read(categoryRepositoryProvider)
        .watchCategories(groupId: groupId)
        .first
        .then((cats) {
      state = state.copyWith(
        categories: cats,
        selectedCategory: cats.isNotEmpty ? cats.first : null,
      );
    });
  }

  void selectCategory(Category cat) =>
      state = state.copyWith(selectedCategory: cat);

  void selectDate(DateTime date) => state = state.copyWith(selectedDate: date);

  Future<void> save({required double amount, String? note}) async {
    final groupId = _ref.read(currentGroupIdProvider);
    final user = _ref.read(firebaseAuthProvider).currentUser;

    if (groupId == null || user == null) {
      state = state.copyWith(error: 'Sessão expirada.');
      return;
    }
    if (state.selectedCategory == null) {
      state = state.copyWith(error: 'Selecione uma categoria.');
      return;
    }

    state = state.copyWith(isSaving: true);

    try {
      final expense = Expense(
        id: _uuid.v4(),
        groupId: groupId,
        userId: user.uid,
        amount: amount,
        categoryId: state.selectedCategory!.id,
        date: state.date,
        note: note?.trim().isEmpty ?? true ? null : note?.trim(),
      );
      await _ref.read(expenseRepositoryProvider).addExpense(expense);
      state = state.copyWith(saved: true);
    } catch (e) {
      state = state.copyWith(error: 'Erro ao salvar. Tente novamente.');
    }
  }
}

final _addExpenseProvider =
    StateNotifierProvider.autoDispose<_AddExpenseViewModel, _AddExpenseState>(
  (ref) => _AddExpenseViewModel(ref),
);

// ── View ──────────────────────────────────────────────────────────────────────

class AddExpenseBottomSheet extends ConsumerStatefulWidget {
  const AddExpenseBottomSheet({super.key});

  @override
  ConsumerState<AddExpenseBottomSheet> createState() =>
      _AddExpenseBottomSheetState();
}

class _AddExpenseBottomSheetState
    extends ConsumerState<AddExpenseBottomSheet> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(_addExpenseProvider);
    final vm = ref.read(_addExpenseProvider.notifier);
    final theme = Theme.of(context);

    // Fecha o sheet ao salvar
    ref.listen(_addExpenseProvider, (_, next) {
      if (next.saved) Navigator.of(context).pop();
    });

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: LoadingOverlay(
        isLoading: state.isSaving,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Handle ───────────────────────────────────────────────
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                Text('Nova despesa', style: theme.textTheme.titleLarge),
                const SizedBox(height: 20),

                // ── Campo de valor ────────────────────────────────────────
                TextFormField(
                  controller: _amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  textInputAction: TextInputAction.next,
                  autofocus: true,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Valor',
                    prefixText: 'R\$ ',
                    prefixStyle: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.outline,
                    ),
                    filled: true,
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Informe o valor';
                    final parsed =
                        double.tryParse(v.replaceAll(',', '.'));
                    if (parsed == null || parsed <= 0) {
                      return 'Valor inválido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ── Categorias (scroll horizontal) ────────────────────────
                if (state.categories.isNotEmpty) ...[
                  Text('Categoria',
                      style: theme.textTheme.labelLarge
                          ?.copyWith(color: theme.colorScheme.outline)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 44,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: state.categories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final cat = state.categories[i];
                        final selected =
                            cat.id == state.selectedCategory?.id;
                        final catColor = Color(cat.colorValue);
                        return GestureDetector(
                          onTap: () => vm.selectCategory(cat),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: selected
                                  ? catColor
                                  : catColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  IconData(cat.iconCode,
                                      fontFamily: 'MaterialIcons'),
                                  size: 16,
                                  color: selected
                                      ? Colors.white
                                      : catColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  cat.name,
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: selected
                                        ? Colors.white
                                        : catColor,
                                    fontWeight: selected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ] else ...[
                  // Aviso quando não há categorias
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.tertiaryContainer
                          .withOpacity(0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded,
                            size: 18,
                            color: theme.colorScheme.tertiary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Crie categorias primeiro na aba Categorias.',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Linha: data ───────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: _DateButton(
                        date: state.date,
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: state.date,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) vm.selectDate(picked);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Observação ────────────────────────────────────────────
                TextFormField(
                  controller: _noteCtrl,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(vm),
                  decoration: const InputDecoration(
                    labelText: 'Observação (opcional)',
                    hintText: 'Ex: almoço com cliente',
                  ),
                ),
                const SizedBox(height: 8),

                // ── Erro ──────────────────────────────────────────────────
                if (state.error != null) ...[
                  ErrorBanner(message: state.error!),
                  const SizedBox(height: 8),
                ],

                // ── Salvar ────────────────────────────────────────────────
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed:
                      state.isSaving ? null : () => _submit(vm),
                  child: const Text('Salvar despesa'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submit(_AddExpenseViewModel vm) {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final raw = _amountCtrl.text.replaceAll(',', '.');
    final amount = double.tryParse(raw) ?? 0;
    vm.save(amount: amount, note: _noteCtrl.text);
  }
}

class _DateButton extends StatelessWidget {
  const _DateButton({required this.date, required this.onTap});
  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = DateFormat("d 'de' MMMM 'de' yyyy", 'pt_BR');
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.calendar_today_outlined, size: 16),
      label: Text(fmt.format(date)),
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerLeft,
        minimumSize: const Size(0, 48),
      ),
    );
  }
}
