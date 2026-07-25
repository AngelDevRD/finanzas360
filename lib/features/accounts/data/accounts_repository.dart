import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/storage_mode.dart';
import '../../auth/data/auth_repository.dart';

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

class RemoteAccountsRepository implements AccountsRepository {
  RemoteAccountsRepository(this._client, this._userId);

  final SupabaseClient _client;
  final String _userId;

  static const _table = 'finanzas360_accounts';

  Account _fromRow(Map<String, dynamic> row) => Account(
    id: row['id'] as String,
    name: row['name'] as String,
    type: row['type'] as String,
    icon: row['icon'] as String,
    color: (row['color'] as num).toInt(),
    initialBalance: (row['initial_balance'] as num).toDouble(),
    currentBalance: (row['current_balance'] as num).toDouble(),
    createdAt: DateTime.parse(row['created_at'] as String),
  );

  Map<String, dynamic> _toRow(Account account) => {
    'id': account.id,
    'user_id': _userId,
    'name': account.name,
    'type': account.type,
    'icon': account.icon,
    'color': account.color,
    'initial_balance': account.initialBalance,
    'current_balance': account.currentBalance,
  };

  @override
  Stream<List<Account>> watchAll() {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('user_id', _userId)
        .map((rows) => rows.map(_fromRow).toList());
  }

  @override
  Future<Account?> getById(String id) async {
    final row = await _client.from(_table).select().eq('id', id).maybeSingle();
    return row == null ? null : _fromRow(row);
  }

  @override
  Future<void> create(Account account) =>
      _client.from(_table).insert(_toRow(account));

  @override
  Future<void> update(Account account) =>
      _client.from(_table).update(_toRow(account)).eq('id', account.id);

  @override
  Future<void> delete(String id) => _client.from(_table).delete().eq('id', id);

  @override
  Future<void> adjustBalance(String accountId, double delta) async {
    final account = await getById(accountId);
    if (account == null) return;
    await _client
        .from(_table)
        .update({'current_balance': account.currentBalance + delta})
        .eq('id', accountId);
  }
}

final accountsRepositoryProvider = Provider<AccountsRepository>((ref) {
  if (ref.watch(storageModeProvider) == StorageMode.cloud) {
    final user = ref.watch(currentUserProvider);
    if (user != null) {
      return RemoteAccountsRepository(Supabase.instance.client, user.id);
    }
  }
  return LocalAccountsRepository(ref.watch(databaseProvider));
});

final accountsStreamProvider = StreamProvider<List<Account>>((ref) {
  return ref.watch(accountsRepositoryProvider).watchAll();
});
