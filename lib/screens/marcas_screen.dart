import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../services/api_service.dart';

const _navy  = Color(0xFF1E3A5F);
const _bg    = Color(0xFFF5F5F5);
const _textDark = Color(0xFF1A1A1A);
const _textGrey = Color(0xFF888888);
const _success  = Color(0xFF2E7D32);

class MarcasScreen extends StatefulWidget {
  final VoidCallback? onGuardado;
  final bool modoEdicion; // true = viene desde catálogo para editar, false = primera vez
  const MarcasScreen({super.key, this.onGuardado, this.modoEdicion = false});
  @override
  State<MarcasScreen> createState() => _MarcasScreenState();
}

class _MarcasScreenState extends State<MarcasScreen> {
  // rubros → lista de marcas
  Map<String, List<Map<String, dynamic>>> _todasMarcas = {};
  // ids de marcas seleccionadas por este comercio
  final Set<int> _seleccionadas = {};
  bool _cargando = true;
  bool _guardando = false;
  String _busqueda = '';
  String? _rubroExpandido;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final todasRes = await ApiService.get('/marcas');
    final misRes   = await ApiService.get('/marcas/mis-marcas');

    if (!mounted) return;
    final todas = todasRes['data'] as Map<String, dynamic>? ?? {};
    final mis   = misRes['data'] is List ? misRes['data'] as List : [];

    setState(() {
      _todasMarcas = todas.map((rubro, lista) => MapEntry(
        rubro,
        (lista as List).map((m) => Map<String, dynamic>.from(m)).toList(),
      ));
      _seleccionadas.addAll(mis.map<int>((m) => m['id'] as int));
      _cargando = false;
    });
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    final res = await ApiService.post('/marcas/mis-marcas', {
      'marca_ids': _seleccionadas.toList(),
    });
    if (!mounted) return;
    setState(() => _guardando = false);
    if (res['status'] == 200) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Marcas guardadas correctamente'),
        backgroundColor: _success,
      ));
      widget.onGuardado?.call();
      if (!widget.modoEdicion) Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res['data']?['error'] ?? 'Error al guardar'),
        backgroundColor: Colors.red,
      ));
    }
  }

  Future<void> _agregarMarcaNueva() async {
    final nombreCtrl = TextEditingController();
    String rubroElegido = _todasMarcas.keys.first;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Agregar marca nueva', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: nombreCtrl,
            decoration: const InputDecoration(labelText: 'Nombre de la marca', border: OutlineInputBorder()),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 12),
          StatefulBuilder(builder: (ctx2, setS) => DropdownButtonFormField<String>(
            value: rubroElegido,
            decoration: const InputDecoration(labelText: 'Rubro', border: OutlineInputBorder()),
            items: _todasMarcas.keys.map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 13)))).toList(),
            onChanged: (v) => setS(() => rubroElegido = v!),
          )),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _navy),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Agregar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (ok != true || nombreCtrl.text.trim().isEmpty) return;

    final res = await ApiService.post('/marcas', {
      'nombre': nombreCtrl.text.trim(),
      'rubro': rubroElegido,
    });
    if (!mounted) return;
    if (res['status'] == 201) {
      await _cargar(); // recargar lista completa
      final nuevaId = res['data']['id'] as int;
      setState(() => _seleccionadas.add(nuevaId));
    }
  }

  List<Map<String, dynamic>> _filtrarMarcas(List<Map<String, dynamic>> lista) {
    if (_busqueda.isEmpty) return lista;
    return lista.where((m) =>
      (m['nombre'] as String).toLowerCase().contains(_busqueda.toLowerCase())).toList();
  }

  @override
  Widget build(BuildContext context) {
    final totalSeleccionadas = _seleccionadas.length;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        title: Text(
          widget.modoEdicion ? 'Editar mis marcas' : 'Elegí las marcas que trabajás',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        actions: [
          if (widget.modoEdicion)
            TextButton.icon(
              onPressed: _agregarMarcaNueva,
              icon: const Icon(Icons.add, color: Colors.white, size: 18),
              label: const Text('Nueva', style: TextStyle(color: Colors.white, fontSize: 12)),
            ),
        ],
      ),
      body: _cargando
        ? const Center(child: CircularProgressIndicator(color: _navy))
        : Column(children: [
            // Header con contador y búsqueda
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(children: [
                if (!widget.modoEdicion)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      'Seleccioná todas las marcas que tu comercio trabaja. Podés cambiarlas en cualquier momento desde el catálogo.',
                      style: const TextStyle(fontSize: 12, color: _textGrey),
                      textAlign: TextAlign.center,
                    ),
                  ),
                Row(children: [
                  Expanded(
                    child: TextField(
                      onChanged: (v) => setState(() => _busqueda = v),
                      decoration: InputDecoration(
                        hintText: 'Buscar marca...',
                        prefixIcon: const Icon(Icons.search, size: 18, color: _textGrey),
                        filled: true, fillColor: _bg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: _navy, borderRadius: BorderRadius.circular(10)),
                    child: Text('$totalSeleccionadas selec.', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ]),
              ]),
            ),

            // Lista de rubros con marcas
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: _todasMarcas.entries.map((entry) {
                  final rubro = entry.key;
                  final marcas = _filtrarMarcas(entry.value);
                  if (marcas.isEmpty) return const SizedBox.shrink();

                  final selecEnRubro = marcas.where((m) => _seleccionadas.contains(m['id'] as int)).length;
                  final expandido = _busqueda.isNotEmpty || _rubroExpandido == rubro;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: selecEnRubro > 0 ? _navy.withValues(alpha: 0.3) : Colors.grey.shade200),
                    ),
                    child: Column(children: [
                      // Header del rubro
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => setState(() => _rubroExpandido = expandido ? null : rubro),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Row(children: [
                            Text(_rubroIcono(rubro), style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 10),
                            Expanded(child: Text(rubro, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _textDark))),
                            if (selecEnRubro > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(color: _success, borderRadius: BorderRadius.circular(20)),
                                child: Text('$selecEnRubro', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                              ),
                            const SizedBox(width: 6),
                            Icon(expandido ? Icons.expand_less : Icons.expand_more, color: _textGrey, size: 20),
                          ]),
                        ),
                      ),

                      // Marcas del rubro
                      if (expandido)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          child: Wrap(
                            spacing: 8, runSpacing: 8,
                            children: marcas.map((m) {
                              final id = m['id'] as int;
                              final sel = _seleccionadas.contains(id);
                              return GestureDetector(
                                onTap: () => setState(() {
                                  if (sel) _seleccionadas.remove(id);
                                  else _seleccionadas.add(id);
                                }),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: sel ? _navy : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: sel ? _navy : Colors.grey.shade300),
                                  ),
                                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                                    if (sel) ...[
                                      const Icon(Icons.check_rounded, size: 13, color: Colors.white),
                                      const SizedBox(width: 4),
                                    ],
                                    Text(m['nombre'], style: TextStyle(
                                      fontSize: 12, fontWeight: FontWeight.w600,
                                      color: sel ? Colors.white : _textDark,
                                    )),
                                  ]),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                    ]),
                  );
                }).toList(),
              ),
            ),
          ]),

      // Botón guardar
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          color: Colors.white,
          child: ElevatedButton(
            onPressed: _guardando || _seleccionadas.isEmpty ? null : _guardar,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: Colors.grey.shade300,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _guardando
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text(
                  _seleccionadas.isEmpty
                    ? 'Seleccioná al menos una marca'
                    : 'Guardar $totalSeleccionadas marcas',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
                ),
          ),
        ),
      ),
    );
  }

  String _rubroIcono(String rubro) {
    switch (rubro) {
      case 'Pinturas':              return '🎨';
      case 'Placas y Steel Frame':  return '🧱';
      case 'Cementos':              return '🏗️';
      case 'Adhesivos y Masillas':  return '🪣';
      case 'Abrasivos':             return '⚙️';
      case 'Herramientas':          return '🔧';
      case 'Hierro y Acero':        return '🔩';
      case 'Sanitarios y Grifería': return '🚿';
      case 'Impermeabilizantes':    return '💧';
      case 'Electricidad':          return '⚡';
      case 'Cables':                return '🔌';
      case 'Caños y Tuberías':      return '🪠';
      case 'Maderas y Tableros':    return '🪵';
      case 'Cerámicos':             return '🏠';
      case 'Selladores':            return '🔒';
      case 'Aislantes':             return '🧊';
      case 'Yeso':                  return '🪨';
      default:                      return '📦';
    }
  }
}
