import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../data/accounts_repository.dart';
import 'account_type.dart';

Future<void> showAccountFormSheet(BuildContext context, {Account? existing}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => AccountFormSheet(existing: existing),
  );
}

class AccountFormSheet extends ConsumerStatefulWidget {
  const AccountFormSheet({super.key, this.existing});

  final Account? existing;

  @override
  ConsumerState<AccountFormSheet> createState() => _AccountFormSheetState();
}

class _AccountFormSheetState extends ConsumerState<AccountFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(
    text: widget.existing?.name ?? '',
  );
  late final _balanceController = TextEditingController(
    text: widget.existing != null
        ? widget.existing!.initialBalance.toString()
        : '0',
  );
  late AccountType _type = widget.existing != null
      ? AccountTypeX.fromId(widget.existing!.type)
      : AccountType.cash;

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
              isEditing ? 'Editar cuenta' : 'Nueva cuenta',
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
            DropdownButtonFormField<AccountType>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Tipo'),
              items: AccountType.values
                  .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
                  .toList(),
              onChanged: (v) => setState(() => _type = v ?? AccountType.cash),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _balanceController,
              decoration: InputDecoration(
                labelText: isEditing ? 'Balance inicial' : 'Balance inicial',
                helperText: isEditing
                    ? 'Cambiar esto no recalcula movimientos ya registrados'
                    : null,
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
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _submit,
              child: Text(isEditing ? 'Guardar' : 'Crear cuenta'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final repo = ref.read(accountsRepositoryProvider);
    final balance = double.parse(_balanceController.text);

    if (widget.existing != null) {
      await repo.update(
        widget.existing!.copyWith(
          name: _nameController.text.trim(),
          type: _type.id,
          initialBalance: balance,
        ),
      );
    } else {
      await repo.create(
        Account(
          id: const Uuid().v4(),
          name: _nameController.text.trim(),
          type: _type.id,
          icon: _type.id,
          color: Colors.blue.toARGB32(),
          initialBalance: balance,
          currentBalance: balance,
          createdAt: DateTime.now(),
        ),
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }
}
