import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';

/// Persistencia de cuentas: siempre local (Drift) -- el SyncEngine se encarga
/// de replicar hacia Supabase en background cuando el modo Nube esta activo
/// (ver core/storage_mode.dart y core/sync/sync_engine.dart). Las filas se
/// marcan `dirty` en cada escritura para que la proxima pasada de sync las
/// suba; el borrado es logico (`deleted=true`) hasta que el sync confirma el
/// borrado remoto.
class AccountsRepository {
  AccountsRepository(this._db);

  final AppDatabase _db;

  Stream<List<Account>> watchAll() {
    return (_db.select(
      _db.accounts,
    )..where((a) => a.deleted.equals(false))).watch();
  }

  Future<Account?> getById(String id) => (_db.select(
    _db.accounts,
  )..where((a) => a.id.equals(id) & a.deleted.equals(false))).getSingleOrNull();

  Future<void> create(Account account) => _db
      .into(_db.accounts)
      .insert(
        AccountsCompanion.insert(
          id: account.id,
          name: account.name,
          type: account.type,
          icon: account.icon,
          color: account.color,
          initialBalance: Value(account.initialBalance),
          currentBalance: Value(account.currentBalance),
          createdAt: Value(account.createdAt),
        ),
      );

  Future<void> update(Account account) => (_db.update(
    _db.accounts,
  )..where((a) => a.id.equals(account.id))).write(
    AccountsCompanion(
      name: Value(account.name),
      type: Value(account.type),
      icon: Value(account.icon),
      color: Value(account.color),
      initialBalance: Value(account.initialBalance),
      currentBalance: Value(account.currentBalance),
      dirty: const Value(true),
    ),
  );

  Future<void> delete(String id) => (_db.update(
    _db.accounts,
  )..where((a) => a.id.equals(id))).write(
    const AccountsCompanion(deleted: Value(true), dirty: Value(true)),
  );

  Future<void> adjustBalance(String accountId, double delta) async {
    final account = await getById(accountId);
    if (account == null) return;
    await (_db.update(
      _db.accounts,
    )..where((a) => a.id.equals(accountId))).write(
      AccountsCompanion(
        currentBalance: Value(account.currentBalance + delta),
        dirty: const Value(true),
      ),
    );
  }
}

final accountsRepositoryProvider = Provider<AccountsRepository>((ref) {
  return AccountsRepository(ref.watch(databaseProvider));
});

final accountsStreamProvider = StreamProvider<List<Account>>((ref) {
  return ref.watch(accountsRepositoryProvider).watchAll();
});
