import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/api_service.dart';
import 'marcas_screen.dart';

const _navy  = Color(0xFF1E3A5F);
const _amber = Color(0xFFE07B00);
const _bg    = Color(0xFFF5F5F5);
const _dark  = Color(0xFF1A1A1A);
const _grey  = Color(0xFF888888);
const _green = Color(0xFF2E7D32);

// ─────────────────────────────────────────────────────────────────────────────
// NIVEL 1 — Lista de grupos
// ─────────────────────────────────────────────────────────────────────────────
class CatalogoNavegacionScreen extends StatefulWidget {
  const CatalogoNavegacionScreen({super.key});
  @override
  State<CatalogoNavegacionScreen> createState() => _CatalogoNavegacionScreenState();
}

class _CatalogoNavegacionScreenState extends State<CatalogoNavegacionScreen> {
  List<dynamic> _grupos = [];
  List<dynamic> _misMarcas = [];
  Set<String> _misMarcasNombres = {}; // nombres de marcas con productos en mi catálogo
  bool _cargando = true;
  final _busCtrl = TextEditingController();
  String _q = '';

  @override
  void initState() { super.initState(); _cargar(); }

  Future<void> _cargar() async {
    final g = await ApiService.get('/marcas/grupos');
    final m = await ApiService.get('/marcas/mis-marcas');
    final misProd = await ApiService.misProductos();
    if (!mounted) return;
    // g['data'] = el JSON crudo de /marcas/grupos (un array directo)
    // m['data'] = el JSON crudo de /marcas/mis-marcas ({ok, data:[...]})
    final gRaw = g['data'];
    final mRaw = m['data'];
    setState(() {
      _grupos    = gRaw is List ? gRaw : [];
      _misMarcas = mRaw is Map && mRaw['data'] is List ? mRaw['data']
                 : mRaw is List ? mRaw : [];
      _misMarcasNombres = misProd
        .map((p) => ((p['marca'] as String?) ?? '').toLowerCase().trim())
        .where((s) => s.isNotEmpty)
        .toSet();
      _cargando  = false;
    });
  }

  List<dynamic> get _filtrados {
    if (_q.isEmpty) return _grupos;
    final q = _q.toLowerCase();
    return _grupos.where((g) =>
      (g['nombre'] as String).toLowerCase().contains(q) ||
      (g['subcategorias'] as List? ?? []).any((s) => (s['nombre'] as String).toLowerCase().contains(q))
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // Header
      Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(children: [
          Row(children: [
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Catálogo maestro', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: _dark)),
              Text('Elegí un rubro para agregar productos', style: TextStyle(fontSize: 11, color: _grey)),
            ])),
            GestureDetector(
              onTap: () async {
                await Navigator.push(context, MaterialPageRoute(
                  builder: (_) => MarcasScreen(modoEdicion: true, onGuardado: _cargar)));
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(color: _navy, borderRadius: BorderRadius.circular(10)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.branding_watermark_rounded, size: 14, color: Colors.white),
                  SizedBox(width: 4),
                  Text('Mis marcas', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700)),
                ]),
              ),
            ),
          ]),
          const SizedBox(height: 10),
          TextField(
            controller: _busCtrl,
            onChanged: (v) => setState(() => _q = v),
            decoration: InputDecoration(
              hintText: 'Buscar rubro...',
              prefixIcon: const Icon(Icons.search, size: 18, color: _grey),
              filled: true, fillColor: _bg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              suffixIcon: _q.isNotEmpty
                ? IconButton(icon: const Icon(Icons.close, size: 16), onPressed: () { _busCtrl.clear(); setState(() => _q = ''); })
                : null,
            ),
          ),
        ]),
      ),
      // Lista grupos
      Expanded(
        child: _cargando
          ? const Center(child: CircularProgressIndicator(color: _navy))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _filtrados.length,
              itemBuilder: (_, i) {
                final g = _filtrados[i];
                // Marcas de este grupo que trabaja el comercio
                final grupoId = g['id'] as int;
                final marcasGrupo = _misMarcas.where((m) {
                  final gid = m['grupo_id'];
                  return gid != null && (gid is int ? gid : int.tryParse(gid.toString())) == grupoId;
                }).toList();

                return GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => _PantallaEleccionMarca(
                      grupo: g,
                      marcasGrupo: marcasGrupo,
                      todasMisMarcas: _misMarcas,
                      misMarcasNombres: _misMarcasNombres,
                      onCatalogoActualizado: _cargar,
                    ),
                  )),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(children: [
                      Text(g['icono'] ?? '📦', style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(g['nombre'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _dark)),
                        if (marcasGrupo.isNotEmpty)
                          Text(marcasGrupo.map((m) => m['nombre']).join(', '),
                            style: const TextStyle(fontSize: 10, color: _grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ])),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: _grey),
                    ]),
                  ),
                );
              },
            ),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NIVEL 2 — Elección de marca dentro de un grupo
// ─────────────────────────────────────────────────────────────────────────────
class _PantallaEleccionMarca extends StatelessWidget {
  final dynamic grupo;
  final List<dynamic> marcasGrupo;
  final List<dynamic> todasMisMarcas;
  final Set<String> misMarcasNombres;
  final VoidCallback onCatalogoActualizado;

  const _PantallaEleccionMarca({
    required this.grupo,
    required this.marcasGrupo,
    required this.todasMisMarcas,
    required this.misMarcasNombres,
    required this.onCatalogoActualizado,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(grupo['nombre'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
          const Text('Elegí una marca', style: TextStyle(fontSize: 10, color: Colors.white70)),
        ]),
      ),
      body: _MarcasGrupoLoader(
        grupoId: grupo['id'] as int,
        grupoNombre: grupo['nombre'] as String,
        misMarcasNombres: misMarcasNombres,
        onElegir: (marcaId, marcaNombre) async {
          await Navigator.push(context, MaterialPageRoute(
            builder: (_) => _PantallaProductosGrupoMarca(
              grupo: grupo,
              marcaNombre: marcaNombre,
            ),
          ));
          onCatalogoActualizado();
        },
      ),
    );
  }

}

// ─────────────────────────────────────────────────────────────────────────────
// Carga y muestra todas las marcas disponibles para un grupo
// ─────────────────────────────────────────────────────────────────────────────
class _MarcasGrupoLoader extends StatefulWidget {
  final int grupoId;
  final String grupoNombre;
  final Set<String> misMarcasNombres;
  final void Function(int? marcaId, String? marcaNombre) onElegir;

  const _MarcasGrupoLoader({
    required this.grupoId,
    required this.grupoNombre,
    required this.misMarcasNombres,
    required this.onElegir,
  });

  @override
  State<_MarcasGrupoLoader> createState() => _MarcasGrupoLoaderState();
}

class _MarcasGrupoLoaderState extends State<_MarcasGrupoLoader> {
  List<dynamic> _marcas = [];
  bool _cargando = true;

  @override
  void initState() { super.initState(); _cargar(); }

  Future<void> _cargar() async {
    final res = await ApiService.get('/marcas/por-grupo/${widget.grupoId}');
    if (!mounted) return;
    // ApiService.get devuelve {status, data: {ok, data: [...]}}
    final body = res['data'];
    final lista = body is Map ? body['data'] : body;
    setState(() {
      _marcas   = lista is List ? lista : [];
      _cargando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) return const Center(child: CircularProgressIndicator(color: _navy));
    if (_marcas.isEmpty) return Center(
      child: Text('No hay marcas registradas para "${widget.grupoNombre}"',
        textAlign: TextAlign.center, style: const TextStyle(color: _grey, fontSize: 13)),
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _cardMarcaItem(context, null, 'Todos los productos del rubro', false),
        const SizedBox(height: 8),
        ..._marcas.map((m) {
          final nombre = m['nombre'] as String;
          final enCatalogo = widget.misMarcasNombres.contains(nombre.toLowerCase().trim());
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _cardMarcaItem(context, m, nombre, enCatalogo),
          );
        }),
      ],
    );
  }

  Widget _cardMarcaItem(BuildContext context, dynamic m, String nombre, bool enCatalogo) {
    return GestureDetector(
      onTap: () => widget.onElegir(m?['id'] as int?, m != null ? nombre : null),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: enCatalogo ? _green.withValues(alpha: 0.35) : Colors.grey.shade200,
            width: enCatalogo ? 1.5 : 1,
          ),
        ),
        child: Row(children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: enCatalogo ? _green.withValues(alpha: 0.08) : _bg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(child: Text(m == null ? '📦' : '🏷️', style: const TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(nombre, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _dark)),
            if (enCatalogo)
              const Text('Tenés productos cargados', style: TextStyle(fontSize: 10, color: _green)),
          ])),
          const SizedBox(width: 8),
          // Estado visual + acción
          if (enCatalogo)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _green.withValues(alpha: 0.4)),
              ),
              child: const Text('✓ En mi\ncatálogo', textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: _green)),
            )
          else if (m != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _amber.withValues(alpha: 0.5)),
              ),
              child: const Text('+ Agregar', textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: _amber)),
            )
          else
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: _grey),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NIVEL 3 — Productos del grupo/marca para agregar al catálogo
// ─────────────────────────────────────────────────────────────────────────────
class _PantallaProductosGrupoMarca extends StatefulWidget {
  final dynamic grupo;
  final String? marcaNombre; // null = todos los productos del grupo

  const _PantallaProductosGrupoMarca({
    super.key,
    required this.grupo,
    required this.marcaNombre,
  });

  @override
  State<_PantallaProductosGrupoMarca> createState() => _PantallaProductosGrupoMarcaState();
}

class _PantallaProductosGrupoMarcaState extends State<_PantallaProductosGrupoMarca> {
  List<dynamic> _productos = [];
  Set<int> _agregados = {};
  bool _cargando = true;

  @override
  void initState() { super.initState(); _cargar(); }

  Future<void> _cargar() async {
    // Cargar productos del catálogo maestro filtrados por nombre de marca
    final res = await ApiService.buscarCatalogoPagina(
      marcaNombre: widget.marcaNombre,
      limit: 100,
      offset: 0,
    );
    // Cargar mis productos para saber cuáles ya agregué
    final misProds = await ApiService.misProductos();
    if (!mounted) return;
    final yaAgregados = misProds.map((p) => p['producto_id'] as int).toSet();
    setState(() {
      _productos = res['productos'] as List;
      _agregados = yaAgregados;
      _cargando  = false;
    });
  }

  Future<void> _agregar(Map prod) async {
    final precioCtrl = TextEditingController();
    final stockCtrl  = TextEditingController(text: '10');
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(prod['nombre'], style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _dark)),
          if (prod['marca'] != null) Text(prod['marca'], style: const TextStyle(fontSize: 12, color: _grey)),
          const SizedBox(height: 18),
          const Text('Tu precio de venta (\$)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          TextField(
            controller: precioCtrl,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Ej: 5500',
              prefixText: '\$ ',
              filled: true, fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 12),
          const Text('Stock inicial', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          TextField(
            controller: stockCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              filled: true, fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity, height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _amber, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                final precio = double.tryParse(precioCtrl.text);
                final stock  = int.tryParse(stockCtrl.text) ?? 10;
                if (precio == null || precio <= 0) return;
                Navigator.pop(context);
                final ok = await ApiService.activarProducto(0, prod['id'] as int, precio, stock);
                if (!mounted) return;
                if (ok) setState(() => _agregados.add(prod['id'] as int));
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(ok ? '${prod['nombre']} agregado a tu catálogo ✓' : 'Error al agregar'),
                  backgroundColor: ok ? _green : Colors.red,
                ));
              },
              child: const Text('Agregar a mi catálogo', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Agrupar por subcategoría
    final Map<String, List<dynamic>> porSub = {};
    for (final p in _productos) {
      final sub = (p['subcategoria'] as String? ?? 'Otros').trim();
      porSub.putIfAbsent(sub, () => []).add(p);
    }
    final subs = porSub.keys.toList()..sort();

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.marcaNombre ?? 'Todos los productos', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
          Text(widget.grupo['nombre'], style: const TextStyle(fontSize: 10, color: Colors.white70)),
        ]),
      ),
      body: _cargando
        ? const Center(child: CircularProgressIndicator(color: _navy))
        : _productos.isEmpty
          ? const Center(child: Text('No hay productos en el catálogo para esta selección', style: TextStyle(color: _grey)))
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                for (final sub in subs) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(2, 16, 2, 8),
                    child: Text(sub,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: _navy, letterSpacing: 0.2)),
                  ),
                  for (final p in porSub[sub]!) _cardProducto(p),
                ],
              ],
            ),
    );
  }

  Widget _cardProducto(Map p) {
    final yaAgregado = _agregados.contains(p['id'] as int);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: yaAgregado ? _green.withValues(alpha: 0.3) : Colors.grey.shade100),
      ),
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: p['imagen_principal_url'] != null
            ? Image.network(p['imagen_principal_url'], width: 60, height: 60, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholder())
            : _placeholder(),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(p['nombre'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _dark), maxLines: 2, overflow: TextOverflow.ellipsis),
          if (p['marca'] != null) Text(p['marca'], style: const TextStyle(fontSize: 10, color: _grey)),
          if (p['unidad'] != null) Text(p['unidad'], style: const TextStyle(fontSize: 10, color: _grey)),
        ])),
        const SizedBox(width: 8),
        yaAgregado
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(color: _green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: const Text('✓ En mi\ncatálogo', textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _green)),
            )
          : ElevatedButton(
              onPressed: () => _agregar(Map.from(p)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _amber, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('+ Agregar', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
            ),
      ]),
    );
  }

  Widget _placeholder() => Container(
    width: 60, height: 60,
    color: Colors.grey.shade100,
    child: const Icon(Icons.inventory_2_outlined, color: Colors.grey),
  );
}
