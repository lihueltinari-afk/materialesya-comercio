import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String _prod = 'https://materialesya-backend-production.up.railway.app/api';
  static String get _base => kIsWeb ? _prod : 'http://10.0.2.2:3000/api';

  // ── Token y sesión ──────────────────────────────────────────────────────────
  static Future<void> guardarToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token_comercio', token);
  }

  static Future<String?> obtenerToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token_comercio');
  }

  static Future<void> guardarComercioId(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('comercio_id', id);
  }

  static Future<int?> obtenerComercioId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('comercio_id');
  }

  static Future<void> cerrarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token_comercio');
    await prefs.remove('usuario_comercio');
    await prefs.remove('comercio_id');
  }

  static Future<Map<String, String>> _headers({bool auth = false}) async {
    final h = {'Content-Type': 'application/json'};
    if (auth) {
      final token = await obtenerToken();
      if (token != null) h['Authorization'] = 'Bearer $token';
    }
    return h;
  }

  // ── Auth ────────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('$_base/auth/login'),
      headers: await _headers(),
      body: jsonEncode({'email': email, 'password': password}),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200) {
      await guardarToken(data['token']);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('usuario_comercio', jsonEncode(data['usuario']));
    }
    return {'status': res.statusCode, 'data': data};
  }

  // ── Mi comercio ─────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>?> miComercio() async {
    final res = await http.get(
      Uri.parse('$_base/comercio/mi-comercio'),
      headers: await _headers(auth: true),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      await guardarComercioId(data['id'] as int);
      return data;
    }
    return null;
  }

  static Future<bool> actualizarAbierto(int comercioId, bool abierto) async {
    final res = await http.patch(
      Uri.parse('$_base/comercio/$comercioId'),
      headers: await _headers(auth: true),
      body: jsonEncode({'abierto': abierto}),
    );
    return res.statusCode == 200;
  }

  // ── Pedidos del comercio ────────────────────────────────────────────────────
  static Future<List<dynamic>> pedidosDelComercio(int comercioId, {String? estado}) async {
    String url = '$_base/comercio/$comercioId/pedidos';
    if (estado != null) url += '?estado=$estado';
    final res = await http.get(Uri.parse(url), headers: await _headers(auth: true));
    if (res.statusCode == 200) return jsonDecode(res.body);
    return [];
  }

  static Future<bool> cambiarEstadoPedido(int pedidoId, String estado) async {
    final res = await http.patch(
      Uri.parse('$_base/pedidos/$pedidoId/estado'),
      headers: await _headers(auth: true),
      body: jsonEncode({'estado': estado}),
    );
    return res.statusCode == 200;
  }

  // ── Catálogo ────────────────────────────────────────────────────────────────
  static Future<List<dynamic>> buscarCatalogo({String? busqueda, int? categoriaId}) async {
    String url = '$_base/productos?limit=50';
    if (categoriaId != null) url += '&categoria_id=$categoriaId';
    if (busqueda != null && busqueda.isNotEmpty) url += '&busqueda=${Uri.encodeComponent(busqueda)}';
    final res = await http.get(Uri.parse(url), headers: await _headers(auth: true));
    if (res.statusCode == 200) return jsonDecode(res.body);
    return [];
  }

  static Future<List<dynamic>> obtenerCategorias() async {
    final res = await http.get(Uri.parse('$_base/productos/categorias'), headers: await _headers());
    if (res.statusCode == 200) return jsonDecode(res.body);
    return [];
  }

  // ── Productos del comercio ──────────────────────────────────────────────────
  static Future<List<dynamic>> misProductos(int comercioId) async {
    final res = await http.get(
      Uri.parse('$_base/comercio/$comercioId/productos'),
      headers: await _headers(auth: true),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    return [];
  }

  static Future<bool> activarProducto(int comercioId, int productoId, double precio, int stock) async {
    final res = await http.post(
      Uri.parse('$_base/comercio/$comercioId/productos'),
      headers: await _headers(auth: true),
      body: jsonEncode({'producto_id': productoId, 'precio': precio, 'stock': stock}),
    );
    return res.statusCode == 201;
  }

  static Future<bool> actualizarProducto(int comercioId, int productoId, double precio, int stock) async {
    final res = await http.patch(
      Uri.parse('$_base/comercio/$comercioId/productos/$productoId'),
      headers: await _headers(auth: true),
      body: jsonEncode({'precio': precio, 'stock': stock}),
    );
    return res.statusCode == 200;
  }
}
