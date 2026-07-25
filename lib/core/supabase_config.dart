/// Configuracion del proyecto Supabase de Finanzas 360 (modo nube), inyectada
/// en build time (AG-CORE-004: las claves nunca van en el código):
///   flutter build apk --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
///
/// Sin estas variables la app funciona igual en modo local (ver
/// StorageMode.local en storage_mode.dart) -- main.dart solo inicializa
/// Supabase cuando [configurado] es true.
abstract final class SupabaseConfig {
  static const url = String.fromEnvironment('SUPABASE_URL');
  static const publishableKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get configurado => url.isNotEmpty && publishableKey.isNotEmpty;
}
