import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/database/seed/default_categories.dart';
import '../../../core/storage_mode.dart';
import '../../auth/data/auth_repository.dart';

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

class RemoteCategoriesRepository implements CategoriesRepository {
  RemoteCategoriesRepository(this._client, this._userId);

  final SupabaseClient _client;
  final String _userId;

  static const _table = 'categories';

  Category _fromRow(Map<String, dynamic> row) => Category(
    id: row['id'] as String,
    name: row['name'] as String,
    type: row['type'] as String,
    parentId: row['parent_id'] as String?,
    icon: row['icon'] as String,
    color: (row['color'] as num).toInt(),
    isDefault: row['is_default'] as bool,
  );

  Map<String, dynamic> _toRow(Category category) => {
    'id': category.id,
    'user_id': _userId,
    'name': category.name,
    'type': category.type,
    'parent_id': category.parentId,
    'icon': category.icon,
    'color': category.color,
    'is_default': category.isDefault,
  };

  @override
  Stream<List<Category>> watchAll() {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('user_id', _userId)
        .map((rows) => rows.map(_fromRow).toList());
  }

  @override
  Stream<List<Category>> watchByType(String type) {
    return watchAll().map(
      (categories) => categories.where((c) => c.type == type).toList(),
    );
  }

  @override
  Future<void> create(Category category) =>
      _client.from(_table).insert(_toRow(category));

  @override
  Future<void> update(Category category) =>
      _client.from(_table).update(_toRow(category)).eq('id', category.id);

  @override
  Future<void> delete(String id) => _client.from(_table).delete().eq('id', id);

  /// Siembra las categorias por defecto la primera vez que un usuario nuevo
  /// entra en modo nube (una cuenta local ya las trae desde el onCreate de
  /// Drift; una cuenta nueva en Supabase arranca vacia).
  Future<void> seedDefaultsIfEmpty() async {
    final existing = await _client
        .from(_table)
        .select('id')
        .eq('user_id', _userId)
        .limit(1);
    if (existing.isNotEmpty) return;
    await _client
        .from(_table)
        .insert(
          kAllDefaultCategories
              .map(
                (c) => {
                  'id': c.id,
                  'user_id': _userId,
                  'name': c.name,
                  'type': c.type,
                  'parent_id': c.parentId,
                  'icon': c.icon,
                  'color': c.color,
                  'is_default': true,
                },
              )
              .toList(),
        );
  }
}

final categoriesRepositoryProvider = Provider<CategoriesRepository>((ref) {
  if (ref.watch(storageModeProvider) == StorageMode.cloud) {
    final user = ref.watch(currentUserProvider);
    if (user != null) {
      return RemoteCategoriesRepository(Supabase.instance.client, user.id);
    }
  }
  return LocalCategoriesRepository(ref.watch(databaseProvider));
});

final categoriesStreamProvider = StreamProvider<List<Category>>((ref) {
  return ref.watch(categoriesRepositoryProvider).watchAll();
});
