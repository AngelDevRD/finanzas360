import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Donde vive la informacion del usuario: solo en el telefono, o en la nube
/// (Supabase, requiere sesion iniciada). Los modos son excluyentes: cambiar
/// de uno a otro no migra datos automaticamente (usar Importar/Exportar).
enum StorageMode { local, cloud }

const _storageModePrefsKey = 'storage_mode';

class StorageModeController extends Notifier<StorageMode> {
  @override
  StorageMode build() {
    _loadSaved();
    return StorageMode.local;
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_storageModePrefsKey);
    if (saved == null) return;
    state = StorageMode.values.firstWhere(
      (m) => m.name == saved,
      orElse: () => StorageMode.local,
    );
  }

  Future<void> setMode(StorageMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageModePrefsKey, mode.name);
  }
}

final storageModeProvider =
    NotifierProvider<StorageModeController, StorageMode>(
      StorageModeController.new,
    );
