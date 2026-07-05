import 'package:flutter/services.dart';

/// Comparte un archivo usando el Intent.ACTION_SEND nativo de Android (vía
/// FileProvider), sin depender de un plugin de terceros. Esto evita romper
/// el build cuando el plugin de turno fija una versión de Kotlin/AGP que no
/// se puede descargar en esta red.
class NativeShare {
  static const _channel = MethodChannel('finanzas360/native_share');

  static Future<void> shareFile(String path, {String? text}) {
    return _channel.invokeMethod<void>('shareFile', {
      'path': path,
      'text': text,
    });
  }
}
