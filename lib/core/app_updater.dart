// Actualizador propio para apps Flutter distribuidas fuera de Google Play.
//
// Copiar este archivo a lib/core/app_updater.dart (o donde viva el resto de "core/").
// Consulta https://<portfolio>/api/projects/<slug>/update, compara la version publicada
// contra la version instalada, y si hay una nueva muestra un dialogo con el changelog.
// Al aceptar, abre la URL de descarga en el navegador del sistema: Android descarga el APK
// y ofrece instalarlo encima del anterior (misma firma + mismo applicationId => no se
// pierden datos), exactamente el mismo flujo que usan las apps distribuidas por APK directo.
//
// Dependencias necesarias en pubspec.yaml (agregar solo las que falten):
//   package_info_plus: ^8.0.0
//   http: ^1.2.0
//   url_launcher: ^6.3.0
//   shared_preferences: ^2.3.0
//
// Uso (en main.dart, despues del primer frame para no bloquear el arranque):
//
//   WidgetsBinding.instance.addPostFrameCallback((_) {
//     AppUpdater.checkForUpdate(context, slug: 'finanzas360');
//   });

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class AppUpdater {
  AppUpdater._();

  static const _prefsSkippedVersionKey = 'app_updater_skipped_version';

  /// Dominio del portafolio que sirve `/api/projects/<slug>/update`.
  /// Cambiar solo si el dominio publico cambia.
  static const String defaultBaseUrl =
      'https://portfolio-five-zeta-xf21p0a5se.vercel.app';

  /// Revisa si hay una version nueva y, si aplica, muestra el dialogo de actualizacion.
  /// Nunca lanza: cualquier error de red o parseo se ignora silenciosamente para no
  /// afectar el arranque de la app.
  static Future<void> checkForUpdate(
    BuildContext context, {
    required String slug,
    String baseUrl = defaultBaseUrl,
  }) async {
    try {
      final info = await _fetchUpdateInfo(slug, baseUrl);
      if (info == null) return;

      final packageInfo = await PackageInfo.fromPlatform();
      final installed = _parseVersion(packageInfo.version);
      final remote = _parseVersion(info.version);
      if (installed == null || remote == null) return;

      final hasUpdate = _compareVersions(remote, installed) > 0;
      if (!hasUpdate) return;

      final required =
          info.minSupportedVersion != null &&
          (_parseVersion(info.minSupportedVersion!) != null) &&
          _compareVersions(
                installed,
                _parseVersion(info.minSupportedVersion!)!,
              ) <
              0;

      if (!required) {
        final prefs = await SharedPreferences.getInstance();
        final skipped = prefs.getString(_prefsSkippedVersionKey);
        if (skipped == info.version) {
          return; // el usuario ya dijo "más tarde" para esta version
        }
      }

      if (!context.mounted) return;
      await _showUpdateDialog(context, info, required: required);
    } catch (_) {
      // Silencioso a proposito: un fallo de red nunca debe bloquear el arranque de la app.
    }
  }

  static Future<_UpdateInfo?> _fetchUpdateInfo(
    String slug,
    String baseUrl,
  ) async {
    final uri = Uri.parse('$baseUrl/api/projects/$slug/update');
    final response = await http.get(uri).timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) return null;
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final version = json['version'] as String?;
    final apkUrl = json['apk_url'] as String?;
    if (version == null || apkUrl == null) return null;
    return _UpdateInfo(
      version: version,
      minSupportedVersion: json['minSupportedVersion'] as String?,
      apkUrl: apkUrl,
      changes: (json['changes'] as List?)?.cast<String>() ?? const [],
    );
  }

  static Future<void> _showUpdateDialog(
    BuildContext context,
    _UpdateInfo info, {
    required bool required,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: !required,
      builder: (dialogContext) {
        return PopScope(
          canPop: !required,
          child: AlertDialog(
            title: Text(
              'Nueva versión disponible (${_displayVersion(info.version)})',
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (required)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Esta actualización es obligatoria para seguir usando la app.',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  if (info.changes.isNotEmpty) ...[
                    const Text(
                      'Novedades:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    ...info.changes.map(
                      (c) => Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text('• $c'),
                      ),
                    ),
                  ] else
                    const Text('¿Deseas actualizar ahora?'),
                ],
              ),
            ),
            actions: [
              if (!required)
                TextButton(
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString(
                      _prefsSkippedVersionKey,
                      info.version,
                    );
                    if (dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                    }
                  },
                  child: const Text('Más tarde'),
                ),
              FilledButton(
                onPressed: () async {
                  await launchUrl(
                    Uri.parse(info.apkUrl),
                    mode: LaunchMode.externalApplication,
                  );
                  if (!required && dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                  }
                },
                child: const Text('Actualizar'),
              ),
            ],
          ),
        );
      },
    );
  }

  static String _displayVersion(String v) =>
      v.startsWith('v') ? v.substring(1) : v;

  static List<int>? _parseVersion(String raw) {
    final cleaned = _displayVersion(
      raw,
    ).split('+').first; // corta build suffix tipo 1.2.0+15
    final parts = cleaned.split('.');
    final nums = <int>[];
    for (final p in parts) {
      final n = int.tryParse(p.trim());
      if (n == null) return null;
      nums.add(n);
    }
    while (nums.length < 3) {
      nums.add(0);
    }
    return nums;
  }

  /// Retorna >0 si [a] es mayor que [b], <0 si es menor, 0 si son iguales.
  static int _compareVersions(List<int> a, List<int> b) {
    for (var i = 0; i < a.length && i < b.length; i++) {
      if (a[i] != b[i]) return a[i] - b[i];
    }
    return 0;
  }
}

class _UpdateInfo {
  final String version;
  final String? minSupportedVersion;
  final String apkUrl;
  final List<String> changes;

  _UpdateInfo({
    required this.version,
    required this.minSupportedVersion,
    required this.apkUrl,
    required this.changes,
  });
}
