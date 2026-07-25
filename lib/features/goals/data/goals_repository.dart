import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';

/// Persistencia de metas de ahorro: siempre local (Drift) -- ver
/// AccountsRepository para el detalle del patron dirty/soft-delete + sync.
class GoalsRepository {
  GoalsRepository(this._db);

  final AppDatabase _db;

  Stream<List<SavingsGoal>> watchAll() {
    return (_db.select(
      _db.savingsGoals,
    )..where((g) => g.deleted.equals(false))).watch();
  }

  Future<void> create(SavingsGoal goal) => _db
      .into(_db.savingsGoals)
      .insert(
        SavingsGoalsCompanion.insert(
          id: goal.id,
          name: goal.name,
          targetAmount: goal.targetAmount,
          currentAmount: Value(goal.currentAmount),
          targetDate: Value(goal.targetDate),
          icon: goal.icon,
          color: goal.color,
          createdAt: Value(goal.createdAt),
        ),
      );

  Future<void> update(SavingsGoal goal) =>
      (_db.update(_db.savingsGoals)..where((g) => g.id.equals(goal.id))).write(
        SavingsGoalsCompanion(
          name: Value(goal.name),
          targetAmount: Value(goal.targetAmount),
          currentAmount: Value(goal.currentAmount),
          targetDate: Value(goal.targetDate),
          icon: Value(goal.icon),
          color: Value(goal.color),
          dirty: const Value(true),
        ),
      );

  Future<void> delete(String id) =>
      (_db.update(_db.savingsGoals)..where((g) => g.id.equals(id))).write(
        const SavingsGoalsCompanion(deleted: Value(true), dirty: Value(true)),
      );

  Future<void> addContribution(String goalId, double amount) async {
    final goal = await (_db.select(
      _db.savingsGoals,
    )..where((g) => g.id.equals(goalId))).getSingleOrNull();
    if (goal == null) return;
    await (_db.update(
      _db.savingsGoals,
    )..where((g) => g.id.equals(goalId))).write(
      SavingsGoalsCompanion(
        currentAmount: Value(goal.currentAmount + amount),
        dirty: const Value(true),
      ),
    );
  }
}

final goalsRepositoryProvider = Provider<GoalsRepository>((ref) {
  return GoalsRepository(ref.watch(databaseProvider));
});

final goalsStreamProvider = StreamProvider<List<SavingsGoal>>((ref) {
  return ref.watch(goalsRepositoryProvider).watchAll();
});
