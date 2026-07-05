import 'dart:io';

import 'package:excel/excel.dart' as xls;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/database/app_database.dart';
import '../../budgets/data/budgets_repository.dart';
import '../../categories/data/categories_repository.dart';
import '../../goals/data/goals_repository.dart';
import '../../transactions/data/transactions_repository.dart';
import 'excel_schema.dart';

final _dateFmt = DateFormat('yyyy-MM-dd');

class ExcelExportService {
  ExcelExportService(this._ref);

  final Ref _ref;

  /// Genera el Excel con los datos reales del usuario (todas las
  /// transacciones, los presupuestos del mes actual y todas las metas) y
  /// devuelve el archivo guardado en el directorio temporal de la app, listo
  /// para compartir o guardar.
  Future<File> exportUserData() async {
    final transactions = await _ref
        .read(transactionsRepositoryProvider)
        .watchAll()
        .first;
    final categories = await _ref
        .read(categoriesRepositoryProvider)
        .watchAll()
        .first;
    final now = DateTime.now();
    final budgets = await _ref
        .read(budgetsRepositoryProvider)
        .watchForMonth(now.month, now.year)
        .first;
    final goals = await _ref.read(goalsRepositoryProvider).watchAll().first;

    final categoryById = {for (final c in categories) c.id: c};

    final workbook = xls.Excel.createExcel();
    _writeMovimientos(workbook, transactions, categoryById);
    _writePresupuestos(workbook, budgets, categoryById);
    _writeMetas(workbook, goals);
    workbook.delete('Sheet1');

    final fileName =
        'Finanzas360_export_${DateFormat('yyyyMMdd_HHmm').format(now)}.xlsx';
    return _saveWorkbook(workbook, fileName);
  }

  /// Genera una plantilla vacía con encabezados y filas de ejemplo, para que
  /// cualquier usuario sepa cómo llenarla antes de importar.
  Future<File> exportTemplate() async {
    final workbook = xls.Excel.createExcel();

    final movimientos = workbook[ExcelSchema.sheetMovimientos];
    _appendRow(movimientos, [
      ExcelSchema.colFecha,
      ExcelSchema.colTipo,
      ExcelSchema.colCategoria,
      ExcelSchema.colDescripcion,
      ExcelSchema.colMonto,
    ]);
    _appendRow(movimientos, [
      '2026-06-01',
      ExcelSchema.tipoIngreso,
      'Salario',
      'Pago mensual',
      2500,
    ]);
    _appendRow(movimientos, [
      '2026-06-02',
      ExcelSchema.tipoGasto,
      'Comida',
      'Supermercado',
      150,
    ]);
    _appendRow(movimientos, [
      '2026-06-03',
      ExcelSchema.tipoGasto,
      'Transporte',
      'Uber',
      20,
    ]);

    final presupuestos = workbook[ExcelSchema.sheetPresupuestos];
    _appendRow(presupuestos, [
      ExcelSchema.colCategoria,
      ExcelSchema.colLimiteMensual,
    ]);
    _appendRow(presupuestos, ['Comida', 500]);
    _appendRow(presupuestos, ['Transporte', 200]);
    _appendRow(presupuestos, ['Ocio', 300]);

    final metas = workbook[ExcelSchema.sheetMetas];
    _appendRow(metas, [
      ExcelSchema.colNombre,
      ExcelSchema.colObjetivo,
      ExcelSchema.colAhorrado,
    ]);
    _appendRow(metas, ['Laptop', 1200, 400]);
    _appendRow(metas, ['Viaje', 3000, 750]);

    workbook.delete('Sheet1');
    return _saveWorkbook(workbook, 'Finanzas360_plantilla.xlsx');
  }

  void _writeMovimientos(
    xls.Excel workbook,
    List<Transaction> transactions,
    Map<String, Category> categoryById,
  ) {
    final sheet = workbook[ExcelSchema.sheetMovimientos];
    _appendRow(sheet, [
      ExcelSchema.colFecha,
      ExcelSchema.colTipo,
      ExcelSchema.colCategoria,
      ExcelSchema.colDescripcion,
      ExcelSchema.colMonto,
    ]);
    for (final t in transactions) {
      _appendRow(sheet, [
        _dateFmt.format(t.date),
        t.type == 'income' ? ExcelSchema.tipoIngreso : ExcelSchema.tipoGasto,
        categoryById[t.categoryId]?.name ?? 'Otro',
        t.description,
        t.amount,
      ]);
    }
  }

  void _writePresupuestos(
    xls.Excel workbook,
    List<Budget> budgets,
    Map<String, Category> categoryById,
  ) {
    final sheet = workbook[ExcelSchema.sheetPresupuestos];
    _appendRow(sheet, [ExcelSchema.colCategoria, ExcelSchema.colLimiteMensual]);
    for (final b in budgets) {
      _appendRow(sheet, [
        categoryById[b.categoryId]?.name ?? 'Otro',
        b.limitAmount,
      ]);
    }
  }

  void _writeMetas(xls.Excel workbook, List<SavingsGoal> goals) {
    final sheet = workbook[ExcelSchema.sheetMetas];
    _appendRow(sheet, [
      ExcelSchema.colNombre,
      ExcelSchema.colObjetivo,
      ExcelSchema.colAhorrado,
    ]);
    for (final g in goals) {
      _appendRow(sheet, [g.name, g.targetAmount, g.currentAmount]);
    }
  }

  void _appendRow(xls.Sheet sheet, List<Object> values) {
    sheet.appendRow(
      values.map((v) {
        if (v is num) return xls.DoubleCellValue(v.toDouble());
        return xls.TextCellValue(v.toString());
      }).toList(),
    );
  }

  Future<File> _saveWorkbook(xls.Excel workbook, String fileName) async {
    final bytes = workbook.encode();
    if (bytes == null) {
      throw Exception('No se pudo generar el archivo Excel.');
    }
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }
}

final excelExportServiceProvider = Provider<ExcelExportService>((ref) {
  return ExcelExportService(ref);
});
