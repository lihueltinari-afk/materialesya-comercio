// Pantalla para fijar la ubicación exacta del comercio en un mapa, evitando que quede mal
// cargada (ej: una calle de otra ciudad). Busca la dirección escrita con Nominatim
// (OpenStreetMap, gratuito, sin API key) para centrar el mapa, y el usuario confirma/ajusta
// el pin a mano tocando el mapa antes de guardar.
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
  bool _buscando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _direccionCtrl = TextEditingController(text: widget.direccionInicial);
    if (widget.latInicial != null && widget.lngInicial != null) {
      _pin = LatLng(widget.latInicial!, widget.lngInicial!);
    } else if (widget.direccionInicial.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _buscarDireccion());
    }
  }

  Future<void> _buscarDireccion() async {
    if (_direccionCtrl.text.trim().isEmpty) return;
    setState(() { _buscando = true; _error = null; });
    try {
      final query = Uri.encodeComponent('${_direccionCtrl.text.trim()}, Mendoza, Argentina');
      final res = await http.get(
        Uri.parse('https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=1'),
        headers: {'User-Agent': 'MaterialesYa/1.0'},
      ).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List;
        if (data.isNotEmpty) {
          final lat = double.parse(data[0]['lat']);
          final lng = double.parse(data[0]['lon']);
          setState(() => _pin = LatLng(lat, lng));
          _mapController.move(_pin, 16);
        } else {
          setState(() => _error = 'No encontramos esa dirección. Movete en el mapa y tocá para marcar el lugar exacto.');
        }
      }
    } catch (_) {
      setState(() => _error = 'No se pudo buscar la dirección. Movete en el mapa y tocá para marcar el lugar.');
    } finally {
      if (mounted) setState(() => _buscando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirmá la ubicación'), backgroundColor: Colors.white, foregroundColor: _textDark, elevation: 0.5),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Expanded(child: TextField(
              controller: _direccionCtrl,
              onSubmitted: (_) => _buscarDireccion(),
              decoration: InputDecoration(
                hintText: 'Dirección (ej: Av. San Martín 1234)',
                filled: true, fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            )),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _buscando ? null : _buscarDireccion,
              style: ElevatedButton.styleFrom(backgroundColor: _amber, foregroundColor: Colors.white),
              child: _buscando ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.search),
            ),
          ]),
        ),
        if (_error != null) Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Text('Tocá el mapa para ajustar el punto exacto de tu local. Así nos aseguramos de que no quede en otra calle o ciudad.',
            style: TextStyle(fontSize: 12, color: Colors.grey)),
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
