import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/excel_import_models.dart';
import '../data/excel_import_service.dart';

class ImportPreviewScreen extends ConsumerStatefulWidget {
  const ImportPreviewScreen({super.key, required this.preview});

  final ExcelImportPreview preview;

  @override
  ConsumerState<ImportPreviewScreen> createState() =>
      _ImportPreviewScreenState();
}

class _ImportPreviewScreenState extends ConsumerState<ImportPreviewScreen> {
  bool _importing = false;

  @override
  Widget build(BuildContext context) {
    final preview = widget.preview;
    return Scaffold(
      appBar: AppBar(title: const Text('Resumen de importación')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!preview.hasAnyData && preview.errors.isEmpty)
            const Text('El archivo no tiene datos en ninguna hoja reconocida.'),
          if (preview.hasMovimientosSheet)
            _SummaryCard(
              icon: Icons.swap_horiz,
              title: 'Movimientos',
              lines: [
                '${preview.validTransactionsCount} válidos para importar',
                if (preview.duplicateCount > 0)
                  '${preview.duplicateCount} duplicados (se omitirán)',
              ],
            ),
          if (preview.hasPresupuestosSheet)
            _SummaryCard(
              icon: Icons.pie_chart_outline,
              title: 'Presupuestos',
              lines: ['${preview.budgets.length} válidos para importar'],
            ),
          if (preview.hasMetasSheet)
            _SummaryCard(
              icon: Icons.flag_outlined,
              title: 'Metas',
              lines: ['${preview.goals.length} válidas para importar'],
            ),
          if (preview.errors.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Filas con errores (no se importarán)',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.red),
            ),
            const SizedBox(height: 8),
            ...preview.errors.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '• ${e.label}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: FilledButton(
          onPressed: (_importing || !_hasImportable(preview)) ? null : _confirm,
          child: _importing
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Confirmar importación'),
        ),
      ),
    );
  }

  bool _hasImportable(ExcelImportPreview preview) =>
      preview.validTransactionsCount > 0 ||
      preview.budgets.isNotEmpty ||
      preview.goals.isNotEmpty;

  Future<void> _confirm() async {
    setState(() => _importing = true);
    try {
      final summary = await ref
          .read(excelImportServiceProvider)
          .confirm(widget.preview);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Importado: ${summary.transactionsImported} movimientos, '
            '${summary.budgetsImported} presupuestos, ${summary.goalsImported} metas'
            '${summary.categoriesCreated > 0 ? ' (se crearon ${summary.categoriesCreated} categorías nuevas)' : ''}.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _importing = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al importar: $e')));
    }
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.title,
    required this.lines,
  });

  final IconData icon;
  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text(lines.join(' · ')),
      ),
    );
  }
}
