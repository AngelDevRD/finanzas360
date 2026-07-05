import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';

abstract class BudgetsRepository {
  Stream<List<Budget>> watchForMonth(int month, int year);
  Future<void> create(Budget budget);
  Future<void> update(Budget budget);
  Future<void> delete(String id);
}

class LocalBudgetsRepository implements BudgetsRepository {
  LocalBudgetsRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<Budget>> watchForMonth(int month, int year) {
    return (_db.select(
      _db.budgets,
    )..where((b) => b.month.equals(month) & b.year.equals(year))).watch();
  }

  @override
  Future<void> create(Budget budget) => _db.into(_db.budgets).insert(budget);

  @override
  Future<void> update(Budget budget) => _db.update(_db.budgets).replace(budget);

  @override
  Future<void> delete(String id) =>
      (_db.delete(_db.budgets)..where((b) => b.id.equals(id))).go();
}

final budgetsRepositoryProvider = Provider<BudgetsRepository>((ref) {
  return LocalBudgetsRepository(ref.watch(databaseProvider));
});

final currentMonthBudgetsProvider = StreamProvider<List<Budget>>((ref) {
  final now = DateTime.now();
  return ref
      .watch(budgetsRepositoryProvider)
      .watchForMonth(now.month, now.year);
});
