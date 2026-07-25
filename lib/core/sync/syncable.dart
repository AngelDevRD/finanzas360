import '../database/app_database.dart';

/// Contrato que implementa cada entidad sincronizable (una tabla local con
/// columnas `dirty`/`deleted`). El [SyncEngine] no conoce nada de
/// Accounts/Transactions en concreto: solo recorre una lista de
/// [SyncableEntity] y llama a estos métodos.
abstract class SyncableEntity {
  /// Nombre corto para logs/errores.
  String get name;

  /// Sube al backend todas las filas locales marcadas `dirty=true` de esta
  /// entidad (upsert por id, o delete si `deleted=true`). Deja `dirty=false`
  /// en cada fila que se subió con éxito; borra localmente las que ya se
  /// eliminaron en el servidor.
  Future<void> push(AppDatabase db);
}
