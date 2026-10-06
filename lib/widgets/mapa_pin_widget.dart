import 'dart:async';
import 'dart:js_interop';
import 'dart:ui_web' as ui;
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;
import '../services/maps_service.dart';

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
  StreamSubscription<web.MessageEvent>? _msgSub;
  JSFunction? _jsHandler;

  @override
  void initState() {
    super.initState();
    final stamp = DateTime.now().millisecondsSinceEpoch;
    _viewId = 'mapa-pin-$stamp';
    _eventName = 'mapa_pin_dragend_$stamp';

    ui.platformViewRegistry.registerViewFactory(_viewId, (int viewId) {
      final container = web.document.createElement('div') as web.HTMLDivElement;
      container.id = _viewId;
      container.style.width = '100%';
      container.style.height = '100%';

      final script = web.document.createElement('script') as web.HTMLScriptElement;
      script.textContent = '''
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

      container.appendChild(script);
      return container;
    });

    final handler = (web.MessageEvent event) {
      try {
        final data = event.data;
        if (data == null) return;
        final map = (data as JSObject).dartify() as Map?;
        if (map == null) return;
        final type = map['type']?.toString();
        if (type == _eventName) {
          final lat = (map['lat'] as num?)?.toDouble();
          final lng = (map['lng'] as num?)?.toDouble();
          if (lat != null && lng != null && mounted) {
            MapsService.coordsADireccion(lat, lng).then((dir) {
              if (mounted) widget.onPinMovido?.call(lat, lng, dir ?? '');
            });
          }
        }
      } catch (_) {}
    }.toJS;
    web.window.addEventListener('message', handler);
    _msgSub = Stream<web.MessageEvent>.empty().listen((_) {});
    // guardamos el handler para removeEventListener en dispose
    _jsHandler = handler;
  }

  @override
  void dispose() {
    _msgSub?.cancel();
    if (_jsHandler != null) {
      web.window.removeEventListener('message', _jsHandler!);
    }
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
