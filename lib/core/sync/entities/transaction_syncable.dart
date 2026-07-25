import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../database/app_database.dart';
import '../syncable.dart';

/// Sync de Transacciones contra Supabase (tabla `finanzas360_transactions`).
/// Requiere que [AccountSyncable] y [CategorySyncable] hayan corrido antes en
/// la misma pasada (FKs a finanzas360_accounts/finanzas360_categories).
class TransactionSyncable implements SyncableEntity {
  final sb.SupabaseClient client;

  TransactionSyncable(this.client);

  @override
  String get name => 'transactions';

  @override
  Future<void> push(AppDatabase db) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) return;

    final dirty = await (db.select(
      db.transactions,
    )..where((t) => t.dirty.equals(true))).get();

    for (final t in dirty) {
      if (t.deleted) {
        await client.from('finanzas360_transactions').delete().eq('id', t.id);
        await (db.delete(
          db.transactions,
        )..where((tbl) => tbl.id.equals(t.id))).go();
        continue;
      }
      await client.from('finanzas360_transactions').upsert({
        'id': t.id,
        'user_id': userId,
        'account_id': t.accountId,
        'category_id': t.categoryId,
        'type': t.type,
        'amount': t.amount,
        'date': t.date.toIso8601String(),
        'description': t.description,
        'payment_method': t.paymentMethod,
        'note': t.note,
        'receipt_path': t.receiptPath,
      });
      await (db.update(
        db.transactions,
      )..where((tbl) => tbl.id.equals(t.id))).write(
        const TransactionsCompanion(dirty: Value(false)),
      );
    }
  }
}
