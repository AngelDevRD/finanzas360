import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';

/// Persistencia de deudas: siempre local (Drift) -- ver AccountsRepository
/// para el detalle del patron dirty/soft-delete + sync.
class DebtsRepository {
  DebtsRepository(this._db);

  final AppDatabase _db;

  Stream<List<Debt>> watchAll() {
    return (_db.select(_db.debts)..where((d) => d.deleted.equals(false)))
        .watch();
  }

  Future<void> create(Debt debt) => _db
      .into(_db.debts)
      .insert(
        DebtsCompanion.insert(
          id: debt.id,
          name: debt.name,
          description: Value(debt.description),
          totalAmount: debt.totalAmount,
          remainingAmount: debt.remainingAmount,
          dueDate: Value(debt.dueDate),
          icon: debt.icon,
          color: debt.color,
          createdAt: Value(debt.createdAt),
        ),
      );

  Future<void> update(Debt debt) =>
      (_db.update(_db.debts)..where((d) => d.id.equals(debt.id))).write(
        DebtsCompanion(
          name: Value(debt.name),
          description: Value(debt.description),
          totalAmount: Value(debt.totalAmount),
          remainingAmount: Value(debt.remainingAmount),
          dueDate: Value(debt.dueDate),
          icon: Value(debt.icon),
          color: Value(debt.color),
          dirty: const Value(true),
        ),
      );

  Future<void> delete(String id) =>
      (_db.update(_db.debts)..where((d) => d.id.equals(id))).write(
        const DebtsCompanion(deleted: Value(true), dirty: Value(true)),
      );

  /// Registra un pago: reduce el monto pendiente sin bajar de cero.
  Future<void> registerPayment(String debtId, double amount) async {
    final debt = await (_db.select(
      _db.debts,
    )..where((d) => d.id.equals(debtId))).getSingleOrNull();
    if (debt == null) return;
    final newRemaining = (debt.remainingAmount - amount).clamp(
      0,
      debt.totalAmount,
    );
    await (_db.update(_db.debts)..where((d) => d.id.equals(debtId))).write(
      DebtsCompanion(
        remainingAmount: Value(newRemaining.toDouble()),
        dirty: const Value(true),
      ),
    );
  }
}

final debtsRepositoryProvider = Provider<DebtsRepository>((ref) {
  return DebtsRepository(ref.watch(databaseProvider));
});

final debtsStreamProvider = StreamProvider<List<Debt>>((ref) {
  return ref.watch(debtsRepositoryProvider).watchAll();
});
