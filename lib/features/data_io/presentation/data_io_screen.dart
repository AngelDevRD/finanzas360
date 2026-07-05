import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/native_share.dart';
import '../data/excel_export_service.dart';
import '../data/excel_import_service.dart';
import 'import_preview_screen.dart';

class DataIoScreen extends ConsumerStatefulWidget {
  const DataIoScreen({super.key});

  @override
  ConsumerState<DataIoScreen> createState() => _DataIoScreenState();
}

class _DataIoScreenState extends ConsumerState<DataIoScreen> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Importar / Exportar Datos')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Exporta tus movimientos, presupuestos y metas a un archivo Excel '
            '(.xlsx) compatible con Microsoft Excel, Google Sheets y LibreOffice, '
            'o importa datos desde un archivo con el mismo formato.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          _ActionCard(
            icon: Icons.upload_file_outlined,
            title: 'Exportar Excel',
            subtitle:
                'Genera un .xlsx con todos tus datos y lo comparte o guarda.',
            busy: _busy,
            onTap: () => _runExport(
              () => ref.read(excelExportServiceProvider).exportUserData(),
              shareText: 'Mis datos de Finanzas 360',
            ),
          ),
          const SizedBox(height: 12),
          _ActionCard(
            icon: Icons.download_outlined,
            title: 'Importar Excel',
            subtitle:
                'Selecciona un .xlsx con hojas Movimientos, Presupuestos y/o Metas.',
            busy: _busy,
            onTap: _runImport,
          ),
          const SizedBox(height: 12),
          _ActionCard(
            icon: Icons.description_outlined,
            title: 'Descargar Plantilla Excel',
            subtitle:
                'Archivo de ejemplo con las hojas y columnas correctas para llenar.',
            busy: _busy,
            onTap: () => _runExport(
              () => ref.read(excelExportServiceProvider).exportTemplate(),
              shareText: 'Plantilla Finanzas 360',
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _runExport(
    Future<dynamic> Function() generate, {
    required String shareText,
  }) async {
    setState(() => _busy = true);
    try {
      final file = await generate();
      if (!mounted) return;
      await NativeShare.shareFile(file.path, text: shareText);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al generar el archivo: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _runImport() async {
    const xlsxType = XTypeGroup(label: 'Excel', extensions: ['xlsx']);
    final file = await openFile(acceptedTypeGroups: [xlsxType]);
    if (file == null) return;
    final bytes = await File(file.path).readAsBytes();

    setState(() => _busy = true);
    try {
      final importService = ref.read(excelImportServiceProvider);
      final existingKeys = await importService.buildExistingTransactionKeys();
      final preview = importService.parse(
        bytes,
        existingTransactionKeys: existingKeys,
      );
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ImportPreviewScreen(preview: preview),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No se pudo leer el archivo: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.busy,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: busy
            ? const SizedBox(width: 16)
            : const Icon(Icons.chevron_right),
        onTap: busy ? null : onTap,
      ),
    );
  }
}
