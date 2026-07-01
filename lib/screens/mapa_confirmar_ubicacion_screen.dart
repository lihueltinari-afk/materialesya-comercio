// Pantalla para fijar la ubicación exacta del comercio en un mapa, evitando que quede mal
// cargada (ej: una calle de otra ciudad). Busca la dirección escrita con Nominatim
// (OpenStreetMap, gratuito, sin API key) para centrar el mapa, y el usuario confirma/ajusta
// el pin a mano tocando el mapa antes de guardar.
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

const _amber = Color(0xFFE07B00);
const _textDark = Color(0xFF1A1A1A);

class MapaConfirmarUbicacionScreen extends StatefulWidget {
  final String direccionInicial;
  final double? latInicial;
  final double? lngInicial;
  const MapaConfirmarUbicacionScreen({super.key, required this.direccionInicial, this.latInicial, this.lngInicial});
  @override
  State<MapaConfirmarUbicacionScreen> createState() => _MapaConfirmarUbicacionScreenState();
}

class _MapaConfirmarUbicacionScreenState extends State<MapaConfirmarUbicacionScreen> {
  final _mapController = MapController();
  late final TextEditingController _direccionCtrl;
  LatLng _pin = const LatLng(-32.8895, -68.8458); // centro de Mendoza por defecto
  List<Map<String, dynamic>> _sugerencias = [];
  bool _buscando = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _direccionCtrl = TextEditingController(text: widget.direccionInicial);
    if (widget.latInicial != null && widget.lngInicial != null) {
      _pin = LatLng(widget.latInicial!, widget.lngInicial!);
    } else if (widget.direccionInicial.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _buscarSugerencias(widget.direccionInicial));
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _direccionCtrl.dispose();
    super.dispose();
  }

  void _onCambioTexto(String texto) {
    _debounce?.cancel();
    if (texto.trim().length < 4) { setState(() => _sugerencias = []); return; }
    _debounce = Timer(const Duration(milliseconds: 600), () => _buscarSugerencias(texto));
  }

  Future<void> _buscarSugerencias(String texto) async {
    if (texto.trim().isEmpty) return;
    setState(() { _buscando = true; _sugerencias = []; });
    try {
      final query = Uri.encodeComponent('$texto, Mendoza, Argentina');
      final res = await http.get(
        Uri.parse('https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=5&countrycodes=ar&addressdetails=1'),
        headers: {'User-Agent': 'MaterialesYa/1.0 (materialesya@gmail.com)'},
      ).timeout(const Duration(seconds: 6));
      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body) as List;
        if (data.isEmpty) {
          setState(() { _buscando = false; _sugerencias = []; });
          return;
        }
        setState(() => _sugerencias = data.map((d) {
          final addr = d['address'] as Map<String, dynamic>? ?? {};
          final calle = addr['road'] ?? addr['pedestrian'] ?? '';
          final numero = addr['house_number'] ?? '';
          final barrio = addr['suburb'] ?? addr['neighbourhood'] ?? '';
          String nombre = calle.isNotEmpty
            ? '$calle${numero.isNotEmpty ? ' $numero' : ''}${barrio.isNotEmpty ? ', $barrio' : ''}'
            : (d['display_name'] as String).split(',').take(2).join(',');
          return {'nombre': nombre.trim(), 'lat': double.parse(d['lat']), 'lng': double.parse(d['lon'])};
        }).toList());
      }
    } catch (_) {}
    if (mounted) setState(() => _buscando = false);
  }

  void _seleccionarSugerencia(Map<String, dynamic> s) {
    _direccionCtrl.text = s['nombre'] as String;
    final pos = LatLng(s['lat'] as double, s['lng'] as double);
    setState(() { _pin = pos; _sugerencias = []; });
    _mapController.move(pos, 16);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirmá la ubicación'), backgroundColor: Colors.white, foregroundColor: _textDark, elevation: 0.5),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            TextField(
              controller: _direccionCtrl,
              onChanged: _onCambioTexto,
              decoration: InputDecoration(
                hintText: 'Ej: Av. San Martín 1234',
                prefixIcon: const Icon(Icons.search, color: _amber),
                filled: true, fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _amber)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                suffixIcon: _buscando
                  ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: _amber)))
                  : null,
              ),
            ),
            if (_sugerencias.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Column(
                  children: _sugerencias.map((s) => InkWell(
                    onTap: () => _seleccionarSugerencia(s),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(children: [
                        const Icon(Icons.location_on_outlined, color: _amber, size: 18),
                        const SizedBox(width: 10),
                        Expanded(child: Text(s['nombre'] as String,
                          style: const TextStyle(fontSize: 13, color: _textDark))),
                      ]),
                    ),
                  )).toList(),
                ),
              ),
            const SizedBox(height: 8),
            const Text('Tocá el mapa para ajustar el punto exacto.',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
          ]),
        ),
        Expanded(
          child: Stack(children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _pin,
                initialZoom: 15,
                onTap: (_, point) => setState(() => _pin = point),
              ),
              children: [
                TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.materialesya.comercio'),
                MarkerLayer(markers: [
                  Marker(point: _pin, width: 44, height: 44, child: const Icon(Icons.location_pin, color: _amber, size: 44)),
                ]),
              ],
            ),
          ]),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, {'lat': _pin.latitude, 'lng': _pin.longitude, 'direccion': _direccionCtrl.text.trim()}),
                style: ElevatedButton.styleFrom(backgroundColor: _amber, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('Confirmar esta ubicación', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}
