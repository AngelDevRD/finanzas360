import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/storage_mode.dart';
import '../../auth/data/auth_repository.dart';

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

class RemoteBudgetsRepository implements BudgetsRepository {
  RemoteBudgetsRepository(this._client, this._userId);

  final SupabaseClient _client;
  final String _userId;

  static const _table = 'finanzas360_budgets';

  Budget _fromRow(Map<String, dynamic> row) => Budget(
    id: row['id'] as String,
    categoryId: row['category_id'] as String,
    month: (row['month'] as num).toInt(),
    year: (row['year'] as num).toInt(),
    limitAmount: (row['limit_amount'] as num).toDouble(),
  );

  Map<String, dynamic> _toRow(Budget budget) => {
    'id': budget.id,
    'user_id': _userId,
    'category_id': budget.categoryId,
    'month': budget.month,
    'year': budget.year,
    'limit_amount': budget.limitAmount,
  };

  @override
  Stream<List<Budget>> watchForMonth(int month, int year) {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('user_id', _userId)
        .map(
          (rows) => rows
              .map(_fromRow)
              .where((b) => b.month == month && b.year == year)
              .toList(),
        );
  }

  @override
  Future<void> create(Budget budget) =>
      _client.from(_table).insert(_toRow(budget));

  @override
  Future<void> update(Budget budget) =>
      _client.from(_table).update(_toRow(budget)).eq('id', budget.id);

  @override
  Future<void> delete(String id) => _client.from(_table).delete().eq('id', id);
}

final budgetsRepositoryProvider = Provider<BudgetsRepository>((ref) {
  if (ref.watch(storageModeProvider) == StorageMode.cloud) {
    final user = ref.watch(currentUserProvider);
    if (user != null) {
      return RemoteBudgetsRepository(Supabase.instance.client, user.id);
    }
  }
  return LocalBudgetsRepository(ref.watch(databaseProvider));
});

final currentMonthBudgetsProvider = StreamProvider<List<Budget>>((ref) {
  final now = DateTime.now();
  return ref
      .watch(budgetsRepositoryProvider)
      .watchForMonth(now.month, now.year);
});
