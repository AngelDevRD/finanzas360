import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../database/app_database.dart';
import '../syncable.dart';

/// Sync de Categorias contra Supabase (tabla `finanzas360_categories`). El id
/// local ES el id remoto (generado en el cliente), asi que no hace falta
/// mapeo de serverId como en otras entidades -- es upsert directo por id.
class CategorySyncable implements SyncableEntity {
  final sb.SupabaseClient client;

  CategorySyncable(this.client);

  @override
  String get name => 'categories';

  @override
  Future<void> push(AppDatabase db) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) return;

    final dirty = await (db.select(
      db.categories,
    )..where((t) => t.dirty.equals(true))).get();

    for (final category in dirty) {
      if (category.deleted) {
        await client
            .from('finanzas360_categories')
            .delete()
            .eq('id', category.id);
        await (db.delete(
          db.categories,
        )..where((t) => t.id.equals(category.id))).go();
        continue;
      }
      await client.from('finanzas360_categories').upsert({
        'id': category.id,
        'user_id': userId,
        'name': category.name,
        'type': category.type,
        'parent_id': category.parentId,
        'icon': category.icon,
        'color': category.color,
        'is_default': category.isDefault,
      });
      await (db.update(
        db.categories,
      )..where((t) => t.id.equals(category.id))).write(
        const CategoriesCompanion(dirty: Value(false)),
      );
    }
  }
}
