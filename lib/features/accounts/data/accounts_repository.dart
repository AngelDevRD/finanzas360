import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';

/// Contrato de persistencia de cuentas. La UI y el dominio dependen solo de
/// esta interfaz; [LocalAccountsRepository] es la implementación de hoy
/// (SQLite/Drift). El día que se agregue sync, se añade una
/// `RemoteAccountsRepository`/`SyncAccountsRepository` sin tocar nada más.
abstract class AccountsRepository {
  Stream<List<Account>> watchAll();
  Future<Account?> getById(String id);
  Future<void> create(Account account);
  Future<void> update(Account account);
  Future<void> delete(String id);
  Future<void> adjustBalance(String accountId, double delta);
}

class LocalAccountsRepository implements AccountsRepository {
  LocalAccountsRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<Account>> watchAll() => _db.select(_db.accounts).watch();

  @override
  Future<Account?> getById(String id) => (_db.select(
    _db.accounts,
  )..where((a) => a.id.equals(id))).getSingleOrNull();

  @override
  Future<void> create(Account account) =>
      _db.into(_db.accounts).insert(account);

  @override
  Future<void> update(Account account) =>
      _db.update(_db.accounts).replace(account);

  @override
  Future<void> delete(String id) =>
      (_db.delete(_db.accounts)..where((a) => a.id.equals(id))).go();

  @override
  Future<void> adjustBalance(String accountId, double delta) async {
    final account = await getById(accountId);
    if (account == null) return;
    await (_db.update(
      _db.accounts,
    )..where((a) => a.id.equals(accountId))).write(
      AccountsCompanion(currentBalance: Value(account.currentBalance + delta)),
    );
  }
}

final accountsRepositoryProvider = Provider<AccountsRepository>((ref) {
  return LocalAccountsRepository(ref.watch(databaseProvider));
});

final accountsStreamProvider = StreamProvider<List<Account>>((ref) {
  return ref.watch(accountsRepositoryProvider).watchAll();
});
