import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../database/app_database.dart';
import '../syncable.dart';

/// Sync de Presupuestos contra Supabase (tabla `finanzas360_budgets`).
/// Requiere que [CategorySyncable] haya corrido antes en la misma pasada
/// (FK a finanzas360_categories).
class BudgetSyncable implements SyncableEntity {
  final sb.SupabaseClient client;

  BudgetSyncable(this.client);

  @override
  String get name => 'budgets';

  @override
  Future<void> push(AppDatabase db) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) return;

    final dirty = await (db.select(
      db.budgets,
    )..where((t) => t.dirty.equals(true))).get();

    for (final budget in dirty) {
      if (budget.deleted) {
        await client.from('finanzas360_budgets').delete().eq('id', budget.id);
        await (db.delete(db.budgets)..where((t) => t.id.equals(budget.id))).go();
        continue;
      }
      await client.from('finanzas360_budgets').upsert({
        'id': budget.id,
        'user_id': userId,
        'category_id': budget.categoryId,
        'month': budget.month,
        'year': budget.year,
        'limit_amount': budget.limitAmount,
      });
      await (db.update(db.budgets)..where((t) => t.id.equals(budget.id))).write(
        const BudgetsCompanion(dirty: Value(false)),
      );
    }
  }
}
