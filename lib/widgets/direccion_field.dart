// ignore: avoid_web_libraries_in_flutter
import 'dart:async';
import 'package:flutter/material.dart';
import '../services/maps_service.dart';

/// Campo de texto de dirección con:
/// - Autocompletado en tiempo real via Places API (requiere API key en index.html)
/// - Botón de GPS para detectar ubicación actual y hacer reverse geocoding
/// - Sin API key: el autocompletado devuelve lista vacía, el GPS sigue funcionando
class DireccionField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final Function(String direccion, double lat, double lng)?
  onDireccionSeleccionada;
  final bool mostrarBotonGps;

  const DireccionField({
    super.key,
    required this.controller,
    this.label = 'Dirección',
    this.hint = 'Ej: Av. San Martín 1234, Mendoza',
    this.onDireccionSeleccionada,
    this.mostrarBotonGps = true,
  });

  @override
  State<DireccionField> createState() => _DireccionFieldState();
}

class _DireccionFieldState extends State<DireccionField> {
  final FocusNode _focusNode = FocusNode();
  List<Map<String, String>> _sugerencias = [];
  Timer? _debounce;
  bool _buscando = false;
  bool _obtenindoGps = false;
  String? _mensajeGps;
  double? _gpsLat, _gpsLng;
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  static const _naranja = Color(0xFFE8601C);

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        // Pequeño delay para que onTap de las sugerencias se dispare antes de cerrar
        Future.delayed(const Duration(milliseconds: 150), _cerrarSugerencias);
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _cerrarSugerencias();
    widget.controller.removeListener(_onTextChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    _debounce?.cancel();
    if (widget.controller.text.length < 3) {
      _cerrarSugerencias();
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      if (!mounted) return;
      setState(() => _buscando = true);
      final sugerencias = await MapsService.autocompletar(
        widget.controller.text,
        lat: _gpsLat,
        lng: _gpsLng,
      );
      if (mounted) {
        setState(() {
          _sugerencias = sugerencias;
          _buscando = false;
        });
        if (sugerencias.isNotEmpty && _focusNode.hasFocus) {
          _mostrarSugerencias();
        }
      }
    });
  }

  void _mostrarSugerencias() {
    _cerrarSugerencias();
    _overlayEntry = OverlayEntry(
      builder:
          (ctx) => Positioned(
            width: 400,
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: const Offset(0, 56),
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 260),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: _sugerencias.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (ctx, i) {
                      final s = _sugerencias[i];
                      return ListTile(
                        leading: const Icon(
                          Icons.location_on_outlined,
                          color: _naranja,
                          size: 20,
                        ),
                        title: Text(
                          s['principal'] ?? '',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          s['secundario'] ?? '',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        onTap: () => _seleccionarSugerencia(s),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _cerrarSugerencias() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Future<void> _seleccionarSugerencia(Map<String, String> sugerencia) async {
    _cerrarSugerencias();
    final placeId = sugerencia['place_id'];
    if (placeId != null && placeId.isNotEmpty) {
      final detalle = await MapsService.detallePlace(placeId);
      if (detalle != null && mounted) {
        final dir =
            detalle['direccion'] as String? ??
            sugerencia['descripcion'] ??
            '';
        widget.controller.text = dir;
        widget.onDireccionSeleccionada?.call(
          dir,
          detalle['lat'] as double,
          detalle['lng'] as double,
        );
      }
    } else {
      widget.controller.text = sugerencia['descripcion'] ?? '';
    }
    _focusNode.unfocus();
  }

  Future<void> _obtenerUbicacionGps() async {
    setState(() {
      _obtenindoGps = true;
      _mensajeGps = null;
    });
    final pos = await MapsService.obtenerUbicacionActual();
    if (!mounted) return;
    if (pos == null) {
      setState(() {
        _obtenindoGps = false;
        _mensajeGps = '⚠ No se pudo obtener la ubicación. Verificá los permisos del navegador.';
      });
      return;
    }
    _gpsLat = pos['lat'];
    _gpsLng = pos['lng'];
    final direccion = await MapsService.coordsADireccion(pos['lat']!, pos['lng']!);
    if (!mounted) return;
    if (direccion != null) {
      widget.controller.text = direccion;
      widget.onDireccionSeleccionada?.call(direccion, pos['lat']!, pos['lng']!);
      setState(() {
        _obtenindoGps = false;
        _mensajeGps = '✓ Ubicación detectada automáticamente';
      });
    } else {
      // GPS funcionó pero sin API key no hay reverse geocoding
      widget.onDireccionSeleccionada?.call('', pos['lat']!, pos['lng']!);
      setState(() {
        _obtenindoGps = false;
        _mensajeGps = 'GPS detectado — escribí la dirección exacta';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CompositedTransformTarget(
          link: _layerLink,
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            decoration: InputDecoration(
              labelText: widget.label,
              hintText: widget.hint,
              prefixIcon: const Icon(
                Icons.location_on_outlined,
                color: _naranja,
              ),
              suffixIcon:
                  widget.mostrarBotonGps
                      ? _obtenindoGps
                          ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: _naranja,
                              ),
                            ),
                          )
                          : IconButton(
                            icon: const Icon(
                              Icons.my_location,
                              color: _naranja,
                            ),
                            onPressed: _obtenerUbicacionGps,
                            tooltip: 'Usar mi ubicación actual',
                          )
                      : _buscando
                      ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: _naranja,
                          ),
                        ),
                      )
                      : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _naranja, width: 2),
              ),
            ),
          ),
        ),
        if (_mensajeGps != null) ...[
          const SizedBox(height: 6),
          Text(
            _mensajeGps!,
            style: TextStyle(
              fontSize: 12,
              color:
                  _mensajeGps!.startsWith('✓')
                      ? Colors.green.shade700
                      : Colors.orange.shade800,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}
