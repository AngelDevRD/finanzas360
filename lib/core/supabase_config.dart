/// Configuracion del proyecto Supabase de Finanzas 360 (modo nube).
///
/// La anon key es publica por diseno (protegida por RLS en el backend, no es
/// un secreto) -- por eso se puede commitear, igual que google-services.json
/// en un proyecto Firebase.
class SupabaseConfig {
  static const url = 'https://hdvjzzgyoukalxrfgvhx.supabase.co';
  static const publishableKey =
      'sb_publishable_UyY0WjwD8Q3JF8ruIV-NXw_5kzNs2js';
}
