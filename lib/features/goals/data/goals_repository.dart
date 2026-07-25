import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/storage_mode.dart';
import '../../auth/data/auth_repository.dart';

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

class RemoteGoalsRepository implements GoalsRepository {
  RemoteGoalsRepository(this._client, this._userId);

  final SupabaseClient _client;
  final String _userId;

  static const _table = 'finanzas360_savings_goals';

  SavingsGoal _fromRow(Map<String, dynamic> row) => SavingsGoal(
    id: row['id'] as String,
    name: row['name'] as String,
    targetAmount: (row['target_amount'] as num).toDouble(),
    currentAmount: (row['current_amount'] as num).toDouble(),
    targetDate: row['target_date'] == null
        ? null
        : DateTime.parse(row['target_date'] as String),
    icon: row['icon'] as String,
    color: (row['color'] as num).toInt(),
    createdAt: DateTime.parse(row['created_at'] as String),
  );

  Map<String, dynamic> _toRow(SavingsGoal goal) => {
    'id': goal.id,
    'user_id': _userId,
    'name': goal.name,
    'target_amount': goal.targetAmount,
    'current_amount': goal.currentAmount,
    'target_date': goal.targetDate?.toIso8601String(),
    'icon': goal.icon,
    'color': goal.color,
  };

  @override
  Stream<List<SavingsGoal>> watchAll() {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('user_id', _userId)
        .map((rows) => rows.map(_fromRow).toList());
  }

  @override
  Future<void> create(SavingsGoal goal) =>
      _client.from(_table).insert(_toRow(goal));

  @override
  Future<void> update(SavingsGoal goal) =>
      _client.from(_table).update(_toRow(goal)).eq('id', goal.id);

  @override
  Future<void> delete(String id) => _client.from(_table).delete().eq('id', id);

  @override
  Future<void> addContribution(String goalId, double amount) async {
    final row = await _client
        .from(_table)
        .select()
        .eq('id', goalId)
        .maybeSingle();
    if (row == null) return;
    final goal = _fromRow(row);
    await _client
        .from(_table)
        .update({'current_amount': goal.currentAmount + amount})
        .eq('id', goalId);
  }
}

final goalsRepositoryProvider = Provider<GoalsRepository>((ref) {
  if (ref.watch(storageModeProvider) == StorageMode.cloud) {
    final user = ref.watch(currentUserProvider);
    if (user != null) {
      return RemoteGoalsRepository(Supabase.instance.client, user.id);
    }
  }
  return LocalGoalsRepository(ref.watch(databaseProvider));
});

final goalsStreamProvider = StreamProvider<List<SavingsGoal>>((ref) {
  return ref.watch(goalsRepositoryProvider).watchAll();
});
