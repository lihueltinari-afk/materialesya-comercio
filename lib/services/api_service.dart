import 'dart:convert';
import 'package:flutter/foundation.dart' show VoidCallback, kReleaseMode, kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static const String _apiVersion = 'v1';
  static const String _prod = 'https://materialesya-backend-production.up.railway.app/api/$_apiVersion';
  static const String _dev = 'http://localhost:3000/api/$_apiVersion';
  // MODO DEMO: forzar localhost para testing local
  static String get _base {
    const env = String.fromEnvironment('API_URL', defaultValue: '');
    if (env.isNotEmpty) return env;
    return _dev;
  }

  static String get baseUrlPublico => _base;
  static String get baseUrl => _base;
  static Future<String?> getToken() => obtenerToken();
  static VoidCallback? onSesionExpirada;
  static bool _sesionExpirandose = false;

  static Future<void> _manejarUnauthorized() async {
    if (_sesionExpirandose) return;
    _sesionExpirandose = true;
    // Intentar renovar el token antes de cerrar sesión
    final renovado = await _renovarToken();
    if (!renovado) {
      await cerrarSesion();
      onSesionExpirada?.call();
    }
    Future.delayed(const Duration(seconds: 3), () => _sesionExpirandose = false);
  }

  static Future<bool> _renovarToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('demo_email');
      final pass = prefs.getString('demo_pass');
      if (email == null || pass == null) return false;
      final res = await http.post(
        Uri.parse('$_base/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': pass}),
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        await guardarSesion(data['token'] as String, Map<String, dynamic>.from(data['usuario'] as Map));
        return true;
      }
    } catch (_) {}
    return false;
  }

  // ─── TOKEN Y SESIÓN ───────────────────────────────────────────────────────────
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static Future<void> guardarToken(String token) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token_comercio', token);
    } else {
      await _secureStorage.write(key: 'token_comercio', value: token);
    }
  }

  static Future<String?> obtenerToken() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('token_comercio');
    }
    return _secureStorage.read(key: 'token_comercio');
  }

  static Future<void> guardarSesion(String token, Map<String, dynamic> usuario) async {
    await guardarToken(token);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('usuario_comercio', jsonEncode(usuario));
  }

  static Future<void> cerrarSesion() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token_comercio');
    } else {
      await _secureStorage.delete(key: 'token_comercio');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('comercio');
  }

  static Future<void> loginDemo(String email, String password) async {
    try {
      final res = await http.post(
        Uri.parse('$_base/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        await guardarSesion(data['token'] as String, Map<String, dynamic>.from(data['usuario'] as Map));
        // Guardar credenciales para renovación automática de token
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('demo_email', email);
        await prefs.setString('demo_pass', password);
        await miComercio();
      }
    } catch (_) {}
  }

  // ─── COMERCIO LOCAL ──────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> comercioActual() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString('comercio');
    if (str == null) return null;
    return jsonDecode(str);
  }

  static Future<int?> obtenerComercioId() async {
    final c = await comercioActual();
    final id = c?['id'];
    if (id == null) return null;
    return id is int ? id : int.tryParse(id.toString());
  }

  static Future<void> guardarComercio(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('comercio', jsonEncode(data));
  }

  // ─── HEADERS ─────────────────────────────────────────────────────────────────

  static Future<Map<String, String>> _headers({bool auth = false}) async {
    final h = {'Content-Type': 'application/json'};
    if (auth) {
      final token = await obtenerToken();
      if (token != null) h['Authorization'] = 'Bearer $token';
    }
    return h;
  }

  // ─── HTTP BASE ────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final res = await http.post(
        Uri.parse('$_base/auth/login'),
        headers: await _headers(),
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 15));
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        await guardarToken(data['token']);
        if (data['comercio'] != null) await guardarComercio(data['comercio']);
      }
      return {'status': res.statusCode, 'data': data};
    } catch (e) {
      return {'status': 0, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> get(String path) async {
    try {
      final res = await http.get(
        Uri.parse('$_base$path'),
        headers: await _headers(auth: true),
      ).timeout(const Duration(seconds: 15));
      if (res.statusCode == 401) { await _manejarUnauthorized(); return {'status': 401}; }
      return {'status': res.statusCode, 'data': jsonDecode(res.body)};
    } catch (e) {
      return {'status': 0, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    try {
      final res = await http.post(
        Uri.parse('$_base$path'),
        headers: await _headers(auth: true),
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));
      if (res.statusCode == 401) { await _manejarUnauthorized(); return {'status': 401}; }
      return {'status': res.statusCode, 'data': jsonDecode(res.body)};
    } catch (e) {
      return {'status': 0, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> patch(String path, Map<String, dynamic> body) async {
    try {
      final res = await http.patch(
        Uri.parse('$_base$path'),
        headers: await _headers(auth: true),
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));
      if (res.statusCode == 401) { await _manejarUnauthorized(); return {'status': 401}; }
      return {'status': res.statusCode, 'data': jsonDecode(res.body)};
    } catch (e) {
      return {'status': 0, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> put(String path, Map<String, dynamic> body) async {
    try {
      final res = await http.put(
        Uri.parse('$_base$path'),
        headers: await _headers(auth: true),
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));
      if (res.statusCode == 401) { await _manejarUnauthorized(); return {'status': 401}; }
      return {'status': res.statusCode, 'data': jsonDecode(res.body)};
    } catch (e) {
      return {'status': 0, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> delete(String path) async {
    try {
      final res = await http.delete(
        Uri.parse('$_base$path'),
        headers: await _headers(auth: true),
      ).timeout(const Duration(seconds: 15));
      if (res.statusCode == 401) { await _manejarUnauthorized(); return {'status': 401}; }
      return {'status': res.statusCode, 'data': res.body.isNotEmpty ? jsonDecode(res.body) : {}};
    } catch (e) {
      return {'status': 0, 'error': e.toString()};
    }
  }

  // ─── MÉTODOS DE DOMINIO ───────────────────────────────────────────────────────

  /// Carga los datos del comercio desde el backend y los guarda localmente.
  static Future<Map<String, dynamic>?> miComercio() async {
    final res = await get('/comercio/mi-comercio');
    if (res['status'] == 200) {
      final data = res['data'];
      final comercio = data['comercio'] ?? data;
      await guardarComercio(comercio);
      return comercio;
    }
    return null;
  }

  /// Actualiza el estado abierto/cerrado del comercio.
  static Future<bool> actualizarAbierto(int comercioId, bool abierto) async {
    final res = await patch('/comercio/toggle-abierto', {'abierto': abierto});
    return res['status'] == 200;
  }

  /// Cambia el estado de un pedido (aceptado, preparando, listo, entregado, cancelado).
  static Future<bool> cambiarEstadoPedido(int pedidoId, String nuevoEstado) async {
    final Map<String, String> rutas = {
      'aceptado': '/comercio/pedidos/$pedidoId/aceptar',
      'cancelado': '/comercio/pedidos/$pedidoId/rechazar',
      'listo_para_retirar': '/comercio/pedidos/$pedidoId/listo',
      'listo': '/comercio/pedidos/$pedidoId/listo',
      'en_camino': '/comercio/pedidos/$pedidoId/en-camino',
      'entregado': '/comercio/pedidos/$pedidoId/entregado',
      'preparando': '/comercio/pedidos/$pedidoId/aceptar',
      'confirmado': '/comercio/pedidos/$pedidoId/aceptar',
    };
    final ruta = rutas[nuevoEstado] ?? '/comercio/pedidos/$pedidoId/estado';
    final res = await patch(ruta, {'estado': nuevoEstado});
    return res['status'] == 200;
  }

  /// Devuelve todos los pedidos del comercio (activos por defecto).
  static Future<List<dynamic>> pedidosDelComercio(int comercioId, {String? estado}) async {
    final query = estado != null ? '?estado=$estado' : '';
    final res = await get('/comercio/pedidos$query');
    if (res['status'] == 200) {
      final data = res['data'];
      if (data is List) return data;
      if (data is Map) return data['datos'] ?? data['pedidos'] ?? [];
    }
    return [];
  }

  /// Busca productos en el catálogo maestro.
  /// Trae una página del catálogo maestro (infinite scroll: la app va pidiendo de a 24
  /// productos con offset creciente a medida que el usuario llega al final de la lista).
  /// Devuelve {'productos': [...], 'hayMas': bool}.
  static Future<Map<String, dynamic>> buscarCatalogoPagina({
    String busqueda = '', int? categoriaId, int? marcaId, String? marcaNombre, int? subcategoriaId, int? rubroId, int limit = 24, int offset = 0,
  }) async {
    var query = '?limit=$limit&offset=$offset';
    if (busqueda.isNotEmpty) query += '&busqueda=${Uri.encodeComponent(busqueda)}';
    if (categoriaId != null) query += '&categoria_id=$categoriaId';
    if (marcaNombre != null && marcaNombre.isNotEmpty) query += '&marca_nombre=${Uri.encodeComponent(marcaNombre)}';
    else if (marcaId != null) query += '&marca_id=$marcaId';
    if (subcategoriaId != null) query += '&subcategoria_id=$subcategoriaId';
    if (rubroId != null) query += '&rubro_id=$rubroId';
    final res = await get('/catalogo-maestro$query');
    if (res['status'] == 200) {
      final data = res['data'];
      if (data is Map) return {'productos': data['productos'] ?? [], 'hayMas': data['hayMas'] ?? false};
      if (data is List) return {'productos': data, 'hayMas': data.length == limit};
    }
    return {'productos': [], 'hayMas': false};
  }

  /// Obtiene las categorías del catálogo.
  static Future<List<dynamic>> obtenerCategorias() async {
    final res = await get('/catalogo-maestro/categorias');
    if (res['status'] == 200) {
      final data = res['data'];
      if (data is List) return data;
      if (data is Map) return data['categorias'] ?? [];
    }
    return [];
  }

  /// Activa un producto del catálogo maestro en el comercio.
  static Future<bool> activarProducto(int comercioId, int productoMaestroId, double precio, int stock) async {
    final res = await post('/comercio/productos', {
      'producto_maestro_id': productoMaestroId,
      'precio': precio,
      'stock': stock,
    });
    return res['status'] == 200 || res['status'] == 201;
  }

  /// Obtiene los productos activos del comercio.
  static Future<List<dynamic>> misProductos() async {
    final res = await get('/comercio/mis-productos');
    if (res['status'] == 200) {
      final data = res['data'];
      if (data is List) return data;
      if (data is Map) return data['productos'] ?? [];
    }
    return [];
  }

  /// Actualiza el precio de un producto del comercio.
  static Future<bool> actualizarPrecioProducto(int productoId, double precio) async {
    final res = await patch('/comercio/productos/$productoId', {'precio': precio});
    return res['status'] == 200;
  }

  static Future<bool> actualizarStockProducto(int productoId, int stock) async {
    final res = await patch('/comercio/productos/$productoId', {'stock': stock});
    return res['status'] == 200;
  }

  /// Activa o desactiva un producto del comercio.
  static Future<bool> toggleProductoActivo(int productoId, bool activo) async {
    final res = await patch('/comercio/productos/$productoId', {'activo': activo});
    return res['status'] == 200;
  }

  /// Obtiene el detalle completo de un pedido.
  static Future<Map<String, dynamic>?> detallePedido(int pedidoId) async {
    final res = await get('/comercio/pedidos/$pedidoId');
    if (res['status'] == 200) {
      final data = res['data'];
      return data['pedido'] ?? data;
    }
    return null;
  }

  /// Acepta un pedido con tiempo estimado.
  static Future<bool> aceptarPedido(int pedidoId, int tiempoEstimadoMin) async {
    final res = await patch('/comercio/pedidos/$pedidoId/aceptar', {
      'tiempo_estimado_min': tiempoEstimadoMin,
    });
    return res['status'] == 200;
  }

  /// Rechaza un pedido con motivo.
  static Future<bool> rechazarPedido(int pedidoId, String motivo) async {
    final res = await patch('/comercio/pedidos/$pedidoId/rechazar', {
      'motivo': motivo,
    });
    return res['status'] == 200;
  }

  /// Marca un pedido como listo para retirar.
  static Future<bool> pedidoListo(int pedidoId) async {
    final res = await patch('/comercio/pedidos/$pedidoId/listo', {});
    return res['status'] == 200;
  }

  /// Devuelve estadísticas del día.
  static Future<Map<String, dynamic>?> estadisticasHoy() async {
    final res = await get('/comercio/estadisticas/hoy');
    if (res['status'] == 200) return res['data'];
    return null;
  }

  /// Actualiza el perfil del comercio.
  static Future<bool> actualizarComercio(Map<String, dynamic> datos) async {
    final res = await patch('/comercio/mi-comercio', datos);
    if (res['status'] == 200) {
      final data = res['data'];
      final comercio = data['comercio'] ?? data;
      await guardarComercio(comercio);
      return true;
    }
    return false;
  }

  /// Carga masiva de precios/stock. Recibe filas ya parseadas: [{producto_id, precio, stock}, ...]
  static Future<Map<String, dynamic>> importarProductosCsv(List<Map<String, dynamic>> productos) async {
    final res = await post('/comercio/productos/importar', {'productos': productos});
    if (res['status'] == 200) return res['data'];
    return {'actualizados': 0, 'errores': ['Error de conexión con el servidor']};
  }

  /// Obtiene el perfil del usuario logueado desde el servidor (incluye email_verificado).
  static Future<Map<String, dynamic>?> usuarioActualRemoto() async {
    final res = await get('/auth/me');
    if (res['status'] == 200) return res['data'];
    return null;
  }

  /// Guarda el email del usuario logueado para poder mostrarlo en VerificarEmailScreen.
  static Future<void> guardarEmailUsuario(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('email_usuario', email);
  }

  static Future<String?> obtenerEmailUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('email_usuario');
  }

  /// Cuenta pedidos pendientes (para badges).
  static Future<int> contarPedidosPendientes() async {
    final pedidos = await pedidosDelComercio(0, estado: 'pendiente');
    return pedidos.length;
  }
}
