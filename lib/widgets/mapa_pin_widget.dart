// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:async';
// ignore: depend_on_referenced_packages
import 'dart:ui_web' as ui;
import 'package:flutter/material.dart';
import '../services/maps_service.dart';

/// Widget de mapa Google Maps con pin arrastrable para Flutter Web.
/// Usa HtmlElementView con un div que contiene el mapa JS inicializado mediante
/// un script inline — evita la necesidad de dart:js allowInterop.
/// Sin API key: aparece en gris con "For development purposes only".
/// Con API key real: mapa completo, pin arrastrable con reverse geocoding.
class MapaPinWidget extends StatefulWidget {
  final double lat;
  final double lng;
  final double height;
  final Function(double lat, double lng, String direccion)? onPinMovido;

  const MapaPinWidget({
    super.key,
    required this.lat,
    required this.lng,
    this.height = 200,
    this.onPinMovido,
  });

  @override
  State<MapaPinWidget> createState() => MapaPinWidgetState();
}

class MapaPinWidgetState extends State<MapaPinWidget> {
  late final String _viewId;
  late final String _eventName;
  StreamSubscription<html.MessageEvent>? _msgSub;

  @override
  void initState() {
    super.initState();
    final stamp = DateTime.now().millisecondsSinceEpoch;
    _viewId = 'mapa-pin-$stamp';
    _eventName = 'mapa_pin_dragend_$stamp';

    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(_viewId, (int viewId) {
      final container = html.DivElement()
        ..id = _viewId
        ..style.width = '100%'
        ..style.height = '100%';

      // Script inline que inicializa el mapa y comunica el dragend via postMessage
      final script = html.ScriptElement()
        ..innerHtml = '''
(function() {
  function tryInit() {
    if (!window.google || !window.google.maps) {
      setTimeout(tryInit, 300);
      return;
    }
    var div = document.getElementById("$_viewId");
    if (!div) return;
    var map = new google.maps.Map(div, {
      center: { lat: ${widget.lat}, lng: ${widget.lng} },
      zoom: 15,
      mapTypeControl: false,
      streetViewControl: false,
      fullscreenControl: false
    });
    var marker = new google.maps.Marker({
      position: { lat: ${widget.lat}, lng: ${widget.lng} },
      map: map,
      draggable: true
    });
    marker.addListener("dragend", function() {
      var pos = marker.getPosition();
      window.parent.postMessage({
        type: "$_eventName",
        lat: pos.lat(),
        lng: pos.lng()
      }, "*");
    });
  }
  tryInit();
})();
''';

      container.append(script);
      return container;
    });

    // Escuchar mensajes del mapa JS via postMessage
    _msgSub = html.window.onMessage.listen((event) {
      try {
        final data = event.data;
        if (data == null) return;
        final type = data['type'];
        if (type == _eventName) {
          final lat = (data['lat'] as num?)?.toDouble();
          final lng = (data['lng'] as num?)?.toDouble();
          if (lat != null && lng != null && mounted) {
            MapsService.coordsADireccion(lat, lng).then((dir) {
              if (mounted) {
                widget.onPinMovido?.call(lat, lng, dir ?? '');
              }
            });
          }
        }
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _msgSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: widget.height,
        child: HtmlElementView(viewType: _viewId),
      ),
    );
  }
}
