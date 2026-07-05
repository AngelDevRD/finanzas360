/// Modelos del resultado de leer un Excel de importación. La lectura nunca
/// escribe en la base de datos: separa "parsear y validar" de "confirmar",
/// para poder mostrarle al usuario un resumen antes de tocar sus datos.
class ImportRowError {
  const ImportRowError({
    required this.sheet,
    required this.row,
    required this.message,
  });

  final String sheet;
  final int row;
  final String message;

  String get label => '$sheet · fila $row: $message';
}

class ParsedTransactionRow {
  const ParsedTransactionRow({
    required this.date,
    required this.type,
    required this.categoryName,
    required this.description,
    required this.amount,
    required this.isDuplicate,
  });

  final DateTime date;
  final String type; // 'income' | 'expense'
  final String categoryName;
  final String description;
  final double amount;
  final bool isDuplicate;
}

class ParsedBudgetRow {
  const ParsedBudgetRow({
    required this.categoryName,
    required this.limitAmount,
  });

  final String categoryName;
  final double limitAmount;
}

class ParsedGoalRow {
  const ParsedGoalRow({
    required this.name,
    required this.target,
    required this.saved,
  });

  final String name;
  final double target;
  final double saved;
}

class ExcelImportPreview {
  const ExcelImportPreview({
    required this.hasMovimientosSheet,
    required this.hasPresupuestosSheet,
    required this.hasMetasSheet,
    required this.transactions,
    required this.budgets,
    required this.goals,
    required this.errors,
  });

  final bool hasMovimientosSheet;
  final bool hasPresupuestosSheet;
  final bool hasMetasSheet;
  final List<ParsedTransactionRow> transactions;
  final List<ParsedBudgetRow> budgets;
  final List<ParsedGoalRow> goals;
  final List<ImportRowError> errors;

  int get duplicateCount => transactions.where((t) => t.isDuplicate).length;
  int get validTransactionsCount =>
      transactions.where((t) => !t.isDuplicate).length;
  bool get hasAnyData =>
      transactions.isNotEmpty || budgets.isNotEmpty || goals.isNotEmpty;
}

class ExcelImportSummary {
  const ExcelImportSummary({
    required this.transactionsImported,
    required this.budgetsImported,
    required this.goalsImported,
    required this.categoriesCreated,
  });

  final int transactionsImported;
  final int budgetsImported;
  final int goalsImported;
  final int categoriesCreated;
}
