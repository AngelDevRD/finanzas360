import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/icon_map.dart';
import '../../categories/data/categories_repository.dart';
import '../../categories/presentation/category_picker_sheet.dart';
import '../data/budgets_repository.dart';

Future<void> showBudgetFormSheet(BuildContext context, {Budget? existing}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => BudgetFormSheet(existing: existing),
  );
}

class BudgetFormSheet extends ConsumerStatefulWidget {
  const BudgetFormSheet({super.key, this.existing});

  final Budget? existing;

  @override
  ConsumerState<BudgetFormSheet> createState() => _BudgetFormSheetState();
}

class _BudgetFormSheetState extends ConsumerState<BudgetFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _amountController = TextEditingController(
    text: widget.existing != null
        ? widget.existing!.limitAmount.toString()
        : '',
  );
  late String? _categoryId = widget.existing?.categoryId;

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEditing ? 'Editar presupuesto' : 'Nuevo presupuesto del mes',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            categoriesAsync.when(
              data: (all) {
                final parentIds = all
                    .map((c) => c.parentId)
                    .whereType<String>()
                    .toSet();
                final options = all
                    .where(
                      (c) => c.type == 'expense' && !parentIds.contains(c.id),
                    )
                    .toList();
                final selected = options
                    .where((c) => c.id == _categoryId)
                    .firstOrNull;
                return FormField<String>(
                  initialValue: _categoryId,
                  validator: (v) => v == null ? 'Requerido' : null,
                  builder: (field) => InkWell(
                    onTap: () async {
                      final picked = await showCategoryPickerSheet(
                        context,
                        options: options,
                        selectedId: _categoryId,
                      );
                      if (picked != null) {
                        setState(() => _categoryId = picked.id);
                        field.didChange(picked.id);
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Categoría',
                        errorText: field.errorText,
                        suffixIcon: const Icon(Icons.search),
                      ),
                      child: selected == null
                          ? const Text('Buscar y seleccionar...')
                          : Row(
                              children: [
                                Icon(
                                  iconForKey(selected.icon),
                                  size: 18,
                                  color: Color(selected.color),
                                ),
                                const SizedBox(width: 8),
                                Text(selected.name),
                              ],
                            ),
                    ),
                  ),
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (e, st) => Text('Error: $e'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: 'Límite mensual'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Requerido';
                if (double.tryParse(v) == null) return 'Monto inválido';
                return null;
              },
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _submit,
              child: Text(isEditing ? 'Guardar' : 'Crear presupuesto'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final repo = ref.read(budgetsRepositoryProvider);
    final now = DateTime.now();
    final amount = double.parse(_amountController.text);

    if (widget.existing != null) {
      await repo.update(
        widget.existing!.copyWith(
          categoryId: _categoryId!,
          limitAmount: amount,
        ),
      );
    } else {
      await repo.create(
        Budget(
          id: const Uuid().v4(),
          categoryId: _categoryId!,
          month: now.month,
          year: now.year,
          limitAmount: amount,
        ),
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }
}
