// Pantalla para actualizar precios y stock de muchos productos a la vez,
// subiendo un archivo CSV o Excel (.xlsx) con columnas: producto_id, precio, stock
import 'package:excel/excel.dart' as xls;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

const _amber = Color(0xFFE07B00);
const _textDark = Color(0xFF1A1A1A);
const _success = Color(0xFF2E7D32);

class CargaMasivaScreen extends StatefulWidget {
  const CargaMasivaScreen({super.key});
  @override
  State<CargaMasivaScreen> createState() => _CargaMasivaScreenState();
}

class _CargaMasivaScreenState extends State<CargaMasivaScreen> {
  bool _procesando = false;
  String? _nombreArchivo;
  Map<String, dynamic>? _resultado;
  String? _error;

  // Convierte el contenido del CSV en una lista de filas {producto_id, precio, stock}.
  // Tolera encabezado opcional y espacios extra. Formato esperado por columna:
  // producto_id,precio,stock
  List<Map<String, dynamic>> _parsearCsv(String contenido) {
    final filas = <Map<String, dynamic>>[];
    final lineas = contenido.split(RegExp(r'\r?\n')).where((l) => l.trim().isNotEmpty).toList();
    for (final linea in lineas) {
      final partes = linea.split(',').map((p) => p.trim()).toList();
      if (partes.length < 2) continue;
      final productoId = int.tryParse(partes[0]);
      final precio = double.tryParse(partes[1].replaceAll('\$', '').replaceAll('.', '').replaceAll(',', '.'));
      final precioSimple = double.tryParse(partes[1]);
      final stock = partes.length > 2 ? int.tryParse(partes[2]) : null;
      if (productoId == null) continue; // probablemente la fila de encabezado
      filas.add({
        'producto_id': productoId,
        'precio': precioSimple ?? precio,
        'stock': stock ?? 0,
      });
    }
    return filas;
  }

  // Convierte la primera hoja de un Excel en filas {producto_id, precio, stock}.
  // Misma lógica que el CSV: tolera encabezado, toma columnas A/B/C (0,1,2).
  List<Map<String, dynamic>> _parsearExcel(List<int> bytes) {
    final filas = <Map<String, dynamic>>[];
    final libro = xls.Excel.decodeBytes(bytes);
    if (libro.tables.isEmpty) return filas;
    final hoja = libro.tables.values.first;
    for (final fila in hoja.rows) {
      if (fila.isEmpty) continue;
      final productoId = int.tryParse('${fila[0]?.value ?? ''}'.trim());
      if (productoId == null) continue; // probablemente encabezado o fila vacía
      final precio = double.tryParse('${fila.length > 1 ? fila[1]?.value ?? '' : ''}'.trim());
      final stock = fila.length > 2 ? int.tryParse('${fila[2]?.value ?? ''}'.trim()) : null;
      filas.add({'producto_id': productoId, 'precio': precio, 'stock': stock ?? 0});
    }
    return filas;
  }

  Future<void> _elegirArchivo() async {
    final resultado = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'xlsx', 'xls'],
      withData: true,
    );
    if (resultado == null || resultado.files.isEmpty) return;
    final archivo = resultado.files.first;
    if (archivo.bytes == null) {
      setState(() => _error = 'No se pudo leer el archivo');
      return;
    }
    setState(() { _procesando = true; _error = null; _resultado = null; _nombreArchivo = archivo.name; });

    try {
      final esExcel = archivo.name.toLowerCase().endsWith('.xlsx') || archivo.name.toLowerCase().endsWith('.xls');
      final filas = esExcel ? _parsearExcel(archivo.bytes!) : _parsearCsv(String.fromCharCodes(archivo.bytes!));
      if (filas.isEmpty) {
        setState(() { _procesando = false; _error = 'El archivo no tiene filas válidas (producto_id, precio, stock)'; });
        return;
      }
      final res = await ApiService.importarProductosCsv(filas);
      setState(() { _procesando = false; _resultado = res; });
    } catch (e) {
      setState(() { _procesando = false; _error = 'Error al procesar el archivo: $e'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Carga masiva de precios'), backgroundColor: Colors.white, foregroundColor: _textDark, elevation: 0.5),
      backgroundColor: const Color(0xFFF7F7F7),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Formato del archivo (CSV o Excel)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: _textDark)),
              const SizedBox(height: 8),
              const Text(
                'Una fila por producto, 3 columnas: producto_id, precio, stock.\n\n'
                'CSV: producto_id,precio,stock\n241,12500,20\n247,3400,15\n\n'
                'Excel (.xlsx): la misma info en columnas A, B y C de la primera hoja.\n\n'
                'El producto_id es el ID del catálogo maestro (lo podés ver en "Catálogo maestro" → buscador).',
                style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.5),
              ),
            ]),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity, height: 50,
            child: ElevatedButton.icon(
              onPressed: _procesando ? null : _elegirArchivo,
              icon: const Icon(Icons.upload_file),
              label: Text(_procesando ? 'Procesando...' : 'Elegir archivo (CSV o Excel)'),
              style: ElevatedButton.styleFrom(backgroundColor: _amber, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            ),
          ),
          if (_nombreArchivo != null) Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text('Archivo: $_nombreArchivo', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ),
          if (_procesando) const Padding(
            padding: EdgeInsets.only(top: 20),
            child: Center(child: CircularProgressIndicator(color: _amber)),
          ),
          if (_error != null) Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10)),
            child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
          ),
          if (_resultado != null) Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(10)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${_resultado!['actualizados'] ?? 0} productos actualizados ✓',
                style: const TextStyle(color: _success, fontWeight: FontWeight.w700)),
              if ((_resultado!['errores'] as List?)?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                const Text('Filas con error:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                ...List<String>.from(_resultado!['errores']).map((e) => Text('• $e', style: const TextStyle(fontSize: 11, color: Colors.red))),
              ],
            ]),
          ),
        ]),
      ),
    );
  }
}
