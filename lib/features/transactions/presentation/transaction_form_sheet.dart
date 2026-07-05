import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/formatting.dart';
import '../../../core/icon_map.dart';
import '../../accounts/data/accounts_repository.dart';
import '../../categories/data/categories_repository.dart';
import '../../categories/presentation/category_picker_sheet.dart';
import '../data/transactions_repository.dart';

const _paymentMethods = ['Efectivo', 'Tarjeta', 'Transferencia', 'Otro'];

Future<void> showTransactionFormSheet(
  BuildContext context, {
  String initialType = 'expense',
  Transaction? existing,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) =>
        TransactionFormSheet(initialType: initialType, existing: existing),
  );
}

class TransactionFormSheet extends ConsumerStatefulWidget {
  const TransactionFormSheet({
    super.key,
    required this.initialType,
    this.existing,
  });

  final String initialType;
  final Transaction? existing;

  @override
  ConsumerState<TransactionFormSheet> createState() =>
      _TransactionFormSheetState();
}

class _TransactionFormSheetState extends ConsumerState<TransactionFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late String _type = widget.existing?.type ?? widget.initialType;
  late final _amountController = TextEditingController(
    text: widget.existing != null ? widget.existing!.amount.toString() : '',
  );
  late final _descriptionController = TextEditingController(
    text: widget.existing?.description ?? '',
  );
  late final _noteController = TextEditingController(
    text: widget.existing?.note ?? '',
  );
  late DateTime _date = widget.existing?.date ?? DateTime.now();
  late String? _accountId = widget.existing?.accountId;
  late String? _categoryId = widget.existing?.categoryId;
  late String _paymentMethod = widget.existing?.paymentMethod.isNotEmpty == true
      ? widget.existing!.paymentMethod
      : _paymentMethods.first;

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;
    final accountsAsync = ref.watch(accountsStreamProvider);
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEditing
                    ? 'Editar movimiento'
                    : (_type == 'income' ? 'Nuevo ingreso' : 'Nuevo gasto'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'expense', label: Text('Gasto')),
                  ButtonSegment(value: 'income', label: Text('Ingreso')),
                ],
                selected: {_type},
                onSelectionChanged: (s) => setState(() {
                  _type = s.first;
                  _categoryId = null;
                }),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Monto'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Requerido';
                  final parsed = double.tryParse(v);
                  if (parsed == null || parsed <= 0) return 'Monto inválido';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              accountsAsync.when(
                data: (accounts) => DropdownButtonFormField<String>(
                  initialValue: _accountId,
                  decoration: const InputDecoration(labelText: 'Cuenta'),
                  items: accounts
                      .map(
                        (a) =>
                            DropdownMenuItem(value: a.id, child: Text(a.name)),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _accountId = v),
                  validator: (v) => v == null ? 'Requerido' : null,
                ),
                loading: () => const LinearProgressIndicator(),
                error: (e, st) => Text('Error: $e'),
              ),
              const SizedBox(height: 12),
              categoriesAsync.when(
                data: (all) {
                  // Seleccionable = no tiene subcategorías propias. Para
                  // gastos eso son las hojas (parentId != null); para
                  // ingresos, que no tienen subcategorías, son todas.
                  final parentIds = all
                      .map((c) => c.parentId)
                      .whereType<String>()
                      .toSet();
                  final options = all
                      .where(
                        (c) => c.type == _type && !parentIds.contains(c.id),
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
              DropdownButtonFormField<String>(
                initialValue: _paymentMethod,
                decoration: const InputDecoration(labelText: 'Método de pago'),
                items: _paymentMethods
                    .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _paymentMethod = v ?? _paymentMethods.first),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Fecha'),
                subtitle: Text(formatDate(_date)),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickDate,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Descripción'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(labelText: 'Nota (opcional)'),
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _submit,
                child: Text(isEditing ? 'Guardar' : 'Crear movimiento'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final repo = ref.read(transactionsRepositoryProvider);
    final amount = double.parse(_amountController.text);

    final transaction = Transaction(
      id: widget.existing?.id ?? const Uuid().v4(),
      accountId: _accountId!,
      categoryId: _categoryId!,
      type: _type,
      amount: amount,
      date: _date,
      description: _descriptionController.text.trim(),
      paymentMethod: _paymentMethod,
      note: _noteController.text.trim(),
      receiptPath: widget.existing?.receiptPath,
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
    );

    if (widget.existing != null) {
      await repo.update(widget.existing!, transaction);
    } else {
      await repo.create(transaction);
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _noteController.dispose();
    super.dispose();
  }
}
