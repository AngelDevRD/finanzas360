import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/icon_map.dart';
import '../data/categories_repository.dart';

const _swatches = [
  0xFF2563EB,
  0xFF22C55E,
  0xFFEF4444,
  0xFFF59E0B,
  0xFFA855F7,
  0xFFEC4899,
  0xFF14B8A6,
  0xFF64748B,
];

Future<void> showCategoryFormSheet(
  BuildContext context, {
  required String type,
  Category? existing,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => CategoryFormSheet(type: type, existing: existing),
  );
}

class CategoryFormSheet extends ConsumerStatefulWidget {
  const CategoryFormSheet({super.key, required this.type, this.existing});

  final String type;
  final Category? existing;

  @override
  ConsumerState<CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends ConsumerState<CategoryFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(
    text: widget.existing?.name ?? '',
  );
  late String _icon = widget.existing?.icon ?? 'category';
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
              isEditing ? 'Editar categoría' : 'Nueva categoría',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nombre'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Requerido' : null,
            ),
            const SizedBox(height: 16),
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
            const SizedBox(height: 16),
            Text('Icono', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: kIconMap.entries.map((e) {
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
              child: Text(isEditing ? 'Guardar' : 'Crear categoría'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final repo = ref.read(categoriesRepositoryProvider);

    if (widget.existing != null) {
      await repo.update(
        widget.existing!.copyWith(
          name: _nameController.text.trim(),
          icon: _icon,
          color: _color,
        ),
      );
    } else {
      await repo.create(
        Category(
          id: const Uuid().v4(),
          name: _nameController.text.trim(),
          type: widget.type,
          icon: _icon,
          color: _color,
          isDefault: false,
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
    super.dispose();
  }
}
