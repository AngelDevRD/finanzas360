import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../accounts/data/accounts_repository.dart';

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

final transactionsRepositoryProvider = Provider<TransactionsRepository>((ref) {
  return LocalTransactionsRepository(
    ref.watch(databaseProvider),
    ref.watch(accountsRepositoryProvider),
  );
});

final transactionsStreamProvider = StreamProvider<List<Transaction>>((ref) {
  return ref.watch(transactionsRepositoryProvider).watchAll();
});
