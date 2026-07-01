import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

class RemoteConfigService {
  static final _rc = FirebaseRemoteConfig.instance;
  static bool _inicializado = false;

  static Future<void> init() async {
    if (_inicializado) return;
    try {
      await _rc.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: kDebugMode ? Duration.zero : const Duration(hours: 1),
      ));
      await _rc.setDefaults({
        'comision_productos_porcentaje': 15,
        'mantenimiento_activo': false,
        'mensaje_mantenimiento': '',
        'version_minima_requerida': '1.0.0',
        'mostrar_banner_promocional': false,
        'texto_banner_promocional': '',
      });
      await _rc.fetchAndActivate();
      _inicializado = true;
    } catch (e) {
      debugPrint('[RemoteConfig] Error: $e');
    }
  }

  static bool get mantenimientoActivo => _rc.getBool('mantenimiento_activo');
  static String get mensajeMantenimiento => _rc.getString('mensaje_mantenimiento');
  static int get comisionPorcentaje => _rc.getInt('comision_productos_porcentaje');
  static bool get mostrarBanner => _rc.getBool('mostrar_banner_promocional');
  static String get textoBanner => _rc.getString('texto_banner_promocional');
  static String get versionMinima => _rc.getString('version_minima_requerida');
}
