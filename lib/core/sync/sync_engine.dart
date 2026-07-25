import 'dart:async';
import 'dart:developer' as developer;

import 'package:connectivity_plus/connectivity_plus.dart';

import '../database/app_database.dart';
import 'syncable.dart';

/// Motor de sincronización genérico: recorre las [SyncableEntity] inyectadas
/// y sube lo pendiente (dirty) al backend. Se dispara al recuperar
/// conectividad y, de respaldo, con un timer periódico configurable (ver
/// SyncSettingsProvider) por si el listener de conectividad se pierde con la
/// app en background. Los datos siempre viven primero en Drift local -- esto
/// solo decide cada cuánto se replican hacia Supabase.
class SyncEngine {
  final AppDatabase db;
  final List<SyncableEntity> entities;
  Duration backupInterval;

  SyncEngine({
    required this.db,
    required this.entities,
    this.backupInterval = const Duration(hours: 3),
  });

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  Timer? _backupTimer;
  bool _syncing = false;

  void start() {
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      if (!results.contains(ConnectivityResult.none)) {
        syncNow();
      }
    });
    _backupTimer = Timer.periodic(backupInterval, (_) => syncNow());
    // Intento inicial al arrancar (por si ya hay conexión).
    syncNow();
  }

  /// Reinicia el timer periódico con un nuevo intervalo (ej. el usuario
  /// cambió la frecuencia en Ajustes). No afecta al listener de conectividad.
  void updateInterval(Duration newInterval) {
    if (newInterval == backupInterval) return;
    backupInterval = newInterval;
    _backupTimer?.cancel();
    _backupTimer = Timer.periodic(backupInterval, (_) => syncNow());
  }

  void dispose() {
    _connectivitySub?.cancel();
    _backupTimer?.cancel();
  }

  /// Corre una pasada de sync. Ignora llamadas concurrentes (lock simple:
  /// Dart es single-threaded en el isolate de UI, no hace falta un mutex).
  Future<void> syncNow() async {
    if (_syncing) return;
    _syncing = true;
    try {
      for (final entity in entities) {
        try {
          await entity.push(db);
        } catch (e, st) {
          // Una entidad fallando (ej. sin red a mitad de camino) no debe
          // frenar a las demás -- se reintenta en la próxima pasada.
          developer.log(
            'Sync falló para ${entity.name}',
            error: e,
            stackTrace: st,
            name: 'SyncEngine',
          );
        }
      }
    } finally {
      _syncing = false;
    }
  }
}
