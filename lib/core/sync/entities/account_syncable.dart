import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../database/app_database.dart';
import '../syncable.dart';

/// Sync de Cuentas contra Supabase (tabla `finanzas360_accounts`). Upsert
/// directo por id (el id local es el mismo que el remoto).
class AccountSyncable implements SyncableEntity {
  final sb.SupabaseClient client;

  AccountSyncable(this.client);

  @override
  String get name => 'accounts';

  @override
  Future<void> push(AppDatabase db) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) return;

    final dirty = await (db.select(
      db.accounts,
    )..where((t) => t.dirty.equals(true))).get();

    for (final account in dirty) {
      if (account.deleted) {
        await client.from('finanzas360_accounts').delete().eq('id', account.id);
        await (db.delete(
          db.accounts,
        )..where((t) => t.id.equals(account.id))).go();
        continue;
      }
      await client.from('finanzas360_accounts').upsert({
        'id': account.id,
        'user_id': userId,
        'name': account.name,
        'type': account.type,
        'icon': account.icon,
        'color': account.color,
        'initial_balance': account.initialBalance,
        'current_balance': account.currentBalance,
      });
      await (db.update(
        db.accounts,
      )..where((t) => t.id.equals(account.id))).write(
        const AccountsCompanion(dirty: Value(false)),
      );
    }
  }
}
