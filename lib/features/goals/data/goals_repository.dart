import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';

abstract class GoalsRepository {
  Stream<List<SavingsGoal>> watchAll();
  Future<void> create(SavingsGoal goal);
  Future<void> update(SavingsGoal goal);
  Future<void> delete(String id);
  Future<void> addContribution(String goalId, double amount);
}

class LocalGoalsRepository implements GoalsRepository {
  LocalGoalsRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<SavingsGoal>> watchAll() => _db.select(_db.savingsGoals).watch();

  @override
  Future<void> create(SavingsGoal goal) =>
      _db.into(_db.savingsGoals).insert(goal);

  @override
  Future<void> update(SavingsGoal goal) =>
      _db.update(_db.savingsGoals).replace(goal);

  @override
  Future<void> delete(String id) =>
      (_db.delete(_db.savingsGoals)..where((g) => g.id.equals(id))).go();

  @override
  Future<void> addContribution(String goalId, double amount) async {
    final goal = await (_db.select(
      _db.savingsGoals,
    )..where((g) => g.id.equals(goalId))).getSingleOrNull();
    if (goal == null) return;
    await (_db.update(
      _db.savingsGoals,
    )..where((g) => g.id.equals(goalId))).write(
      SavingsGoalsCompanion(currentAmount: Value(goal.currentAmount + amount)),
    );
  }
}

final goalsRepositoryProvider = Provider<GoalsRepository>((ref) {
  return LocalGoalsRepository(ref.watch(databaseProvider));
});

final goalsStreamProvider = StreamProvider<List<SavingsGoal>>((ref) {
  return ref.watch(goalsRepositoryProvider).watchAll();
});
