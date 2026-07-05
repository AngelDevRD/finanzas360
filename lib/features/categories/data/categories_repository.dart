import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';

abstract class CategoriesRepository {
  Stream<List<Category>> watchAll();
  Stream<List<Category>> watchByType(String type);
  Future<void> create(Category category);
  Future<void> update(Category category);
  Future<void> delete(String id);
}

class LocalCategoriesRepository implements CategoriesRepository {
  LocalCategoriesRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<Category>> watchAll() => _db.select(_db.categories).watch();

  @override
  Stream<List<Category>> watchByType(String type) =>
      (_db.select(_db.categories)..where((c) => c.type.equals(type))).watch();

  @override
  Future<void> create(Category category) =>
      _db.into(_db.categories).insert(category);

  @override
  Future<void> update(Category category) =>
      _db.update(_db.categories).replace(category);

  @override
  Future<void> delete(String id) =>
      (_db.delete(_db.categories)..where((c) => c.id.equals(id))).go();
}

final categoriesRepositoryProvider = Provider<CategoriesRepository>((ref) {
  return LocalCategoriesRepository(ref.watch(databaseProvider));
});

final categoriesStreamProvider = StreamProvider<List<Category>>((ref) {
  return ref.watch(categoriesRepositoryProvider).watchAll();
});
