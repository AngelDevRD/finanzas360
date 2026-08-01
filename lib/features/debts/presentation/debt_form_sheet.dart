import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../data/debts_repository.dart';

const _swatches = [0xFFEF4444, 0xFFF59E0B, 0xFF2563EB, 0xFFA855F7, 0xFF64748B];
const _icons = {
  'credit_card': Icons.credit_card,
  'house': Icons.house,
  'directions_car_filled': Icons.directions_car_filled,
  'school': Icons.school,
  'receipt_long': Icons.receipt_long,
};

Future<void> showDebtFormSheet(BuildContext context, {Debt? existing}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => DebtFormSheet(existing: existing),
  );
}

class DebtFormSheet extends ConsumerStatefulWidget {
  const DebtFormSheet({super.key, this.existing});

  final Debt? existing;

  @override
  ConsumerState<DebtFormSheet> createState() => _DebtFormSheetState();
}

class _DebtFormSheetState extends ConsumerState<DebtFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(
    text: widget.existing?.name ?? '',
  );
  late final _totalController = TextEditingController(
    text: widget.existing != null
        ? widget.existing!.totalAmount.toString()
        : '',
  );
  late final _remainingController = TextEditingController(
    text: widget.existing != null
        ? widget.existing!.remainingAmount.toString()
        : '',
  );
  late DateTime? _dueDate = widget.existing?.dueDate;
  late String _icon = widget.existing?.icon ?? _icons.keys.first;
  late int _color = widget.existing?.color ?? _swatches.first;

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;
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
              isEditing ? 'Editar deuda' : 'Nueva deuda',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nombre'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Requerido' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _totalController,
              decoration: const InputDecoration(labelText: 'Monto total'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Requerido';
                if (double.tryParse(v) == null) return 'Monto inválido';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _remainingController,
              decoration: const InputDecoration(
                labelText: 'Monto pendiente actual',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Requerido';
                if (double.tryParse(v) == null) return 'Monto inválido';
                return null;
              },
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Fecha límite (opcional)'),
              subtitle: Text(
                _dueDate == null
                    ? 'Sin fecha'
                    : '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDate,
            ),
            const SizedBox(height: 8),
            Text('Color', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _swatches.map((c) {
                final selected = c == _color;
                return GestureDetector(
                  onTap: () => setState(() => _color = c),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Color(c),
                    child: selected
                        ? const Icon(Icons.check, color: Colors.white)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: _icons.entries.map((e) {
                final selected = e.key == _icon;
                return GestureDetector(
                  onTap: () => setState(() => _icon = e.key),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: selected
                        ? Color(_color)
                        : Colors.grey.shade300,
                    child: Icon(
                      e.value,
                      color: selected ? Colors.white : Colors.black54,
                      size: 18,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _submit,
              child: Text(isEditing ? 'Guardar' : 'Crear deuda'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final repo = ref.read(debtsRepositoryProvider);
    final total = double.parse(_totalController.text);
    final remaining = double.parse(_remainingController.text);

    if (widget.existing != null) {
      await repo.update(
        widget.existing!.copyWith(
          name: _nameController.text.trim(),
          totalAmount: total,
          remainingAmount: remaining,
          dueDate: Value(_dueDate),
          icon: _icon,
          color: _color,
        ),
      );
    } else {
      await repo.create(
        Debt(
          id: const Uuid().v4(),
          name: _nameController.text.trim(),
          totalAmount: total,
          remainingAmount: remaining,
          dueDate: _dueDate,
          icon: _icon,
          color: _color,
          createdAt: DateTime.now(),
          dirty: true,
          deleted: false,
        ),
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _totalController.dispose();
    _remainingController.dispose();
    super.dispose();
  }
}
