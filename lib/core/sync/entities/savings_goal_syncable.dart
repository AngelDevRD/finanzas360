import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../database/app_database.dart';
import '../syncable.dart';

/// Sync de Metas de ahorro contra Supabase (tabla `finanzas360_savings_goals`).
class SavingsGoalSyncable implements SyncableEntity {
  final sb.SupabaseClient client;

  SavingsGoalSyncable(this.client);

  @override
  String get name => 'savings_goals';

  @override
  Future<void> push(AppDatabase db) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) return;

    final dirty = await (db.select(
      db.savingsGoals,
    )..where((t) => t.dirty.equals(true))).get();

    for (final goal in dirty) {
      if (goal.deleted) {
        await client
            .from('finanzas360_savings_goals')
            .delete()
            .eq('id', goal.id);
        await (db.delete(
          db.savingsGoals,
        )..where((t) => t.id.equals(goal.id))).go();
        continue;
      }
      await client.from('finanzas360_savings_goals').upsert({
        'id': goal.id,
        'user_id': userId,
        'name': goal.name,
        'target_amount': goal.targetAmount,
        'current_amount': goal.currentAmount,
        'target_date': goal.targetDate?.toIso8601String(),
        'icon': goal.icon,
        'color': goal.color,
      });
      await (db.update(
        db.savingsGoals,
      )..where((t) => t.id.equals(goal.id))).write(
        const SavingsGoalsCompanion(dirty: Value(false)),
      );
    }
  }
}
