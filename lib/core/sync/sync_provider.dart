import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../features/auth/data/auth_repository.dart';
import '../database/database_provider.dart';
import '../storage_mode.dart';
import '../supabase_config.dart';
import 'entities/account_syncable.dart';
import 'entities/budget_syncable.dart';
import 'entities/category_syncable.dart';
import 'entities/debt_syncable.dart';
import 'entities/savings_goal_syncable.dart';
import 'entities/transaction_syncable.dart';
import 'sync_engine.dart';
import 'sync_settings.dart';

/// Mantiene vivo el SyncEngine mientras el modo Nube este activo y haya
/// sesion iniciada. Se recrea automaticamente si cambia el modo, el usuario o
/// la frecuencia elegida en Ajustes (Riverpod dispone la instancia anterior y
/// arranca una nueva con el intervalo actualizado).
final syncEngineProvider = Provider<SyncEngine?>((ref) {
  // Orden importa: currentUserProvider toca Supabase.instance, que nunca se
  // inicializa en modo local -- debe evaluarse solo despues de confirmar
  // modo Nube (mismo invariante que MyApp.build en main.dart).
  final mode = ref.watch(storageModeProvider);
  if (mode != StorageMode.cloud || !SupabaseConfig.configurado) return null;

  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  final frequency = ref.watch(syncFrequencyProvider);
  final client = sb.Supabase.instance.client;
  final db = ref.watch(databaseProvider);

  final engine = SyncEngine(
    db: db,
    backupInterval: frequency.interval,
    entities: [
      CategorySyncable(client),
      AccountSyncable(client),
      BudgetSyncable(client),
      SavingsGoalSyncable(client),
      TransactionSyncable(client),
      DebtSyncable(client),
    ],
  )..start();

  ref.onDispose(engine.dispose);
  return engine;
});
