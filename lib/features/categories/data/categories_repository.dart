import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';

/// Persistencia de categorias: siempre local (Drift) -- ver
/// AccountsRepository para el detalle del patron dirty/soft-delete + sync.
/// Los defaults se siembran una sola vez al crear la base (ver
/// AppDatabase.onCreate), sin importar el modo (local o nube).
class CategoriesRepository {
  CategoriesRepository(this._db);

  final AppDatabase _db;

  Stream<List<Category>> watchAll() {
    return (_db.select(
      _db.categories,
    )..where((c) => c.deleted.equals(false))).watch();
  }

  Stream<List<Category>> watchByType(String type) {
    return (_db.select(_db.categories)
          ..where((c) => c.type.equals(type) & c.deleted.equals(false)))
        .watch();
  }

  Future<void> create(Category category) => _db
      .into(_db.categories)
      .insert(
        CategoriesCompanion.insert(
          id: category.id,
          name: category.name,
          type: category.type,
          parentId: Value(category.parentId),
          icon: category.icon,
          color: category.color,
          isDefault: Value(category.isDefault),
        ),
      );

  Future<void> update(Category category) =>
      (_db.update(_db.categories)..where((c) => c.id.equals(category.id)))
          .write(
            CategoriesCompanion(
              name: Value(category.name),
              type: Value(category.type),
              parentId: Value(category.parentId),
              icon: Value(category.icon),
              color: Value(category.color),
              dirty: const Value(true),
            ),
          );

  Future<void> delete(String id) =>
      (_db.update(_db.categories)..where((c) => c.id.equals(id))).write(
        const CategoriesCompanion(deleted: Value(true), dirty: Value(true)),
      );
}

final categoriesRepositoryProvider = Provider<CategoriesRepository>((ref) {
  return CategoriesRepository(ref.watch(databaseProvider));
});

final categoriesStreamProvider = StreamProvider<List<Category>>((ref) {
  return ref.watch(categoriesRepositoryProvider).watchAll();
});
