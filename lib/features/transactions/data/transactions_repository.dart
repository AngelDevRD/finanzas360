import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/storage_mode.dart';
import '../../accounts/data/accounts_repository.dart';
import '../../auth/data/auth_repository.dart';

abstract class TransactionsRepository {
  Stream<List<Transaction>> watchAll();
  Stream<List<Transaction>> watchInRange(DateTime start, DateTime end);
  Future<void> create(Transaction transaction);
  Future<void> update(Transaction oldTransaction, Transaction newTransaction);
  Future<void> delete(Transaction transaction);
}

class LocalTransactionsRepository implements TransactionsRepository {
  LocalTransactionsRepository(this._db, this._accountsRepository);

  final AppDatabase _db;
  final AccountsRepository _accountsRepository;

  @override
  Stream<List<Transaction>> watchAll() {
    return (_db.select(
      _db.transactions,
    )..orderBy([(t) => OrderingTerm.desc(t.date)])).watch();
  }

  @override
  Stream<List<Transaction>> watchInRange(DateTime start, DateTime end) {
    return (_db.select(_db.transactions)
          ..where((t) => t.date.isBetweenValues(start, end))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .watch();
  }

  double _signedAmount(Transaction t) =>
      t.type == 'income' ? t.amount : -t.amount;

  @override
  Future<void> create(Transaction transaction) async {
    await _db.transaction(() async {
      await _db.into(_db.transactions).insert(transaction);
      await _accountsRepository.adjustBalance(
        transaction.accountId,
        _signedAmount(transaction),
      );
    });
  }

  @override
  Future<void> update(
    Transaction oldTransaction,
    Transaction newTransaction,
  ) async {
    await _db.transaction(() async {
      await _db.update(_db.transactions).replace(newTransaction);
      // revierte el efecto de la transaccion anterior y aplica la nueva
      await _accountsRepository.adjustBalance(
        oldTransaction.accountId,
        -_signedAmount(oldTransaction),
      );
      await _accountsRepository.adjustBalance(
        newTransaction.accountId,
        _signedAmount(newTransaction),
      );
    });
  }

  @override
  Future<void> delete(Transaction transaction) async {
    await _db.transaction(() async {
      await (_db.delete(
        _db.transactions,
      )..where((t) => t.id.equals(transaction.id))).go();
      await _accountsRepository.adjustBalance(
        transaction.accountId,
        -_signedAmount(transaction),
      );
    });
  }
}

class RemoteTransactionsRepository implements TransactionsRepository {
  RemoteTransactionsRepository(
    this._client,
    this._userId,
    this._accountsRepository,
  );

  final SupabaseClient _client;
  final String _userId;
  final AccountsRepository _accountsRepository;

  static const _table = 'finanzas360_transactions';

  Transaction _fromRow(Map<String, dynamic> row) => Transaction(
    id: row['id'] as String,
    accountId: row['account_id'] as String,
    categoryId: row['category_id'] as String,
    type: row['type'] as String,
    amount: (row['amount'] as num).toDouble(),
    date: DateTime.parse(row['date'] as String),
    description: row['description'] as String,
    paymentMethod: row['payment_method'] as String,
    note: row['note'] as String,
    receiptPath: row['receipt_path'] as String?,
    createdAt: DateTime.parse(row['created_at'] as String),
  );

  Map<String, dynamic> _toRow(Transaction t) => {
    'id': t.id,
    'user_id': _userId,
    'account_id': t.accountId,
    'category_id': t.categoryId,
    'type': t.type,
    'amount': t.amount,
    'date': t.date.toIso8601String(),
    'description': t.description,
    'payment_method': t.paymentMethod,
    'note': t.note,
    'receipt_path': t.receiptPath,
  };

  double _signedAmount(Transaction t) =>
      t.type == 'income' ? t.amount : -t.amount;

  @override
  Stream<List<Transaction>> watchAll() {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('user_id', _userId)
        .order('date')
        .map((rows) => rows.reversed.map(_fromRow).toList());
  }

  @override
  Stream<List<Transaction>> watchInRange(DateTime start, DateTime end) {
    return watchAll().map(
      (all) => all
          .where((t) => !t.date.isBefore(start) && !t.date.isAfter(end))
          .toList(),
    );
  }

  // Nota: a diferencia de LocalTransactionsRepository, aqui la escritura de
  // la transaccion y el ajuste de saldo no son atomicos (dos llamadas REST
  // separadas) -- aceptable para el alcance actual, sin RPC/Postgres function.
  @override
  Future<void> create(Transaction transaction) async {
    await _client.from(_table).insert(_toRow(transaction));
    await _accountsRepository.adjustBalance(
      transaction.accountId,
      _signedAmount(transaction),
    );
  }

  @override
  Future<void> update(
    Transaction oldTransaction,
    Transaction newTransaction,
  ) async {
    await _client
        .from(_table)
        .update(_toRow(newTransaction))
        .eq('id', newTransaction.id);
    await _accountsRepository.adjustBalance(
      oldTransaction.accountId,
      -_signedAmount(oldTransaction),
    );
    await _accountsRepository.adjustBalance(
      newTransaction.accountId,
      _signedAmount(newTransaction),
    );
  }

  @override
  Future<void> delete(Transaction transaction) async {
    await _client.from(_table).delete().eq('id', transaction.id);
    await _accountsRepository.adjustBalance(
      transaction.accountId,
      -_signedAmount(transaction),
    );
  }
}

final transactionsRepositoryProvider = Provider<TransactionsRepository>((ref) {
  final accountsRepository = ref.watch(accountsRepositoryProvider);
  if (ref.watch(storageModeProvider) == StorageMode.cloud) {
    final user = ref.watch(currentUserProvider);
    if (user != null) {
      return RemoteTransactionsRepository(
        Supabase.instance.client,
        user.id,
        accountsRepository,
      );
    }
  }
  return LocalTransactionsRepository(
    ref.watch(databaseProvider),
    accountsRepository,
  );
});

final transactionsStreamProvider = StreamProvider<List<Transaction>>((ref) {
  return ref.watch(transactionsRepositoryProvider).watchAll();
});
