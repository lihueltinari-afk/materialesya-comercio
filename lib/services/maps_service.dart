import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'package:http/http.dart' as http;
import 'package:web/web.dart' as web;

class MapsService {
  static const _defaultLat = -32.8908;
  static const _defaultLng = -68.8272;

  static String? _apiKey;

  static String? get apiKey {
    if (_apiKey != null) return _apiKey;
    try {
      final scripts = web.document.querySelectorAll('script[src*="maps.googleapis.com"]');
      if (scripts.length > 0) {
        final src = (scripts.item(0) as web.HTMLScriptElement).src;
        final uri = Uri.tryParse(src);
        final key = uri?.queryParameters['key'];
        if (key != null && key != 'YOUR_GOOGLE_MAPS_API_KEY') {
          _apiKey = key;
        }
      }
    } catch (_) {}
    return _apiKey;
  }

  static Future<Map<String, double>?> obtenerUbicacionActual() async {
    final completer = Completer<Map<String, double>?>();
    try {
      web.window.navigator.geolocation.getCurrentPosition(
        (web.GeolocationPosition pos) {
          final lat = pos.coords.latitude.toDouble();
          final lng = pos.coords.longitude.toDouble();
          completer.complete({'lat': lat, 'lng': lng});
        }.toJS,
        (web.GeolocationPositionError _) {
          if (!completer.isCompleted) completer.complete(null);
        }.toJS,
      );
    } catch (_) {
      if (!completer.isCompleted) completer.complete(null);
    }
    return completer.future.timeout(const Duration(seconds: 10), onTimeout: () => null);
  }

  static Future<String?> coordsADireccion(double lat, double lng) async {
    final key = apiKey;
    if (key == null) return null;
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$key&language=es',
      );
      final res = await http.get(url).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['status'] == 'OK') {
          final results = data['results'] as List;
          if (results.isNotEmpty) return results[0]['formatted_address'] as String?;
        }
      }
    } catch (_) {}
    return null;
  }

  static Future<Map<String, double>?> direccionACoords(String direccion) async {
    final key = apiKey;
    if (key == null) return null;
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json'
        '?address=${Uri.encodeComponent('$direccion, Argentina')}&key=$key&language=es&region=AR',
      );
      final res = await http.get(url).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['status'] == 'OK') {
          final loc = (data['results'] as List)[0]['geometry']['location'];
          return {'lat': (loc['lat'] as num).toDouble(), 'lng': (loc['lng'] as num).toDouble()};
        }
      }
    } catch (_) {}
    return null;
  }

  static Future<List<Map<String, String>>> autocompletar(String input, {double? lat, double? lng}) async {
    if (input.trim().length < 2) return [];
    final key = apiKey;
    if (key == null) return [];
    try {
      var urlStr = 'https://maps.googleapis.com/maps/api/place/autocomplete/json'
          '?input=${Uri.encodeComponent(input)}&key=$key&language=es&components=country:ar&types=address';
      if (lat != null && lng != null) urlStr += '&location=$lat,$lng&radius=50000';
      final res = await http.get(Uri.parse(urlStr)).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['status'] == 'OK') {
          final predictions = data['predictions'] as List;
          return predictions.map((p) {
            final structured = p['structured_formatting'] as Map<String, dynamic>? ?? {};
            return {
              'place_id': p['place_id']?.toString() ?? '',
              'descripcion': p['description']?.toString() ?? '',
              'principal': structured['main_text']?.toString() ?? '',
              'secundario': structured['secondary_text']?.toString() ?? '',
            };
          }).toList();
        }
      }
    } catch (_) {}
    return [];
  }

  static Future<Map<String, dynamic>?> detallePlace(String placeId) async {
    final key = apiKey;
    if (key == null) return null;
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json'
        '?place_id=${Uri.encodeComponent(placeId)}&key=$key&language=es&fields=geometry,formatted_address,name',
      );
      final res = await http.get(url).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['status'] == 'OK') {
          final result = data['result'] as Map<String, dynamic>;
          final loc = result['geometry']['location'];
          return {
            'lat': (loc['lat'] as num).toDouble(),
            'lng': (loc['lng'] as num).toDouble(),
            'direccion': result['formatted_address']?.toString() ?? '',
          };
        }
      }
    } catch (_) {}
    return null;
  }

  static Future<Map<String, dynamic>?> calcularDistanciaRuta({
    required double origenLat,
    required double origenLng,
    required double destinoLat,
    required double destinoLng,
  }) async {
    final key = apiKey;
    if (key == null) return null;
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/distancematrix/json'
        '?origins=$origenLat,$origenLng&destinations=$destinoLat,$destinoLng&mode=driving&key=$key&language=es',
      );
      final res = await http.get(url).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['status'] == 'OK') {
          final element = (data['rows'] as List)[0]['elements'][0] as Map<String, dynamic>;
          if (element['status'] == 'OK') {
            return {
              'distancia_m': element['distance']['value'] as int,
              'distancia_texto': element['distance']['text']?.toString() ?? '',
              'duracion_s': element['duration']['value'] as int,
              'duracion_texto': element['duration']['text']?.toString() ?? '',
            };
          }
        }
      }
    } catch (_) {}
    return null;
  }

  static int calcularCostoEnvio(int distanciaMetros, String vehiculo) {
    final km = distanciaMetros / 1000.0;
    switch (vehiculo) {
      case 'bicicleta': return (500 + km * 50).round();
      case 'moto': return (800 + km * 80).round();
      case 'auto': return (1200 + km * 120).round();
      case 'camioneta': return (2500 + km * 200).round();
      case 'camion': return (5000 + km * 350).round();
      default: return (800 + km * 80).round();
    }
  }

  static Map<String, double> get posicionPorDefecto => {'lat': _defaultLat, 'lng': _defaultLng};
}
