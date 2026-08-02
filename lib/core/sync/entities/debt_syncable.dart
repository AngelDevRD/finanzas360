import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../database/app_database.dart';
import '../syncable.dart';

/// Sync de Deudas contra Supabase (tabla `finanzas360_debts`).
class DebtSyncable implements SyncableEntity {
  final sb.SupabaseClient client;

  DebtSyncable(this.client);

  @override
  String get name => 'debts';

  @override
  Future<void> push(AppDatabase db) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) return;

    final dirty = await (db.select(
      db.debts,
    )..where((t) => t.dirty.equals(true))).get();

    for (final debt in dirty) {
      if (debt.deleted) {
        await client.from('finanzas360_debts').delete().eq('id', debt.id);
        await (db.delete(db.debts)..where((t) => t.id.equals(debt.id))).go();
        continue;
      }
      await client.from('finanzas360_debts').upsert({
        'id': debt.id,
        'user_id': userId,
        'name': debt.name,
        'description': debt.description,
        'total_amount': debt.totalAmount,
        'remaining_amount': debt.remainingAmount,
        'due_date': debt.dueDate?.toIso8601String(),
        'icon': debt.icon,
        'color': debt.color,
      });
      await (db.update(db.debts)..where((t) => t.id.equals(debt.id))).write(
        const DebtsCompanion(dirty: Value(false)),
      );
    }
  }
}
