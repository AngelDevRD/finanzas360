import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';

/// Persistencia de presupuestos: siempre local (Drift) -- ver
/// AccountsRepository para el detalle del patron dirty/soft-delete + sync.
class BudgetsRepository {
  BudgetsRepository(this._db);

  final AppDatabase _db;

  Stream<List<Budget>> watchForMonth(int month, int year) {
    return (_db.select(_db.budgets)..where(
          (b) =>
              b.month.equals(month) &
              b.year.equals(year) &
              b.deleted.equals(false),
        ))
        .watch();
  }

  Future<void> create(Budget budget) => _db
      .into(_db.budgets)
      .insert(
        BudgetsCompanion.insert(
          id: budget.id,
          categoryId: budget.categoryId,
          month: budget.month,
          year: budget.year,
          limitAmount: budget.limitAmount,
        ),
      );

  Future<void> update(Budget budget) =>
      (_db.update(_db.budgets)..where((b) => b.id.equals(budget.id))).write(
        BudgetsCompanion(
          categoryId: Value(budget.categoryId),
          month: Value(budget.month),
          year: Value(budget.year),
          limitAmount: Value(budget.limitAmount),
          dirty: const Value(true),
        ),
      );

  Future<void> delete(String id) =>
      (_db.update(_db.budgets)..where((b) => b.id.equals(id))).write(
        const BudgetsCompanion(deleted: Value(true), dirty: Value(true)),
      );
}

final budgetsRepositoryProvider = Provider<BudgetsRepository>((ref) {
  return BudgetsRepository(ref.watch(databaseProvider));
});

final currentMonthBudgetsProvider = StreamProvider<List<Budget>>((ref) {
  final now = DateTime.now();
  return ref
      .watch(budgetsRepositoryProvider)
      .watchForMonth(now.month, now.year);
});
