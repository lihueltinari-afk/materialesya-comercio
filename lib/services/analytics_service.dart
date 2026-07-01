import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  static final _fa = FirebaseAnalytics.instance;
  static FirebaseAnalyticsObserver get observer => FirebaseAnalyticsObserver(analytics: _fa);

  static Future<void> pedidoAceptado(String pedidoId, double monto) =>
      _fa.logEvent(name: 'pedido_aceptado', parameters: {'pedido_id': pedidoId, 'monto': monto});

  static Future<void> pedidoRechazado(String pedidoId, String motivo) =>
      _fa.logEvent(name: 'pedido_rechazado', parameters: {'pedido_id': pedidoId, 'motivo': motivo});

  static Future<void> productoAgregadoCatalogo(String nombre, double precio) =>
      _fa.logEvent(name: 'producto_agregado_catalogo', parameters: {'nombre': nombre, 'precio': precio});

  static Future<void> setUsuario(String userId) =>
      _fa.setUserId(id: userId);
}
