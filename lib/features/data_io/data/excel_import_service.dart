import 'package:excel/excel.dart' as xls;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../accounts/data/accounts_repository.dart';
import '../../budgets/data/budgets_repository.dart';
import '../../categories/data/categories_repository.dart';
import '../../goals/data/goals_repository.dart';
import '../../transactions/data/transactions_repository.dart';
import 'excel_import_models.dart';
import 'excel_schema.dart';

const _defaultCategoryColor = 0xFF64748B;

/// Lee y valida un Excel de importación, y por separado, confirma la
/// escritura en la base de datos. Diseñado para que agregar columnas nuevas
/// en el futuro no rompa archivos viejos: las columnas se buscan por nombre
/// de encabezado (no por posición) y cualquier columna nueva que falte se
/// completa con un valor por defecto en vez de fallar.
class ExcelImportService {
  ExcelImportService(this._ref);

  final Ref _ref;

  /// Construye las claves de las transacciones ya existentes en la base de
  /// datos, para poder detectar duplicados al importar.
  Future<Set<String>> buildExistingTransactionKeys() async {
    final transactionsRepo = _ref.read(transactionsRepositoryProvider);
    final categoriesRepo = _ref.read(categoriesRepositoryProvider);
    final transactions = await transactionsRepo.watchAll().first;
    final categories = await categoriesRepo.watchAll().first;
    final categoryById = {for (final c in categories) c.id: c};
    return transactions.map((t) {
      final categoryName = categoryById[t.categoryId]?.name ?? '';
      return _transactionKey(
        t.date,
        t.type,
        categoryName,
        t.amount,
        t.description,
      );
    }).toSet();
  }

  ExcelImportPreview parse(
    List<int> bytes, {
    required Set<String> existingTransactionKeys,
  }) {
    final workbook = xls.Excel.decodeBytes(bytes);
    final errors = <ImportRowError>[];

    final hasMovimientos = workbook.tables.containsKey(
      ExcelSchema.sheetMovimientos,
    );
    final hasPresupuestos = workbook.tables.containsKey(
      ExcelSchema.sheetPresupuestos,
    );
    final hasMetas = workbook.tables.containsKey(ExcelSchema.sheetMetas);

    final transactions = hasMovimientos
        ? _parseMovimientos(
            workbook.tables[ExcelSchema.sheetMovimientos]!,
            errors,
            existingTransactionKeys,
          )
        : <ParsedTransactionRow>[];

    final budgets = hasPresupuestos
        ? _parsePresupuestos(
            workbook.tables[ExcelSchema.sheetPresupuestos]!,
            errors,
          )
        : <ParsedBudgetRow>[];

    final goals = hasMetas
        ? _parseMetas(workbook.tables[ExcelSchema.sheetMetas]!, errors)
        : <ParsedGoalRow>[];

    return ExcelImportPreview(
      hasMovimientosSheet: hasMovimientos,
      hasPresupuestosSheet: hasPresupuestos,
      hasMetasSheet: hasMetas,
      transactions: transactions,
      budgets: budgets,
      goals: goals,
      errors: errors,
    );
  }

  List<ParsedTransactionRow> _parseMovimientos(
    xls.Sheet sheet,
    List<ImportRowError> errors,
    Set<String> existingKeys,
  ) {
    final rows = sheet.rows;
    if (rows.isEmpty) return [];
    final header = _headerIndex(rows.first);
    final iFecha = header[ExcelSchema.colFecha.toLowerCase()];
    final iTipo = header[ExcelSchema.colTipo.toLowerCase()];
    final iCategoria = header[ExcelSchema.colCategoria.toLowerCase()];
    final iDescripcion = header[ExcelSchema.colDescripcion.toLowerCase()];
    final iMonto = header[ExcelSchema.colMonto.toLowerCase()];

    if (iFecha == null ||
        iTipo == null ||
        iCategoria == null ||
        iMonto == null) {
      errors.add(
        ImportRowError(
          sheet: ExcelSchema.sheetMovimientos,
          row: 1,
          message:
              'Faltan columnas obligatorias (Fecha, Tipo, Categoría, Monto).',
        ),
      );
      return [];
    }

    final result = <ParsedTransactionRow>[];
    for (var r = 1; r < rows.length; r++) {
      final row = rows[r];
      if (_isEmptyRow(row)) continue;
      final rowNum = r + 1;

      final date = _cellToDate(_cell(row, iFecha));
      if (date == null) {
        errors.add(
          ImportRowError(
            sheet: ExcelSchema.sheetMovimientos,
            row: rowNum,
            message: 'Fecha inválida (use AAAA-MM-DD).',
          ),
        );
        continue;
      }

      final tipoRaw = _cellToString(_cell(row, iTipo))?.trim();
      final type = _normalizeType(tipoRaw);
      if (type == null) {
        errors.add(
          ImportRowError(
            sheet: ExcelSchema.sheetMovimientos,
            row: rowNum,
            message: 'Tipo inválido ("$tipoRaw"). Use Ingreso o Gasto.',
          ),
        );
        continue;
      }

      final categoryName = _cellToString(_cell(row, iCategoria))?.trim();
      if (categoryName == null || categoryName.isEmpty) {
        errors.add(
          ImportRowError(
            sheet: ExcelSchema.sheetMovimientos,
            row: rowNum,
            message: 'Categoría vacía.',
          ),
        );
        continue;
      }

      final amount = _cellToNum(_cell(row, iMonto));
      if (amount == null || amount <= 0) {
        errors.add(
          ImportRowError(
            sheet: ExcelSchema.sheetMovimientos,
            row: rowNum,
            message: 'Monto inválido (debe ser un número positivo).',
          ),
        );
        continue;
      }

      final description = iDescripcion != null
          ? (_cellToString(_cell(row, iDescripcion)) ?? '')
          : '';

      final key = _transactionKey(
        date,
        type,
        categoryName,
        amount,
        description,
      );
      result.add(
        ParsedTransactionRow(
          date: date,
          type: type,
          categoryName: categoryName,
          description: description,
          amount: amount,
          isDuplicate: existingKeys.contains(key),
        ),
      );
    }
    return result;
  }

  List<ParsedBudgetRow> _parsePresupuestos(
    xls.Sheet sheet,
    List<ImportRowError> errors,
  ) {
    final rows = sheet.rows;
    if (rows.isEmpty) return [];
    final header = _headerIndex(rows.first);
    final iCategoria = header[ExcelSchema.colCategoria.toLowerCase()];
    final iLimite = header[ExcelSchema.colLimiteMensual.toLowerCase()];
    if (iCategoria == null || iLimite == null) {
      errors.add(
        ImportRowError(
          sheet: ExcelSchema.sheetPresupuestos,
          row: 1,
          message: 'Faltan columnas obligatorias (Categoría, Límite Mensual).',
        ),
      );
      return [];
    }

    final result = <ParsedBudgetRow>[];
    for (var r = 1; r < rows.length; r++) {
      final row = rows[r];
      if (_isEmptyRow(row)) continue;
      final rowNum = r + 1;

      final categoryName = _cellToString(_cell(row, iCategoria))?.trim();
      if (categoryName == null || categoryName.isEmpty) {
        errors.add(
          ImportRowError(
            sheet: ExcelSchema.sheetPresupuestos,
            row: rowNum,
            message: 'Categoría vacía.',
          ),
        );
        continue;
      }

      final limit = _cellToNum(_cell(row, iLimite));
      if (limit == null || limit <= 0) {
        errors.add(
          ImportRowError(
            sheet: ExcelSchema.sheetPresupuestos,
            row: rowNum,
            message: 'Límite mensual inválido (debe ser un número positivo).',
          ),
        );
        continue;
      }

      result.add(
        ParsedBudgetRow(categoryName: categoryName, limitAmount: limit),
      );
    }
    return result;
  }

  List<ParsedGoalRow> _parseMetas(
    xls.Sheet sheet,
    List<ImportRowError> errors,
  ) {
    final rows = sheet.rows;
    if (rows.isEmpty) return [];
    final header = _headerIndex(rows.first);
    final iNombre = header[ExcelSchema.colNombre.toLowerCase()];
    final iObjetivo = header[ExcelSchema.colObjetivo.toLowerCase()];
    final iAhorrado = header[ExcelSchema.colAhorrado.toLowerCase()];
    if (iNombre == null || iObjetivo == null) {
      errors.add(
        ImportRowError(
          sheet: ExcelSchema.sheetMetas,
          row: 1,
          message: 'Faltan columnas obligatorias (Nombre, Objetivo).',
        ),
      );
      return [];
    }

    final result = <ParsedGoalRow>[];
    for (var r = 1; r < rows.length; r++) {
      final row = rows[r];
      if (_isEmptyRow(row)) continue;
      final rowNum = r + 1;

      final name = _cellToString(_cell(row, iNombre))?.trim();
      if (name == null || name.isEmpty) {
        errors.add(
          ImportRowError(
            sheet: ExcelSchema.sheetMetas,
            row: rowNum,
            message: 'Nombre vacío.',
          ),
        );
        continue;
      }

      final target = _cellToNum(_cell(row, iObjetivo));
      if (target == null || target <= 0) {
        errors.add(
          ImportRowError(
            sheet: ExcelSchema.sheetMetas,
            row: rowNum,
            message: 'Objetivo inválido (debe ser un número positivo).',
          ),
        );
        continue;
      }

      // "Ahorrado" es una columna opcional (compatibilidad futura): si no
      // existe o está vacía, se completa con 0.
      final saved = iAhorrado != null
          ? (_cellToNum(_cell(row, iAhorrado)) ?? 0)
          : 0.0;

      result.add(
        ParsedGoalRow(
          name: name,
          target: target,
          saved: saved.clamp(0, target),
        ),
      );
    }
    return result;
  }

  /// Escribe en la base de datos solo las filas válidas y no duplicadas.
  /// Las categorías que no existan se crean automáticamente.
  Future<ExcelImportSummary> confirm(ExcelImportPreview preview) async {
    final categoriesRepo = _ref.read(categoriesRepositoryProvider);
    final accountsRepo = _ref.read(accountsRepositoryProvider);
    final budgetsRepo = _ref.read(budgetsRepositoryProvider);
    final goalsRepo = _ref.read(goalsRepositoryProvider);
    final transactionsRepo = _ref.read(transactionsRepositoryProvider);

    final categories = await categoriesRepo.watchAll().first;
    final categoryByKey = {
      for (final c in categories) '${c.type}::${c.name.toLowerCase()}': c,
    };
    var categoriesCreated = 0;

    Future<Category> resolveCategory(String name, String type) async {
      final key = '$type::${name.toLowerCase()}';
      final existing = categoryByKey[key];
      if (existing != null) return existing;
      final created = Category(
        id: const Uuid().v4(),
        name: name,
        type: type,
        parentId: null,
        icon: 'category',
        color: _defaultCategoryColor,
        isDefault: false,
        dirty: true,
        deleted: false,
      );
      await categoriesRepo.create(created);
      categoryByKey[key] = created;
      categoriesCreated++;
      return created;
    }

    final accounts = await accountsRepo.watchAll().first;
    Account defaultAccount;
    if (accounts.isNotEmpty) {
      defaultAccount = accounts.first;
    } else {
      defaultAccount = Account(
        id: const Uuid().v4(),
        name: 'Importado',
        type: 'cash',
        icon: 'account_balance_wallet',
        color: _defaultCategoryColor,
        initialBalance: 0,
        currentBalance: 0,
        createdAt: DateTime.now(),
        dirty: true,
        deleted: false,
      );
      await accountsRepo.create(defaultAccount);
    }

    var transactionsImported = 0;
    for (final t in preview.transactions) {
      if (t.isDuplicate) continue;
      final category = await resolveCategory(t.categoryName, t.type);
      await transactionsRepo.create(
        Transaction(
          id: const Uuid().v4(),
          accountId: defaultAccount.id,
          categoryId: category.id,
          type: t.type,
          amount: t.amount,
          date: t.date,
          description: t.description,
          paymentMethod: '',
          note: '',
          receiptPath: null,
          createdAt: DateTime.now(),
          dirty: true,
          deleted: false,
        ),
      );
      transactionsImported++;
    }

    final now = DateTime.now();
    var budgetsImported = 0;
    for (final b in preview.budgets) {
      final category = await resolveCategory(b.categoryName, 'expense');
      await budgetsRepo.create(
        Budget(
          id: const Uuid().v4(),
          categoryId: category.id,
          month: now.month,
          year: now.year,
          limitAmount: b.limitAmount,
          dirty: true,
          deleted: false,
        ),
      );
      budgetsImported++;
    }

    var goalsImported = 0;
    for (final g in preview.goals) {
      await goalsRepo.create(
        SavingsGoal(
          id: const Uuid().v4(),
          name: g.name,
          targetAmount: g.target,
          currentAmount: g.saved,
          targetDate: null,
          icon: 'savings',
          color: _defaultCategoryColor,
          createdAt: DateTime.now(),
          dirty: true,
          deleted: false,
        ),
      );
      goalsImported++;
    }

    return ExcelImportSummary(
      transactionsImported: transactionsImported,
      budgetsImported: budgetsImported,
      goalsImported: goalsImported,
      categoriesCreated: categoriesCreated,
    );
  }

  // ---- helpers de lectura de celdas ----

  Map<String, int> _headerIndex(List<xls.Data?> headerRow) {
    final map = <String, int>{};
    for (var i = 0; i < headerRow.length; i++) {
      final name = _cellToString(headerRow[i])?.trim().toLowerCase();
      if (name != null && name.isNotEmpty) map[name] = i;
    }
    return map;
  }

  xls.Data? _cell(List<xls.Data?> row, int index) =>
      index < row.length ? row[index] : null;

  bool _isEmptyRow(List<xls.Data?> row) {
    return row.every(
      (d) => _cellToString(d) == null || _cellToString(d)!.trim().isEmpty,
    );
  }

  String? _normalizeType(String? raw) {
    if (raw == null) return null;
    final v = raw.trim().toLowerCase();
    if (v == ExcelSchema.tipoIngreso.toLowerCase() || v == 'income') {
      return 'income';
    }
    if (v == ExcelSchema.tipoGasto.toLowerCase() || v == 'expense') {
      return 'expense';
    }
    return null;
  }

  String _transactionKey(
    DateTime date,
    String type,
    String categoryName,
    double amount,
    String description,
  ) {
    final d = '${date.year}-${date.month}-${date.day}';
    return '$d|$type|${categoryName.toLowerCase()}|$amount|${description.toLowerCase()}';
  }

  String? _cellToString(xls.Data? data) {
    final v = data?.value;
    if (v == null) return null;
    switch (v) {
      case xls.TextCellValue text:
        return text.value.text;
      case xls.IntCellValue intVal:
        return intVal.value.toString();
      case xls.DoubleCellValue d:
        return d.value.toString();
      case xls.DateCellValue date:
        return _isoDate(date.asDateTimeLocal());
      case xls.DateTimeCellValue dt:
        return _isoDate(dt.asDateTimeLocal());
      case xls.BoolCellValue b:
        return b.value.toString();
      default:
        return v.toString();
    }
  }

  double? _cellToNum(xls.Data? data) {
    final v = data?.value;
    if (v == null) return null;
    if (v is xls.IntCellValue) return v.value.toDouble();
    if (v is xls.DoubleCellValue) return v.value;
    if (v is xls.TextCellValue) {
      return double.tryParse(v.value.text?.trim() ?? '');
    }
    return null;
  }

  DateTime? _cellToDate(xls.Data? data) {
    final v = data?.value;
    if (v == null) return null;
    if (v is xls.DateCellValue) return v.asDateTimeLocal();
    if (v is xls.DateTimeCellValue) return v.asDateTimeLocal();
    if (v is xls.TextCellValue) {
      return DateTime.tryParse(v.value.text?.trim() ?? '');
    }
    return null;
  }

  String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

final excelImportServiceProvider = Provider<ExcelImportService>((ref) {
  return ExcelImportService(ref);
});
