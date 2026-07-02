import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import '../services/api_service.dart';

// ─── Colores ──────────────────────────────────────────────────────────────────
const _amber  = Color(0xFFE07B00);
const _navy   = Color(0xFF1E3A5F);
const _dark   = Color(0xFF1A1A1A);
const _grey   = Color(0xFF888888);
const _green  = Color(0xFF2E7D32);
const _blue   = Color(0xFF1565C0);
const _yellow = Color(0xFFF57F17);
const _red    = Color(0xFFC62828);

class ExcelPreciosScreen extends StatefulWidget {
  const ExcelPreciosScreen({super.key});
  @override
  State<ExcelPreciosScreen> createState() => _ExcelPreciosScreenState();
}

class _ExcelPreciosScreenState extends State<ExcelPreciosScreen> {
  // 0=inicio  1=procesando  2=resultados  3=confirmacion  4=exito  5=historial
  int _pantalla = 0;
  bool _cargando = false;
  String? _error;
  String? _nombreArchivo;
  int? _cargaIdExito;

  // Pasos de procesamiento
  final List<int> _pasoStatus = [0, 0, 0, 0, 0]; // 0=pendiente 1=cargando 2=listo

  // Datos del resultado
  List<Map<String, dynamic>> _automaticos  = [];
  List<Map<String, dynamic>> _nuevos       = [];
  List<Map<String, dynamic>> _confirmar    = [];
  List<Map<String, dynamic>> _faltantes    = [];
  int _totalFilas = 0;

  // Decisiones por sección
  final Map<int, bool>   _selAuto     = {};   // true=aplicar (default true)
  final Map<int, bool>   _selNuevo    = {};   // false=no agregar (default false)
  final Map<int, int?>   _linkNuevo   = {};   // catalogoProductoId vinculado
  final Map<int, String?> _linkNombreNuevo = {};
  final Map<int, String> _decConfirmar= {};   // 'pendiente'|'si'|'no'|'saltear'
  final Map<int, String> _decFaltante = {};   // 'mantener'|'desactivar'|'precio_manual'
  final Map<int, TextEditingController> _precioManualCtrl = {};

  // Historial
  List<dynamic> _historial = [];
  Map<String, dynamic>? _ultimaCarga;

  @override
  void initState() {
    super.initState();
    _cargarUltimaCarga();
  }

  @override
  void dispose() {
    for (final c in _precioManualCtrl.values) c.dispose();
    super.dispose();
  }

  // ─── Router de pantallas ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F8),
      appBar: _pantalla == 4 ? null : AppBar(
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        title: Text(_tituloAppBar(), style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700)),
        leading: _pantalla > 0 && _pantalla != 4
          ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: _volverAtras)
          : null,
      ),
      body: () {
        switch (_pantalla) {
          case 0: return _buildInicio();
          case 1: return _buildProcesando();
          case 2: return _buildResultados();
          case 3: return _buildConfirmacion();
          case 4: return _buildExito();
          case 5: return _buildHistorial();
          default: return _buildInicio();
        }
      }(),
    );
  }

  String _tituloAppBar() {
    switch (_pantalla) {
      case 0: return 'Actualizar por Excel';
      case 1: return 'Procesando...';
      case 2: return 'Revisá los cambios';
      case 3: return 'Confirmación final';
      case 5: return 'Historial de cargas';
      default: return 'Actualizar por Excel';
    }
  }

  void _volverAtras() {
    if (_pantalla == 2) setState(() { _pantalla = 0; _error = null; });
    else if (_pantalla == 3) setState(() => _pantalla = 2);
    else if (_pantalla == 5) setState(() => _pantalla = 0);
    else setState(() => _pantalla = 0);
  }

  // ─── PANTALLA 0: INICIO ───────────────────────────────────────────────────

  Future<void> _cargarUltimaCarga() async {
    final r = await ApiService.get('/comercio/excel/historial');
    if (!mounted) return;
    final lista = r['data']?['historial'] as List? ?? [];
    setState(() => _ultimaCarga = lista.isNotEmpty ? Map<String, dynamic>.from(lista.first) : null);
  }

  Widget _buildInicio() {
    return ListView(padding: const EdgeInsets.all(20), children: [
      const SizedBox(height: 12),
      // Cabecera
      Center(child: Column(children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(color: _green.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
          child: const Icon(Icons.table_chart, size: 40, color: _green),
        ),
        const SizedBox(height: 12),
        Text('Actualizá tu catálogo', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w800, color: _dark)),
        const SizedBox(height: 4),
        Text('Subí tu lista de precios y la app se encarga del resto', style: GoogleFonts.poppins(fontSize: 13, color: _grey), textAlign: TextAlign.center),
      ])),
      const SizedBox(height: 28),

      // Zona de carga
      GestureDetector(
        onTap: _cargando ? null : _elegirArchivo,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: MediaQuery.of(context).size.height * 0.28,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _amber.withOpacity(0.5), width: 2, style: BorderStyle.solid),
            boxShadow: [BoxShadow(color: _amber.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: _cargando
            ? const Center(child: CircularProgressIndicator(color: _amber))
            : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.cloud_upload_outlined, size: 52, color: _amber),
                const SizedBox(height: 12),
                Text('Tocá para elegir tu archivo', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: _dark)),
                const SizedBox(height: 4),
                Text('Formatos aceptados: .xlsx, .xls, .csv', style: GoogleFonts.poppins(fontSize: 12, color: _grey)),
              ]),
        ),
      ),

      if (_error != null) ...[
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10)),
          child: Text(_error!, style: GoogleFonts.poppins(fontSize: 12, color: Colors.red)),
        ),
      ],

      const SizedBox(height: 16),

      // Descargar plantilla
      Center(child: TextButton.icon(
        onPressed: _descargarPlantilla,
        icon: const Icon(Icons.download, size: 16, color: _blue),
        label: Text('Descargar plantilla de ejemplo', style: GoogleFonts.poppins(fontSize: 13, color: _blue, fontWeight: FontWeight.w600)),
      )),

      const SizedBox(height: 20),

      // Última carga
      if (_ultimaCarga != null) _buildUltimaCarga(),

      const SizedBox(height: 12),
      Center(child: TextButton.icon(
        onPressed: () async {
          setState(() => _pantalla = 5);
          _cargarHistorial();
        },
        icon: const Icon(Icons.history, size: 16, color: _grey),
        label: Text('Ver historial completo', style: GoogleFonts.poppins(fontSize: 12, color: _grey)),
      )),
      const SizedBox(height: 20),
    ]);
  }

  Widget _buildUltimaCarga() {
    final f = DateTime.tryParse(_ultimaCarga!['fecha_carga']?.toString() ?? '');
    final hace = f != null ? _tiempoRelativo(f) : '';
    final total = (_ultimaCarga!['actualizados_automatico'] ?? 0) + (_ultimaCarga!['actualizados_manual'] ?? 0);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(children: [
        const Icon(Icons.history, color: _grey, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Última actualización: $hace', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: _dark)),
          Text('$total productos actualizados · ${_ultimaCarga!['nombre_archivo'] ?? ''}',
            style: GoogleFonts.poppins(fontSize: 11, color: _grey)),
        ])),
      ]),
    );
  }

  String _tiempoRelativo(DateTime f) {
    final diff = DateTime.now().difference(f);
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
    if (diff.inHours < 24)   return 'hace ${diff.inHours} h';
    if (diff.inDays == 1)    return 'ayer';
    return 'hace ${diff.inDays} días';
  }

  // ─── SELECCIÓN DE ARCHIVO ─────────────────────────────────────────────────

  Future<void> _elegirArchivo() async {
    setState(() { _cargando = true; _error = null; });
    try {
      final r = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx', 'xls'],
        withData: true,
      );
      if (r == null || r.files.isEmpty) { setState(() => _cargando = false); return; }
      final archivo = r.files.first;
      if (archivo.bytes == null) {
        setState(() { _cargando = false; _error = 'No se pudo leer el archivo'; });
        return;
      }
      _nombreArchivo = archivo.name;
      setState(() { _cargando = false; _pantalla = 1; _pasoStatus.fillRange(0, 5, 0); });
      await _procesarArchivo(archivo.bytes!, archivo.name);
    } catch (e) {
      setState(() { _cargando = false; _error = 'Error: $e'; });
    }
  }

  Future<void> _descargarPlantilla() async {
    final r = await ApiService.get('/comercio/excel/plantilla');
    if (r['status'] == 200) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Plantilla descargada — revisá tu carpeta de descargas'),
        backgroundColor: _green,
      ));
    }
  }

  // ─── PANTALLA 1: PROCESANDO ───────────────────────────────────────────────

  Widget _buildProcesando() {
    final pasos = [
      'Archivo recibido',
      'Leyendo columnas...',
      'Identificando productos...',
      'Comparando con tu catálogo actual...',
      'Generando resumen de cambios...',
    ];
    return Center(child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 20),
        Text('Procesando con IA', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w800, color: _dark)),
        Text(_nombreArchivo ?? '', style: GoogleFonts.poppins(fontSize: 11, color: _grey)),
        const SizedBox(height: 32),
        ...pasos.asMap().entries.map((e) => _buildPasoItem(e.key, e.value)),
        const SizedBox(height: 24),
        Text('Esto tarda unos segundos...', style: GoogleFonts.poppins(fontSize: 12, color: _grey)),
      ]),
    ));
  }

  Widget _buildPasoItem(int i, String label) {
    final status = i < _pasoStatus.length ? _pasoStatus[i] : 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        SizedBox(width: 28, height: 28, child:
          status == 2 ? const Icon(Icons.check_circle, color: _green, size: 24)
          : status == 1 ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: _amber))
          : Icon(Icons.radio_button_unchecked, color: Colors.grey.shade300, size: 24)
        ),
        const SizedBox(width: 12),
        Text(label, style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: status == 1 ? FontWeight.w700 : FontWeight.normal,
          color: status == 2 ? _green : status == 1 ? _dark : _grey,
        )),
      ]),
    );
  }

  Future<void> _procesarArchivo(List<int> bytes, String nombre) async {
    final esCsv = nombre.toLowerCase().endsWith('.csv');
    List<List<dynamic>> filasBruto = [];
    Map<String, int?> columnas = {'codigo': null, 'nombre': 0, 'precio': 1, 'stock': null};

    // Paso 1: recibido
    setState(() => _pasoStatus[0] = 2);
    await Future.delayed(const Duration(milliseconds: 400));

    // Paso 2: leer columnas
    setState(() => _pasoStatus[1] = 1);
    try {
      if (esCsv) {
        final txt = String.fromCharCodes(bytes);
        filasBruto = txt.split(RegExp(r'\r?\n')).where((l) => l.trim().isNotEmpty)
          .map((l) { final sep = l.contains(';') ? ';' : l.contains('|') ? '|' : ','; return l.split(sep).map((v) => v.trim()).toList() as List<dynamic>; }).toList();
        columnas = _detectarColumnasCsv(filasBruto);
        if (filasBruto.isNotEmpty) filasBruto = filasBruto.sublist(1); // skip header
      } else {
        final b64 = base64Encode(bytes);
        final res = await ApiService.post('/comercio/excel/parsear-archivo', {'base64': b64, 'nombreArchivo': nombre});
        if (res['status'] != 200 || !mounted) {
          setState(() { _pantalla = 0; _error = res['data']?['error'] ?? 'Error al leer el archivo'; });
          return;
        }
        filasBruto = (res['data']['filas'] as List).map((f) => List<dynamic>.from(f as List)).toList();
        final cols = res['data']['columnasDetectadas'] as Map<String, dynamic>? ?? {};
        columnas = {
          'codigo': cols['codigo'] != null ? (cols['codigo'] as num).toInt() : null,
          'nombre': cols['nombre'] != null ? (cols['nombre'] as num).toInt() : null,
          'precio': cols['precio'] != null ? (cols['precio'] as num).toInt() : null,
          'stock':  cols['stock']  != null ? (cols['stock']  as num).toInt() : null,
        };
        // Saltar filas de título/encabezado (puede haber más de 1 antes de los datos)
        final filasHeader = (res['data']['filasHeader'] as num?)?.toInt() ?? 1;
        if (filasBruto.length > filasHeader) {
          filasBruto = filasBruto.sublist(filasHeader);
        }
      }
    } catch (e) {
      if (mounted) setState(() { _pantalla = 0; _error = 'Error al leer el archivo: $e'; });
      return;
    }
    setState(() => _pasoStatus[1] = 2);
    await Future.delayed(const Duration(milliseconds: 300));

    // Paso 3: identificar
    setState(() => _pasoStatus[2] = 1);
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => _pasoStatus[2] = 2);

    // Paso 4: matching backend
    setState(() => _pasoStatus[3] = 1);
    final res2 = await ApiService.post('/comercio/excel/procesar', {
      'nombreArchivo': nombre,
      'columnas': columnas,
      'filas': filasBruto,
    });
    if (!mounted) return;
    if (res2['status'] != 200) {
      final errMsg = res2['data']?['error'] ?? 'Error al procesar';
      final colsDet = res2['data']?['columnasDetectadas'];
      String detalle = errMsg;
      if (colsDet != null) {
        detalle += '\n\nColumnas detectadas: nombre=${colsDet['nombre']}, precio=${colsDet['precio']}, código=${colsDet['codigo']}';
      }
      setState(() { _pantalla = 0; _error = detalle; });
      return;
    }
    setState(() => _pasoStatus[3] = 2);
    await Future.delayed(const Duration(milliseconds: 300));

    // Paso 5: generar resumen
    setState(() => _pasoStatus[4] = 1);
    final data = res2['data'] as Map<String, dynamic>;
    _automaticos  = List<Map<String, dynamic>>.from(data['automaticos'] ?? []);
    _nuevos       = List<Map<String, dynamic>>.from(data['nuevos'] ?? []);
    _confirmar    = List<Map<String, dynamic>>.from(data['confirmar'] ?? []);
    _faltantes    = List<Map<String, dynamic>>.from(data['faltantes'] ?? []);
    _totalFilas   = (data['totalFilas'] as num?)?.toInt() ?? filasBruto.length;

    // Inicializar decisiones
    _selAuto.clear(); _selNuevo.clear(); _decConfirmar.clear(); _decFaltante.clear(); _precioManualCtrl.clear(); _linkNuevo.clear(); _linkNombreNuevo.clear();
    for (int i = 0; i < _automaticos.length; i++) _selAuto[i] = true;
    for (int i = 0; i < _nuevos.length; i++) { _selNuevo[i] = false; _linkNuevo[i] = null; }
    for (int i = 0; i < _confirmar.length; i++) _decConfirmar[i] = 'pendiente';
    for (int i = 0; i < _faltantes.length; i++) {
      _decFaltante[i] = 'mantener';
      _precioManualCtrl[i] = TextEditingController();
    }
    await Future.delayed(const Duration(milliseconds: 300));
    setState(() { _pasoStatus[4] = 2; });
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) setState(() => _pantalla = 2);
  }

  Map<String, int?> _detectarColumnasCsv(List<List<dynamic>> filas) {
    if (filas.isEmpty) return {'codigo': null, 'nombre': 0, 'precio': 1, 'stock': null};
    final h = filas[0].map((v) => v.toString().toLowerCase()).toList();
    int? cod, nom, pre, sto;
    for (int i = 0; i < h.length; i++) {
      if (pre == null && (h[i].contains('venta') || h[i].contains('precio'))) pre = i;
      if (sto == null && (h[i].contains('stock') || h[i].contains('cantidad') || h[i].contains('disponible'))) sto = i;
      if (cod == null && (h[i].contains('cod') || h[i].contains('sku') || h[i].contains('ref'))) cod = i;
      if (nom == null && (h[i].contains('nombre') || h[i].contains('producto') || h[i].contains('descripcion'))) nom = i;
    }
    return {'codigo': cod, 'nombre': nom ?? 0, 'precio': pre ?? 1, 'stock': sto};
  }

  // ─── PANTALLA 2: RESULTADOS ───────────────────────────────────────────────

  Widget _buildResultados() {
    final cntAuto    = _automaticos.length;
    final cntNuevos  = _nuevos.length;
    final cntConf    = _confirmar.length;
    final cntFalt    = _faltantes.length;

    final pendientes = _confirmar.asMap().entries.where((e) => _decConfirmar[e.key] == 'pendiente').length;

    return Column(children: [
      // Pills resumen
      Container(
        color: _navy,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(children: [
          _pill('$cntAuto auto', _green),
          const SizedBox(width: 6),
          _pill('$cntNuevos nuevos', _blue),
          const SizedBox(width: 6),
          _pill('$cntConf verificar', _yellow),
          const SizedBox(width: 6),
          _pill('$cntFalt faltantes', _red),
        ]),
      ),
      Expanded(child: ListView(padding: const EdgeInsets.all(12), children: [
        if (_automaticos.isNotEmpty) ...[
          _seccionHeader('✅ Actualizados automáticamente', _green, cntAuto,
            trailing: TextButton(
              onPressed: () => setState(() { for (int i=0; i<_automaticos.length; i++) _selAuto[i] = true; }),
              child: Text('Sel. todos', style: GoogleFonts.poppins(fontSize: 11, color: _green)),
            )),
          ..._automaticos.asMap().entries.map((e) => _cardAuto(e.key, e.value)),
          const SizedBox(height: 16),
        ],
        if (_nuevos.isNotEmpty) ...[
          _seccionHeader('🔵 Productos nuevos detectados', _blue, cntNuevos),
          Text('Están en tu Excel pero no en tu catálogo actual. Vinculalos si los reconocés.',
            style: GoogleFonts.poppins(fontSize: 11, color: _grey), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          ..._nuevos.asMap().entries.map((e) => _cardNuevo(e.key, e.value)),
          const SizedBox(height: 16),
        ],
        if (_confirmar.isNotEmpty) ...[
          _seccionHeader('🟡 Revisar manualmente', _yellow, cntConf,
            trailing: pendientes > 0
              ? Text('$pendientes pendientes', style: GoogleFonts.poppins(fontSize: 11, color: _yellow, fontWeight: FontWeight.w700))
              : null),
          Text('Los encontramos pero no estamos 100% seguros. Confirmá cada uno.',
            style: GoogleFonts.poppins(fontSize: 11, color: _grey), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          ..._confirmar.asMap().entries.map((e) => _cardConfirmar(e.key, e.value)),
          const SizedBox(height: 16),
        ],
        if (_faltantes.isNotEmpty) ...[
          _seccionHeader('🔴 No están en tu Excel', _red, cntFalt,
            trailing: TextButton(
              onPressed: () => setState(() { for (int i=0; i<_faltantes.length; i++) _decFaltante[i] = 'mantener'; }),
              child: Text('Mantener todos', style: GoogleFonts.poppins(fontSize: 11, color: _red)),
            )),
          Text('Estos productos los tenés en el catálogo pero no aparecen en el Excel.',
            style: GoogleFonts.poppins(fontSize: 11, color: _grey), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          ..._faltantes.asMap().entries.map((e) => _cardFaltante(e.key, e.value)),
          const SizedBox(height: 80),
        ],
        if (_automaticos.isEmpty && _nuevos.isEmpty && _confirmar.isEmpty)
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orange.shade200)),
            child: Column(children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 36),
              const SizedBox(height: 8),
              Text('No se encontraron coincidencias con tu catálogo', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: _dark), textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text('El Excel se procesó pero ningún producto coincidió con los que tenés cargados. Revisá que los nombres sean similares o que las columnas estén bien detectadas.', style: GoogleFonts.poppins(fontSize: 11, color: _grey), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: _volverAtras, child: Text('Volver e intentar de nuevo', style: GoogleFonts.poppins(fontSize: 12))),
            ]),
          ),
      ])),
      // Botón sticky
      Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        child: Column(children: [
          if (pendientes > 0)
            Padding(padding: const EdgeInsets.only(bottom: 6),
              child: Text('Resolvé los $pendientes ítems amarillos antes de continuar',
                style: GoogleFonts.poppins(fontSize: 11, color: _yellow, fontWeight: FontWeight.w600), textAlign: TextAlign.center)),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: pendientes == 0 ? () => setState(() => _pantalla = 3) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _amber, foregroundColor: Colors.white, disabledBackgroundColor: Colors.grey.shade300,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Confirmar cambios seleccionados', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15)),
          )),
        ]),
      ),
    ]);
  }

  Widget _pill(String txt, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
    child: Text(txt, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
  );

  Widget _seccionHeader(String titulo, Color color, int count, {Widget? trailing}) => Padding(
    padding: const EdgeInsets.only(bottom: 6, top: 4),
    child: Row(children: [
      Expanded(child: Text(titulo, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w800, color: color))),
      if (trailing != null) trailing
      else Text('$count', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
    ]),
  );

  // ─── Card VERDE ───────────────────────────────────────────────────────────

  Widget _cardAuto(int i, Map e) {
    final seleccionado = _selAuto[i] ?? true;
    final precioAnt = (e['precioActual'] as num?)?.toDouble() ?? 0;
    final precioNuevo = (e['precioNuevo'] as num?)?.toDouble() ?? 0;
    final diff = precioNuevo - precioAnt;
    final pct  = precioAnt > 0 ? (diff / precioAnt * 100) : 0.0;
    final subio = diff > 0.01;
    final bajo  = diff < -0.01;
    final colorDiff = subio ? _green : bajo ? _red : _grey;
    final iconDiff  = subio ? '↑' : bajo ? '↓' : '=';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: seleccionado ? Colors.green.shade200 : Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(e['productoNombre'] ?? '', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: _dark)),
            if (e['productomarca'] != null && e['productomarca'].toString().isNotEmpty)
              Text(e['productomarca'].toString(), style: GoogleFonts.poppins(fontSize: 10, color: _grey)),
            const SizedBox(height: 4),
            Row(children: [
              if (precioAnt > 0 && diff.abs() > 0.01) ...[
                Text('\$${_fmt(precioAnt)}', style: GoogleFonts.poppins(fontSize: 11, color: _grey, decoration: TextDecoration.lineThrough)),
                const SizedBox(width: 6),
              ],
              Text('\$${_fmt(precioNuevo)}', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w800, color: colorDiff)),
              const SizedBox(width: 6),
              if (diff.abs() > 0.01)
                Text('$iconDiff ${pct.abs().toStringAsFixed(1)}%', style: GoogleFonts.poppins(fontSize: 10, color: colorDiff, fontWeight: FontWeight.w700)),
            ]),
            if (e['stockNuevo'] != null)
              Text('Stock: ${e['stockNuevo']}', style: GoogleFonts.poppins(fontSize: 10, color: _grey)),
          ])),
          Switch(
            value: seleccionado,
            onChanged: (v) => setState(() => _selAuto[i] = v),
            activeColor: _green,
          ),
        ]),
      ),
    );
  }

  // ─── Card AZUL ────────────────────────────────────────────────────────────

  Widget _cardNuevo(int i, Map e) {
    final seleccionado = _selNuevo[i] ?? false;
    final linkId = _linkNuevo[i];
    final linkNombre = _linkNombreNuevo[i];
    final fila = e['fila'] as Map? ?? {};
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.blue.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(fila['nombre'] ?? fila['codigo'] ?? 'Sin nombre',
                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: _dark)),
              if (fila['codigo'] != null && fila['codigo'].toString().isNotEmpty)
                Text('Código: ${fila['codigo']}', style: GoogleFonts.poppins(fontSize: 10, color: _grey)),
              Text('Precio: \$${_fmt((fila['precio'] as num?)?.toDouble() ?? 0)}',
                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: _blue)),
            ])),
            Switch(value: seleccionado && linkId != null, onChanged: linkId != null ? (v) => setState(() => _selNuevo[i] = v) : null, activeColor: _blue),
          ]),
          const SizedBox(height: 8),
          if (linkId != null)
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
              child: Row(children: [
                const Icon(Icons.link, size: 14, color: _blue),
                const SizedBox(width: 6),
                Expanded(child: Text('Vinculado a: $linkNombre', style: GoogleFonts.poppins(fontSize: 11, color: _blue, fontWeight: FontWeight.w600))),
                GestureDetector(onTap: () => setState(() { _linkNuevo[i] = null; _linkNombreNuevo[i] = null; _selNuevo[i] = false; }),
                  child: const Icon(Icons.close, size: 14, color: _grey)),
              ]))
          else
            OutlinedButton.icon(
              onPressed: () => _abrirBuscadorCatalogo(i, esSector: 'nuevo'),
              icon: const Icon(Icons.search, size: 14),
              label: Text('¿Cuál es este producto?', style: GoogleFonts.poppins(fontSize: 12)),
              style: OutlinedButton.styleFrom(foregroundColor: _blue, side: const BorderSide(color: _blue),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
            ),
        ]),
      ),
    );
  }

  // ─── Card AMARILLO ────────────────────────────────────────────────────────

  Widget _cardConfirmar(int i, Map e) {
    final dec = _decConfirmar[i] ?? 'pendiente';
    final fila = e['fila'] as Map? ?? {};
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: dec == 'si' ? Colors.green.shade300 : dec == 'no' ? Colors.red.shade300 : dec == 'saltear' ? Colors.grey.shade300 : Colors.orange.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('En tu Excel: "${fila['nombre'] ?? fila['codigo'] ?? ''}"',
                style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: _dark)),
              const SizedBox(height: 2),
              Text('Creemos que es: ${e['productoNombre'] ?? ''}${e['productomarca'] != null && e['productomarca'].toString().isNotEmpty ? ' · ${e['productomarca']}' : ''}',
                style: GoogleFonts.poppins(fontSize: 11, color: _grey)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: _yellow.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                child: Text('${e['score']}% similar', style: GoogleFonts.poppins(fontSize: 10, color: _yellow, fontWeight: FontWeight.w700))),
              const SizedBox(height: 4),
              Text('\$${_fmt((e['precioNuevo'] as num?)?.toDouble() ?? 0)}',
                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w800, color: _amber)),
            ]),
          ]),
          if (dec == 'pendiente') ...[
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _btnDecision('❌ No es este', Colors.red, () {
                setState(() => _decConfirmar[i] = 'no');
                _abrirBuscadorCatalogo(i, esSector: 'confirmar');
              })),
              const SizedBox(width: 6),
              Expanded(child: _btnDecision('⏭️ Saltear', Colors.grey, () => setState(() => _decConfirmar[i] = 'saltear'))),
              const SizedBox(width: 6),
              Expanded(child: _btnDecision('✅ Sí, es este', Colors.green, () => setState(() => _decConfirmar[i] = 'si'))),
            ]),
          ] else ...[
            const SizedBox(height: 8),
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(
              color: dec == 'si' ? Colors.green.shade50 : dec == 'no' ? Colors.red.shade50 : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8)),
              child: Row(children: [
                Text(dec == 'si' ? '✅ Confirmado — se actualizará el precio'
                  : dec == 'no' ? '❌ Rechazado — no se tocará'
                  : '⏭️ Salteado — sin cambios',
                  style: GoogleFonts.poppins(fontSize: 11, color: dec == 'si' ? _green : dec == 'no' ? _red : _grey)),
                const Spacer(),
                GestureDetector(onTap: () => setState(() => _decConfirmar[i] = 'pendiente'),
                  child: const Icon(Icons.undo, size: 14, color: _grey)),
              ]),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _btnDecision(String label, Color color, VoidCallback onTap) => OutlinedButton(
    onPressed: onTap,
    style: OutlinedButton.styleFrom(foregroundColor: color, side: BorderSide(color: color), padding: const EdgeInsets.symmetric(vertical: 8)),
    child: Text(label, style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600)),
  );

  // ─── Card ROJO ────────────────────────────────────────────────────────────

  Widget _cardFaltante(int i, Map e) {
    final dec = _decFaltante[i] ?? 'mantener';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.red.shade100)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(e['productoNombre'] ?? '', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: _dark)),
              if (e['productomarca'] != null && e['productomarca'].toString().isNotEmpty)
                Text(e['productomarca'].toString(), style: GoogleFonts.poppins(fontSize: 10, color: _grey)),
              Text('Precio actual: \$${_fmt((e['precioActual'] as num?)?.toDouble() ?? 0)}',
                style: GoogleFonts.poppins(fontSize: 11, color: _grey)),
            ])),
            Text('No está en tu Excel', style: GoogleFonts.poppins(fontSize: 10, color: Colors.red.shade400)),
          ]),
          const SizedBox(height: 8),
          // Selector de acción
          Row(children: [
            _chipAccion('📌 Mantener', 'mantener', dec, i),
            const SizedBox(width: 6),
            _chipAccion('✏️ Editar precio', 'precio_manual', dec, i),
            const SizedBox(width: 6),
            _chipAccion('🔕 Desactivar', 'desactivar', dec, i),
          ]),
          if (dec == 'precio_manual') ...[
            const SizedBox(height: 8),
            TextField(
              controller: _precioManualCtrl[i],
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: 'Nuevo precio',
                prefixText: '\$',
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _amber)),
              ),
              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ],
          if (dec == 'desactivar')
            Padding(padding: const EdgeInsets.only(top: 6),
              child: Text('Se ocultará para los clientes pero podrás reactivarlo cuando quieras.',
                style: GoogleFonts.poppins(fontSize: 10, color: Colors.red.shade400))),
        ]),
      ),
    );
  }

  Widget _chipAccion(String label, String valor, String actual, int i) => GestureDetector(
    onTap: () => setState(() => _decFaltante[i] = valor),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: actual == valor ? _dark.withOpacity(0.08) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: actual == valor ? _dark : Colors.grey.shade200, width: actual == valor ? 1.5 : 1),
      ),
      child: Text(label, style: GoogleFonts.poppins(fontSize: 10, fontWeight: actual == valor ? FontWeight.w700 : FontWeight.normal, color: actual == valor ? _dark : _grey)),
    ),
  );

  // ─── Buscador inline de catálogo ──────────────────────────────────────────

  Future<void> _abrirBuscadorCatalogo(int idx, {required String esSector}) async {
    final ctrl = TextEditingController();
    List<Map<String, dynamic>> resultados = [];
    bool buscando = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(builder: (ctx2, setS) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, sc) => Column(children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 12),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child:
              Text('Buscá el producto correcto', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w800, color: _dark))),
            const SizedBox(height: 12),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: TextField(
              controller: ctrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Ej: Cemento Portland 50kg',
                prefixIcon: const Icon(Icons.search, color: _amber),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _amber, width: 2)),
              ),
              onChanged: (q) async {
                if (q.length < 2) return;
                setS(() => buscando = true);
                final r = await ApiService.get('/catalogo-maestro?busqueda=${Uri.encodeComponent(q)}&limit=10');
                setS(() {
                  buscando = false;
                  resultados = List<Map<String, dynamic>>.from(r['data']?['productos'] ?? r['data']?['data'] ?? []);
                });
              },
            )),
            const SizedBox(height: 8),
            Expanded(child: buscando
              ? const Center(child: CircularProgressIndicator(color: _amber))
              : ListView.separated(
                  controller: sc,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: resultados.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, j) {
                    final p = resultados[j];
                    return ListTile(
                      title: Text(p['nombre'] ?? '', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700)),
                      subtitle: Text(p['marca'] ?? '', style: GoogleFonts.poppins(fontSize: 11, color: _grey)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: _amber),
                      onTap: () {
                        Navigator.pop(ctx);
                        setState(() {
                          if (esSector == 'nuevo') {
                            _linkNuevo[idx] = p['id'] as int?;
                            _linkNombreNuevo[idx] = p['nombre'] as String?;
                            _selNuevo[idx] = true;
                          } else if (esSector == 'confirmar') {
                            _decConfirmar[idx] = 'si';
                          }
                        });
                      },
                    );
                  },
                )),
          ]),
        );
      }),
    );
  }

  // ─── PANTALLA 3: CONFIRMACIÓN FINAL ──────────────────────────────────────

  Widget _buildConfirmacion() {
    final autoSeleccionados = _automaticos.asMap().entries.where((e) => _selAuto[e.key] == true).length;
    final nuevosAgregar = _nuevos.asMap().entries.where((e) => _selNuevo[e.key] == true && _linkNuevo[e.key] != null).length;
    final confirmadosSi = _confirmar.asMap().entries.where((e) => _decConfirmar[e.key] == 'si').length;
    final desactivados = _faltantes.asMap().entries.where((e) => _decFaltante[e.key] == 'desactivar').length;
    final precioManual = _faltantes.asMap().entries.where((e) => _decFaltante[e.key] == 'precio_manual').length;
    final mantener = _faltantes.asMap().entries.where((e) => _decFaltante[e.key] == 'mantener').length;

    return ListView(padding: const EdgeInsets.all(20), children: [
      const SizedBox(height: 16),
      Center(child: Column(children: [
        const Icon(Icons.fact_check_outlined, size: 52, color: _amber),
        const SizedBox(height: 12),
        Text('¿Confirmás estos cambios?', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w800, color: _dark), textAlign: TextAlign.center),
        const SizedBox(height: 4),
        Text('Revisá el resumen antes de aplicar', style: GoogleFonts.poppins(fontSize: 13, color: _grey)),
      ])),
      const SizedBox(height: 28),
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
        child: Column(children: [
          _filResumen('✅ Actualizar precio de $autoSeleccionados productos', _green, autoSeleccionados > 0),
          if (nuevosAgregar > 0) _filResumen('🔵 Agregar $nuevosAgregar productos nuevos', _blue, true),
          if (confirmadosSi > 0) _filResumen('🟡 Actualizar $confirmadosSi productos confirmados', _yellow, true),
          if (desactivados > 0) _filResumen('🔴 Desactivar $desactivados productos', _red, true),
          if (precioManual > 0) _filResumen('✏️ Actualizar precio manual de $precioManual productos', _amber, true),
          _filResumen('📌 Mantener $mantener productos sin cambios', _grey, false),
        ]),
      ),
      const SizedBox(height: 28),
      SizedBox(width: double.infinity, child: ElevatedButton(
        onPressed: _cargando ? null : _aplicarCambios,
        style: ElevatedButton.styleFrom(
          backgroundColor: _amber, foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: _cargando
          ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
          : Text('Aplicar todos los cambios', style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 16)),
      )),
      const SizedBox(height: 12),
      Center(child: TextButton(
        onPressed: () => setState(() => _pantalla = 2),
        child: Text('Revisar de nuevo', style: GoogleFonts.poppins(fontSize: 13, color: _grey)),
      )),
    ]);
  }

  Widget _filResumen(String txt, Color color, bool destacado) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(children: [
      Expanded(child: Text(txt, style: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: destacado ? FontWeight.w700 : FontWeight.normal,
        color: destacado ? color : _grey,
      ))),
    ]),
  );

  Future<void> _aplicarCambios() async {
    setState(() => _cargando = true);
    try {
      final actualizados = _automaticos.asMap().entries.map((e) => {
        'productoId': e.value['productoId'],
        'catalogoProductoId': e.value['catalogoProductoId'],
        'precioNuevo': e.value['precioNuevo'],
        'stockNuevo': e.value['stockNuevo'],
        'fila': e.value['fila'],
        'aprendidoId': e.value['aprendidoId'],
        'aplicar': _selAuto[e.key] ?? true,
      }).toList();

      final confirmados = _confirmar.asMap().entries
        .where((e) => _decConfirmar[e.key] == 'si')
        .map((e) => {
          'productoId': e.value['productoId'],
          'catalogoProductoId': e.value['catalogoProductoId'],
          'precioNuevo': e.value['precioNuevo'],
          'stockNuevo': e.value['stockNuevo'],
          'fila': e.value['fila'],
        }).toList();

      final faltantesBody = _faltantes.asMap().entries
        .where((e) => _decFaltante[e.key] != 'mantener')
        .map((e) => {
          'productoId': e.value['productoId'],
          'accion': _decFaltante[e.key],
          'precioNuevo': _decFaltante[e.key] == 'precio_manual' ? _precioManualCtrl[e.key]?.text : null,
        }).toList();

      final nuevosBody = _nuevos.asMap().entries
        .where((e) => _selNuevo[e.key] == true && _linkNuevo[e.key] != null)
        .map((e) => {
          'catalogoProductoId': _linkNuevo[e.key],
          'precio': e.value['fila']['precio'],
          'stock': e.value['fila']['stock'],
          'fila': e.value['fila'],
          'agregar': true,
        }).toList();

      final res = await ApiService.post('/comercio/excel/aplicar', {
        'nombreArchivo': _nombreArchivo ?? 'planilla',
        'totalFilas': _totalFilas,
        'actualizados': actualizados,
        'confirmados': confirmados,
        'faltantes': faltantesBody,
        'nuevos': nuevosBody,
      });

      if (!mounted) return;
      setState(() => _cargando = false);
      if (res['status'] == 200) {
        _cargaIdExito = res['data']['cargaId'] as int?;
        setState(() => _pantalla = 4);
        _cargarUltimaCarga();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: ${res['data']?['error'] ?? 'No se pudo aplicar'}'),
          backgroundColor: Colors.red,
        ));
      }
    } catch (e) {
      setState(() => _cargando = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  // ─── PANTALLA 4: ÉXITO ────────────────────────────────────────────────────

  Widget _buildExito() {
    return SafeArea(child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(children: [
        const Spacer(),
        // Check animado
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 600),
          builder: (_, v, __) => Transform.scale(scale: v, child: Container(
            width: 96, height: 96,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: _green),
            child: const Icon(Icons.check, color: Colors.white, size: 56),
          )),
        ),
        const SizedBox(height: 24),
        Text('¡Catálogo actualizado!', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w900, color: _dark), textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text('Tus clientes ya ven los nuevos precios', style: GoogleFonts.poppins(fontSize: 14, color: _grey), textAlign: TextAlign.center),
        const SizedBox(height: 32),
        // Resumen compacto
        if (_ultimaCarga != null) _buildResumenExito(),
        const Spacer(),
        SizedBox(width: double.infinity, child: ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(backgroundColor: _amber, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          child: Text('Ver mi catálogo actualizado', style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 15)),
        )),
        const SizedBox(height: 12),
        if (_cargaIdExito != null)
          TextButton.icon(
            onPressed: () => _deshacerCarga(_cargaIdExito!),
            icon: const Icon(Icons.undo, size: 16, color: _grey),
            label: Text('Deshacer cambios (disponible 30 min)', style: GoogleFonts.poppins(fontSize: 12, color: _grey)),
          ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () { setState(() { _pantalla = 5; }); _cargarHistorial(); },
          child: Text('Ver historial de actualizaciones', style: GoogleFonts.poppins(fontSize: 12, color: _blue)),
        ),
      ]),
    ));
  }

  Widget _buildResumenExito() {
    final total = (_ultimaCarga!['actualizados_automatico'] ?? 0) + (_ultimaCarga!['actualizados_manual'] ?? 0);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _green.withOpacity(0.06), borderRadius: BorderRadius.circular(14), border: Border.all(color: _green.withOpacity(0.2))),
      child: Column(children: [
        _rowResumenExito('Precios actualizados', '$total'),
        _rowResumenExito('Productos desactivados', '${_faltantes.where((f) => _decFaltante[_faltantes.indexOf(f)] == 'desactivar').length}'),
      ]),
    );
  }

  Widget _rowResumenExito(String label, String val) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: GoogleFonts.poppins(fontSize: 13, color: _grey)),
      Text(val, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w800, color: _dark)),
    ]),
  );

  // ─── PANTALLA 5: HISTORIAL ────────────────────────────────────────────────

  bool _cargandoHistorial = false;

  Widget _buildHistorial() {
    if (_historial.isEmpty && !_cargandoHistorial) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _cargarHistorial());
    }
    if (_cargandoHistorial) return const Center(child: CircularProgressIndicator(color: _amber));
    if (_historial.isEmpty) return Center(child: Text('Aún no hay cargas registradas', style: GoogleFonts.poppins(color: _grey)));
    return ListView.separated(
      padding: const EdgeInsets.all(14),
      itemCount: _historial.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _cardHistorial(_historial[i] as Map<String, dynamic>),
    );
  }

  Widget _cardHistorial(Map<String, dynamic> h) {
    final fecha = DateTime.tryParse(h['fecha_carga']?.toString() ?? '');
    final revertido = h['revertido'] == true;
    final auto = h['actualizados_automatico'] ?? 0;
    final manual = h['actualizados_manual'] ?? 0;
    final noEnc = h['no_encontrados'] ?? 0;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(h['nombre_archivo'] ?? '', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: _dark))),
          if (revertido) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
            child: Text('↩️ Revertido', style: GoogleFonts.poppins(fontSize: 10, color: _grey))),
        ]),
        if (fecha != null) Padding(padding: const EdgeInsets.only(top: 2),
          child: Text('${fecha.day}/${fecha.month}/${fecha.year} ${fecha.hour}:${fecha.minute.toString().padLeft(2,'0')}',
            style: GoogleFonts.poppins(fontSize: 11, color: _grey))),
        const SizedBox(height: 8),
        Row(children: [
          _statChip('$auto auto', Colors.green),
          const SizedBox(width: 6),
          _statChip('$manual manual', Colors.orange),
          const SizedBox(width: 6),
          _statChip('$noEnc no enc.', Colors.red),
        ]),
        if (!revertido) ...[
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            TextButton.icon(
              onPressed: () => _deshacerCarga(int.tryParse(h['id'].toString()) ?? 0),
              icon: const Icon(Icons.undo, size: 14, color: Colors.red),
              label: Text('Deshacer', style: GoogleFonts.poppins(fontSize: 12, color: Colors.red)),
              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
            ),
          ]),
        ],
      ])),
    );
  }

  Widget _statChip(String txt, MaterialColor color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: color.shade50, borderRadius: BorderRadius.circular(10)),
    child: Text(txt, style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: color.shade700)),
  );

  Future<void> _cargarHistorial() async {
    setState(() => _cargandoHistorial = true);
    final r = await ApiService.get('/comercio/excel/historial');
    if (mounted) setState(() { _cargandoHistorial = false; _historial = (r['data']?['historial'] as List?) ?? []; });
  }

  Future<void> _deshacerCarga(int id) async {
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text('¿Deshacer esta carga?', style: GoogleFonts.poppins(fontWeight: FontWeight.w800)),
      content: Text('Se van a revertir todos los precios de esta carga.', style: GoogleFonts.poppins(fontSize: 13)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
        ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Deshacer')),
      ],
    ));
    if (ok != true || !mounted) return;
    final r = await ApiService.post('/comercio/excel/deshacer/$id', {});
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(r['status'] == 200 ? '✓ Carga revertida correctamente' : 'Error: ${r['data']?['error'] ?? 'no se pudo'}'),
      backgroundColor: r['status'] == 200 ? _green : Colors.red,
    ));
    if (r['status'] == 200) {
      if (_pantalla == 4) setState(() { _pantalla = 0; _cargaIdExito = null; });
      else _cargarHistorial();
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  String _fmt(double v) {
    if (v == v.truncate()) return v.toInt().toString();
    return v.toStringAsFixed(2);
  }
}
