import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../accounts/data/accounts_repository.dart';

/// Persistencia de transacciones: siempre local (Drift) -- ver
/// AccountsRepository para el detalle del patron dirty/soft-delete + sync.
class TransactionsRepository {
  TransactionsRepository(this._db, this._accountsRepository);

  final AppDatabase _db;
  final AccountsRepository _accountsRepository;

  Stream<List<Transaction>> watchAll() {
    return (_db.select(_db.transactions)
          ..where((t) => t.deleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .watch();
  }

  Stream<List<Transaction>> watchInRange(DateTime start, DateTime end) {
    return (_db.select(_db.transactions)
          ..where(
            (t) =>
                t.date.isBetweenValues(start, end) & t.deleted.equals(false),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .watch();
  }

  double _signedAmount(Transaction t) =>
      t.type == 'income' ? t.amount : -t.amount;

  Future<void> create(Transaction transaction) async {
    await _db.transaction(() async {
      await _db
          .into(_db.transactions)
          .insert(
            TransactionsCompanion.insert(
              id: transaction.id,
              accountId: transaction.accountId,
              categoryId: transaction.categoryId,
              type: transaction.type,
              amount: transaction.amount,
              date: transaction.date,
              description: Value(transaction.description),
              paymentMethod: Value(transaction.paymentMethod),
              note: Value(transaction.note),
              receiptPath: Value(transaction.receiptPath),
              createdAt: Value(transaction.createdAt),
            ),
          );
      await _accountsRepository.adjustBalance(
        transaction.accountId,
        _signedAmount(transaction),
      );
    });
  }

  Future<void> update(
    Transaction oldTransaction,
    Transaction newTransaction,
  ) async {
    await _db.transaction(() async {
      await (_db.update(
        _db.transactions,
      )..where((t) => t.id.equals(newTransaction.id))).write(
        TransactionsCompanion(
          accountId: Value(newTransaction.accountId),
          categoryId: Value(newTransaction.categoryId),
          type: Value(newTransaction.type),
          amount: Value(newTransaction.amount),
          date: Value(newTransaction.date),
          description: Value(newTransaction.description),
          paymentMethod: Value(newTransaction.paymentMethod),
          note: Value(newTransaction.note),
          receiptPath: Value(newTransaction.receiptPath),
          dirty: const Value(true),
        ),
      );
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

  Future<void> delete(Transaction transaction) async {
    await _db.transaction(() async {
      await (_db.update(
        _db.transactions,
      )..where((t) => t.id.equals(transaction.id))).write(
        const TransactionsCompanion(deleted: Value(true), dirty: Value(true)),
      );
      await _accountsRepository.adjustBalance(
        transaction.accountId,
        -_signedAmount(transaction),
      );
    });
  }
}

final transactionsRepositoryProvider = Provider<TransactionsRepository>((ref) {
  return TransactionsRepository(
    ref.watch(databaseProvider),
    ref.watch(accountsRepositoryProvider),
  );
});

final transactionsStreamProvider = StreamProvider<List<Transaction>>((ref) {
  return ref.watch(transactionsRepositoryProvider).watchAll();
});
