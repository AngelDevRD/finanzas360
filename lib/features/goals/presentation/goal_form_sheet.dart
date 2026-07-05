import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../data/goals_repository.dart';

const _swatches = [0xFF2563EB, 0xFF22C55E, 0xFFA855F7, 0xFFF59E0B, 0xFFEC4899];
const _icons = {
  'savings': Icons.savings,
  'flight': Icons.flight,
  'directions_car_filled': Icons.directions_car_filled,
  'house': Icons.house,
  'computer': Icons.computer,
};

Future<void> showGoalFormSheet(BuildContext context, {SavingsGoal? existing}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => GoalFormSheet(existing: existing),
  );
}

class GoalFormSheet extends ConsumerStatefulWidget {
  const GoalFormSheet({super.key, this.existing});

  final SavingsGoal? existing;

  @override
  ConsumerState<GoalFormSheet> createState() => _GoalFormSheetState();
}

class _GoalFormSheetState extends ConsumerState<GoalFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(
    text: widget.existing?.name ?? '',
  );
  late final _targetController = TextEditingController(
    text: widget.existing != null
        ? widget.existing!.targetAmount.toString()
        : '',
  );
  late DateTime? _targetDate = widget.existing?.targetDate;
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
              isEditing ? 'Editar meta' : 'Nueva meta de ahorro',
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
              controller: _targetController,
              decoration: const InputDecoration(labelText: 'Monto objetivo'),
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
              title: const Text('Fecha objetivo (opcional)'),
              subtitle: Text(
                _targetDate == null
                    ? 'Sin fecha'
                    : '${_targetDate!.day}/${_targetDate!.month}/${_targetDate!.year}',
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
              child: Text(isEditing ? 'Guardar' : 'Crear meta'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _targetDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final repo = ref.read(goalsRepositoryProvider);
    final target = double.parse(_targetController.text);

    if (widget.existing != null) {
      await repo.update(
        widget.existing!.copyWith(
          name: _nameController.text.trim(),
          targetAmount: target,
          targetDate: Value(_targetDate),
          icon: _icon,
          color: _color,
        ),
      );
    } else {
      await repo.create(
        SavingsGoal(
          id: const Uuid().v4(),
          name: _nameController.text.trim(),
          targetAmount: target,
          currentAmount: 0,
          targetDate: _targetDate,
          icon: _icon,
          color: _color,
          createdAt: DateTime.now(),
        ),
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    super.dispose();
  }
}
