import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' as xls;
import '../services/api_service.dart';

const _amber = Color(0xFFE07B00);
const _navy = Color(0xFF1E3A5F);
const _dark = Color(0xFF1A1A1A);
const _grey = Color(0xFF888888);
const _success = Color(0xFF2E7D32);

class ExcelPreciosScreen extends StatefulWidget {
  const ExcelPreciosScreen({super.key});
  @override
  State<ExcelPreciosScreen> createState() => _ExcelPreciosScreenState();
}

class _ExcelPreciosScreenState extends State<ExcelPreciosScreen> {
  int _paso = 0; // 0=inicio, 1=preview, 2=procesando, 3=resultados, 4=historial
  bool _cargando = false;
  String? _nombreArchivo;
  List<List<dynamic>> _filasBruto = [];
  Map<String, int?> _columnas = {'codigo': null, 'nombre': 0, 'precio': 1};
  Map<String, dynamic>? _resultado;
  String? _error;

  // Resultados separados con estado de confirmación
  List<Map<String, dynamic>> _automaticos = [];
  List<Map<String, dynamic>> _confirmar = [];
  List<Map<String, dynamic>> _noEncontrados = [];

  // Tracking de confirmaciones manuales
  final Map<int, bool> _confirmados = {}; // idx -> aceptado/rechazado
  final Map<int, int?> _vinculadoA = {}; // idx -> productoId seleccionado manualmente

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F8),
      appBar: AppBar(
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        title: Text('Actualizar precios por planilla',
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700)),
      ),
      body: _buildCuerpo(),
    );
  }

  Widget _buildCuerpo() {
    if (_paso == 0) return _buildPaso0Inicio();
    if (_paso == 1) return _buildPaso1Preview();
    if (_paso == 2) return _buildPaso2Procesando();
    if (_paso == 3) return _buildPaso3Resultados();
    if (_paso == 4) return _buildPaso4Historial();
    return const SizedBox.shrink();
  }

  // ─── PASO 0: SELECCIÓN DE ARCHIVO ────────────────────────────────────────

  Widget _buildPaso0Inicio() {
    return ListView(padding: const EdgeInsets.all(20), children: [
      const SizedBox(height: 20),
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(children: [
          const Text('📊', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text('Actualización inteligente de precios',
            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w800, color: _dark),
            textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
            'Subí tu planilla con precios y el sistema reconoce tus productos automáticamente, '
            'incluso si usás nombres o códigos propios.',
            style: GoogleFonts.poppins(fontSize: 12, color: _grey, height: 1.5),
            textAlign: TextAlign.center),
          const SizedBox(height: 24),
          _buildFormatoAceptado(),
          const SizedBox(height: 24),
          if (_cargando)
            const CircularProgressIndicator(color: _amber)
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _elegirArchivo,
                icon: const Icon(Icons.upload_file),
                label: Text('Elegir archivo (Excel o CSV)',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _amber, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => setState(() => _paso = 4),
            icon: const Icon(Icons.history, size: 16, color: _grey),
            label: Text('Ver historial de cargas',
              style: GoogleFonts.poppins(fontSize: 12, color: _grey)),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
              child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
            ),
          ],
        ]),
      ),
    ]);
  }

  Widget _buildFormatoAceptado() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Formatos aceptados:', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: _dark)),
        const SizedBox(height: 6),
        _fmtRow('Solo nombre', '"Cemento loma negra"'),
        _fmtRow('Nombre + precio', '"Cemento loma negra | 8500"'),
        _fmtRow('Código + nombre + precio', '"LN50 | Cemento | 8500"'),
        _fmtRow('Código + precio', '"LN50 | 8500"'),
      ]),
    );
  }

  Widget _fmtRow(String label, String ejemplo) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('• ', style: GoogleFonts.poppins(fontSize: 10, color: _amber, fontWeight: FontWeight.w700)),
      Expanded(child: RichText(text: TextSpan(
        style: GoogleFonts.poppins(fontSize: 10, color: _grey),
        children: [
          TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
          TextSpan(text: ejemplo, style: const TextStyle(fontStyle: FontStyle.italic)),
        ],
      ))),
    ]),
  );

  // ─── SELECCIÓN Y PARSEO DE ARCHIVO ────────────────────────────────────────

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
      if (archivo.bytes == null) { setState(() { _cargando = false; _error = 'No se pudo leer el archivo'; }); return; }

      _nombreArchivo = archivo.name;
      final esExcel = archivo.name.toLowerCase().endsWith('.xlsx') || archivo.name.toLowerCase().endsWith('.xls');
      _filasBruto = esExcel ? _parsearExcel(archivo.bytes!) : _parsearCsv(String.fromCharCodes(archivo.bytes!));

      if (_filasBruto.isEmpty) {
        setState(() { _cargando = false; _error = 'El archivo no tiene filas válidas'; }); return;
      }

      // Auto-detectar columnas
      _columnas = _detectarColumnas();
      setState(() { _cargando = false; _paso = 1; });
    } catch (e) {
      setState(() { _cargando = false; _error = 'Error al leer el archivo: $e'; });
    }
  }

  List<List<dynamic>> _parsearCsv(String contenido) {
    final filas = <List<dynamic>>[];
    final lineas = contenido.split(RegExp(r'\r?\n')).where((l) => l.trim().isNotEmpty);
    for (final l in lineas) {
      final sep = l.contains(';') ? ';' : l.contains('|') ? '|' : ',';
      filas.add(l.split(sep).map((v) => v.trim()).toList());
    }
    return filas;
  }

  List<List<dynamic>> _parsearExcel(List<int> bytes) {
    final filas = <List<dynamic>>[];
    final libro = xls.Excel.decodeBytes(bytes);
    if (libro.tables.isEmpty) return filas;
    final hoja = libro.tables.values.first;
    for (final f in hoja.rows) {
      if (f.isEmpty) continue;
      filas.add(f.map((c) => c?.value?.toString() ?? '').toList());
    }
    return filas;
  }

  Map<String, int?> _detectarColumnas() {
    if (_filasBruto.isEmpty) return {'codigo': null, 'nombre': 0, 'precio': 1};
    final primera = _filasBruto[0];
    final segunda = _filasBruto.length > 1 ? _filasBruto[1] : primera;
    final cols = primera.length;
    if (cols == 1) return {'codigo': null, 'nombre': 0, 'precio': null};
    if (cols == 2) return {'codigo': null, 'nombre': 0, 'precio': 1};
    // 3+ columnas: detectar por contenido
    int? precioCol, nombreCol, codigoCol;
    for (int i = 0; i < cols; i++) {
      final v = segunda[i]?.toString() ?? '';
      final n = double.tryParse(v.replaceAll(RegExp(r'[\$\s.]'), '').replaceAll(',', '.'));
      if (n != null && n > 0 && precioCol == null) { precioCol = i; continue; }
      if (RegExp(r'^[A-Z0-9\-_]{2,15}$').hasMatch(v) && codigoCol == null) { codigoCol = i; continue; }
      if (v.length > 4 && nombreCol == null) nombreCol = i;
    }
    return {'codigo': codigoCol, 'nombre': nombreCol ?? 0, 'precio': precioCol ?? (cols > 1 ? cols - 1 : null)};
  }

  // ─── PASO 1: PREVIEW ─────────────────────────────────────────────────────

  Widget _buildPaso1Preview() {
    final preview = _filasBruto.take(5).toList();
    return ListView(padding: const EdgeInsets.all(16), children: [
      Text('Vista previa del archivo', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w800, color: _dark)),
      Text(_nombreArchivo ?? '', style: GoogleFonts.poppins(fontSize: 11, color: _grey)),
      const SizedBox(height: 16),

      // Preview tabla
      Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
        child: Column(children: [
          ...preview.asMap().entries.map((e) => _filaPreview(e.key, e.value)),
          if (_filasBruto.length > 5)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text('... y ${_filasBruto.length - 5} filas más',
                style: GoogleFonts.poppins(fontSize: 11, color: _grey)),
            ),
        ]),
      ),

      const SizedBox(height: 20),
      Text('Columnas detectadas:', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: _dark)),
      const SizedBox(height: 8),
      _buildSelectorColumnas(),

      const SizedBox(height: 24),
      Row(children: [
        Expanded(child: OutlinedButton(
          onPressed: () => setState(() => _paso = 0),
          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: Text('Volver', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        )),
        const SizedBox(width: 12),
        Expanded(flex: 2, child: ElevatedButton(
          onPressed: _procesarConIA,
          style: ElevatedButton.styleFrom(backgroundColor: _amber, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: Text('Sí, procesar con IA', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14)),
        )),
      ]),
    ]);
  }

  Widget _filaPreview(int i, List<dynamic> fila) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: i == 0 ? _navy.withOpacity(0.05) : Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(children: fila.asMap().entries.map((e) {
        final colName = e.key == _columnas['codigo'] ? '📌' : e.key == _columnas['nombre'] ? '📝' : e.key == _columnas['precio'] ? '💲' : '';
        return Expanded(child: Text('$colName ${e.value}', style: GoogleFonts.poppins(fontSize: 10, fontWeight: i == 0 ? FontWeight.w700 : FontWeight.normal)));
      }).toList()),
    );
  }

  Widget _buildSelectorColumnas() {
    final ncols = _filasBruto.isNotEmpty ? _filasBruto[0].length : 3;
    final opcs = <DropdownMenuItem<int?>>[const DropdownMenuItem<int?>(value: null, child: Text('—'))]
      + List.generate(ncols, (i) => DropdownMenuItem<int?>(value: i, child: Text('Columna ${i+1}')));
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade200)),
      child: Column(children: [
        _dropCol('📌 Código (opcional)', 'codigo', opcs),
        const Divider(height: 16),
        _dropCol('📝 Nombre del producto', 'nombre', opcs),
        const Divider(height: 16),
        _dropCol('💲 Precio', 'precio', opcs),
      ]),
    );
  }

  Widget _dropCol(String label, String key, List<DropdownMenuItem<int?>> opcs) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: _dark)),
      DropdownButton<int?>(
        value: _columnas[key],
        items: opcs,
        onChanged: (v) => setState(() => _columnas[key] = v),
        style: GoogleFonts.poppins(fontSize: 12, color: _dark),
        underline: Container(height: 1, color: _amber),
      ),
    ]);
  }

  // ─── PASO 2: PROCESANDO ───────────────────────────────────────────────────

  String _mensajeProcesando = 'Enviando al servidor...';

  Widget _buildPaso2Procesando() {
    return Center(child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const CircularProgressIndicator(color: _amber, strokeWidth: 3),
        const SizedBox(height: 24),
        Text('Procesando con IA', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w800, color: _dark)),
        const SizedBox(height: 8),
        Text(_mensajeProcesando, style: GoogleFonts.poppins(fontSize: 12, color: _grey), textAlign: TextAlign.center),
        const SizedBox(height: 16),
        Text('Analizando ${_filasBruto.length} productos...', style: GoogleFonts.poppins(fontSize: 11, color: _grey)),
      ]),
    ));
  }

  Future<void> _procesarConIA() async {
    setState(() { _paso = 2; _mensajeProcesando = 'Analizando columnas...'; });
    await Future.delayed(const Duration(milliseconds: 300));

    setState(() => _mensajeProcesando = 'Buscando coincidencias en tu catálogo...');

    final filasMapeadas = _filasBruto.map((f) {
      final vals = List<dynamic>.from(f);
      while (vals.length < 3) vals.add('');
      return vals;
    }).toList();

    final res = await ApiService.post('/comercio/excel/procesar', {
      'nombreArchivo': _nombreArchivo ?? 'planilla.xlsx',
      'columnas': _columnas,
      'filas': filasMapeadas,
    });

    if (!mounted) return;

    if (res['status'] != 200) {
      setState(() { _paso = 0; _error = 'Error al procesar: ${res['data']?['error'] ?? res['error'] ?? 'status ${res['status']}'}'; });
      return;
    }

    final data = res['data'] as Map<String, dynamic>;
    _automaticos = List<Map<String, dynamic>>.from(data['automaticos'] ?? []);
    _confirmar = List<Map<String, dynamic>>.from(data['confirmar'] ?? []);
    _noEncontrados = List<Map<String, dynamic>>.from(data['noEncontrados'] ?? []);
    _resultado = data;
    _confirmados.clear();
    _vinculadoA.clear();

    setState(() { _paso = 3; });
  }

  // ─── PASO 3: RESULTADOS ───────────────────────────────────────────────────

  Widget _buildPaso3Resultados() {
    final totalAuto = _automaticos.length;
    final totalConfirmar = _confirmar.where((e) => _confirmados[_confirmar.indexOf(e)] == true).length;
    final totalAplicar = totalAuto + totalConfirmar;

    return Column(children: [
      // Resumen
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: _navy,
        child: Row(children: [
          _chipResumen('$totalAuto auto', Colors.green.shade400),
          const SizedBox(width: 8),
          _chipResumen('${_confirmar.length} verificar', Colors.orange.shade400),
          const SizedBox(width: 8),
          _chipResumen('${_noEncontrados.length} no encontrado', Colors.red.shade400),
        ]),
      ),
      Expanded(child: ListView(padding: const EdgeInsets.all(12), children: [
        if (_automaticos.isNotEmpty) ...[
          _seccionHeader('✅ Actualizados automáticamente', Colors.green.shade700, _automaticos.length),
          ..._automaticos.map((e) => _cardAutomatico(e)),
          const SizedBox(height: 16),
        ],
        if (_confirmar.isNotEmpty) ...[
          _seccionHeader('⚠️ Necesitan confirmación', Colors.orange.shade700, _confirmar.length),
          ..._confirmar.asMap().entries.map((e) => _cardConfirmar(e.key, e.value)),
          const SizedBox(height: 16),
        ],
        if (_noEncontrados.isNotEmpty) ...[
          _seccionHeader('❌ No encontrados', Colors.red.shade700, _noEncontrados.length),
          ..._noEncontrados.asMap().entries.map((e) => _cardNoEncontrado(e.key, e.value)),
          const SizedBox(height: 16),
        ],
        const SizedBox(height: 8),
      ])),
      // Botón aplicar
      Container(
        padding: const EdgeInsets.all(16),
        color: Colors.white,
        child: Column(children: [
          if (totalAplicar == 0)
            Text('Confirmá las coincidencias amarillas para aplicar cambios',
              style: GoogleFonts.poppins(fontSize: 12, color: _grey), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: totalAplicar > 0 && !_cargando ? _aplicarCambios : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _amber, foregroundColor: Colors.white, disabledBackgroundColor: Colors.grey.shade300,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _cargando
              ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
              : Text('Aplicar $totalAplicar actualizaciones', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15)),
          )),
        ]),
      ),
    ]);
  }

  Widget _chipResumen(String txt, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
    child: Text(txt, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
  );

  Widget _seccionHeader(String titulo, Color color, int count) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: [
      Text(titulo, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
      const Spacer(),
      Text('$count', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
    ]),
  );

  Widget _cardAutomatico(Map e) {
    final precioAnterior = e['precioActual'];
    final precioNuevo = e['precioNuevo'];
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.green.shade200),
      ),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: Colors.green.shade100,
          child: Text('${e['score']}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.green.shade700))),
        title: Text(e['productoNombre'] ?? '', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700)),
        subtitle: Text('${e['fila']['nombre'] ?? e['fila']['codigo'] ?? ''}', style: GoogleFonts.poppins(fontSize: 10, color: _grey)),
        trailing: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
          if (precioAnterior != null && precioAnterior != precioNuevo)
            Text('\$$precioAnterior', style: GoogleFonts.poppins(fontSize: 10, color: _grey, decoration: TextDecoration.lineThrough)),
          Text('\$$precioNuevo', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.green.shade700)),
        ]),
      ),
    );
  }

  Widget _cardConfirmar(int idx, Map e) {
    final confirmado = _confirmados[idx];
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: confirmado == true ? Colors.green.shade300 : confirmado == false ? Colors.red.shade300 : Colors.orange.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Excel: "${e['fila']['nombre'] ?? e['fila']['codigo'] ?? ''}"',
                style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: _dark)),
              const Icon(Icons.arrow_downward, size: 14, color: _grey),
              Text('Producto: ${e['productoNombre'] ?? ''}${e['productomarca'] != null ? ' (${e['productomarca']})' : ''}',
                style: GoogleFonts.poppins(fontSize: 11, color: _grey)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('Score: ${e['score']}%', style: GoogleFonts.poppins(fontSize: 10, color: _grey)),
              Text('\$${e['precioNuevo']}', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w800, color: _amber)),
            ]),
          ]),
          if (confirmado == null) ...[
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: OutlinedButton.icon(
                onPressed: () => setState(() => _confirmados[idx] = false),
                icon: const Icon(Icons.close, size: 14),
                label: const Text('No es este', style: TextStyle(fontSize: 11)),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red), padding: const EdgeInsets.symmetric(vertical: 8)),
              )),
              const SizedBox(width: 8),
              Expanded(child: ElevatedButton.icon(
                onPressed: () => setState(() => _confirmados[idx] = true),
                icon: const Icon(Icons.check, size: 14),
                label: const Text('Sí, es este', style: TextStyle(fontSize: 11)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 8)),
              )),
            ]),
          ] else if (confirmado == true)
            Container(margin: const EdgeInsets.only(top: 6), padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(6)),
              child: Row(children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 14),
                const SizedBox(width: 4),
                Text('Confirmado — se va a actualizar', style: GoogleFonts.poppins(fontSize: 10, color: Colors.green.shade700)),
                const Spacer(),
                GestureDetector(onTap: () => setState(() => _confirmados.remove(idx)), child: const Icon(Icons.undo, size: 14, color: _grey)),
              ]))
          else
            Container(margin: const EdgeInsets.only(top: 6), padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(6)),
              child: Row(children: [
                const Icon(Icons.cancel, color: Colors.red, size: 14),
                const SizedBox(width: 4),
                Text('Rechazado', style: GoogleFonts.poppins(fontSize: 10, color: Colors.red.shade700)),
                const Spacer(),
                GestureDetector(onTap: () => setState(() => _confirmados.remove(idx)), child: const Icon(Icons.undo, size: 14, color: _grey)),
              ])),
        ]),
      ),
    );
  }

  Widget _cardNoEncontrado(int idx, Map e) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.red.shade200)),
      child: ListTile(
        leading: const CircleAvatar(backgroundColor: Color(0xFFFFEBEE), child: Icon(Icons.help_outline, color: Colors.red, size: 18)),
        title: Text(e['fila']['nombre'] ?? e['fila']['codigo'] ?? 'Sin nombre',
          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: _dark)),
        subtitle: Text('No se encontró coincidencia', style: GoogleFonts.poppins(fontSize: 10, color: _grey)),
        trailing: Text('\$${e['fila']['precio']}', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: _grey)),
      ),
    );
  }

  // ─── APLICAR CAMBIOS ─────────────────────────────────────────────────────

  Future<void> _aplicarCambios() async {
    final totalAuto = _automaticos.length;
    final confirmadosManual = _confirmar.asMap().entries.where((e) => _confirmados[e.key] == true).toList();
    final total = totalAuto + confirmadosManual.length;

    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text('¿Aplicar cambios?', style: GoogleFonts.poppins(fontWeight: FontWeight.w800)),
      content: Text('Se van a actualizar los precios de $total productos en tu catálogo.',
        style: GoogleFonts.poppins(fontSize: 13)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: ElevatedButton.styleFrom(backgroundColor: _amber),
          child: Text('Sí, actualizar', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: Colors.white)),
        ),
      ],
    ));

    if (ok != true || !mounted) return;
    setState(() => _cargando = true);

    final actualizaciones = [
      ..._automaticos.map((e) => {
        'productoId': e['productoId'],
        'precioNuevo': e['precioNuevo'],
        'fila': e['fila'],
        'confirmaManual': false,
        'aprendidoId': e['aprendidoId'],
      }),
      ...confirmadosManual.map((e) => {
        'productoId': e.value['productoId'],
        'precioNuevo': e.value['precioNuevo'],
        'fila': e.value['fila'],
        'confirmaManual': true,
        'aprendidoId': null,
      }),
    ];

    final res = await ApiService.post('/comercio/excel/confirmar', {
      'actualizaciones': actualizaciones,
      'nombreArchivo': _nombreArchivo ?? 'planilla.xlsx',
      'totalFilas': _filasBruto.length,
      'noEncontrados': _noEncontrados.length,
    });

    if (!mounted) return;
    setState(() => _cargando = false);

    if (res['status'] == 200) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('✓ ${res['data']['total']} precios actualizados correctamente'),
        backgroundColor: _success,
        duration: const Duration(seconds: 4),
      ));
      setState(() { _paso = 0; _filasBruto = []; _resultado = null; });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: ${res['data']?['error'] ?? 'No se pudo aplicar'}'),
        backgroundColor: Colors.red,
      ));
    }
  }

  // ─── PASO 4: HISTORIAL ────────────────────────────────────────────────────

  List<dynamic> _historial = [];
  bool _cargandoHistorial = false;

  Widget _buildPaso4Historial() {
    if (_historial.isEmpty && !_cargandoHistorial) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _cargarHistorial());
    }
    return Column(children: [
      Container(
        padding: const EdgeInsets.all(12),
        color: _navy,
        child: Row(children: [
          IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => setState(() { _paso = 0; })),
          Text('Historial de cargas', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
        ]),
      ),
      Expanded(child: _cargandoHistorial
        ? const Center(child: CircularProgressIndicator(color: _amber))
        : _historial.isEmpty
          ? Center(child: Text('Aún no hay cargas registradas', style: GoogleFonts.poppins(color: _grey)))
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: _historial.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _cardHistorial(_historial[i]),
            )),
    ]);
  }

  Widget _cardHistorial(Map h) {
    final fecha = DateTime.tryParse(h['fecha_carga']?.toString() ?? '');
    final revertido = h['revertido'] == true;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(h['nombre_archivo'] ?? 'Sin nombre', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700))),
            if (revertido) Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4)), child: Text('Revertido', style: GoogleFonts.poppins(fontSize: 9, color: _grey))),
          ]),
          if (fecha != null) Text('${fecha.day}/${fecha.month}/${fecha.year} ${fecha.hour}:${fecha.minute.toString().padLeft(2,'0')}', style: GoogleFonts.poppins(fontSize: 10, color: _grey)),
          const SizedBox(height: 6),
          Row(children: [
            _statChip('${h['actualizados_automatico']} auto', Colors.green),
            const SizedBox(width: 6),
            _statChip('${h['actualizados_manual']} manual', Colors.orange),
            const SizedBox(width: 6),
            _statChip('${h['no_encontrados']} no enc.', Colors.red),
          ]),
          if (!revertido) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => _deshacerCarga(int.tryParse(h['id'].toString()) ?? 0),
              style: TextButton.styleFrom(foregroundColor: Colors.red, padding: EdgeInsets.zero),
              child: Text('Deshacer esta carga', style: GoogleFonts.poppins(fontSize: 11)),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _statChip(String txt, MaterialColor color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: color.shade50, borderRadius: BorderRadius.circular(12)),
    child: Text(txt, style: GoogleFonts.poppins(fontSize: 10, color: color.shade700, fontWeight: FontWeight.w600)),
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
    if (ok != true) return;
    final r = await ApiService.post('/comercio/excel/deshacer/$id', {});
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(r['status'] == 200 ? '✓ Carga revertida' : 'Error: ${r['data']?['error'] ?? 'no se pudo'}'),
      backgroundColor: r['status'] == 200 ? _success : Colors.red,
    ));
    _cargarHistorial();
  }
}
