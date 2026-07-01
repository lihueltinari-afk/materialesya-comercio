import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/api_service.dart';
import 'carga_masiva_screen.dart';
import 'marcas_screen.dart';
import 'catalogo_navegacion_screen.dart';

const _amber = Color(0xFFE07B00);
const _textDark = Color(0xFF1A1A1A);
const _success = Color(0xFF2E7D32);

class CatalogoScreen extends StatefulWidget {
  final int? comercioId;
  const CatalogoScreen({super.key, this.comercioId});
  @override
  State<CatalogoScreen> createState() => _CatalogoScreenState();
}

const _porPagina = 24;

class _CatalogoScreenState extends State<CatalogoScreen> {
  final _busquedaCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  List<dynamic> _productos = [];
  List<dynamic> _categorias = [];
  List<dynamic> _misProductos = [];
  List<dynamic> _misMarcas = [];
  String? _marcaFiltroMisProductos; // marca seleccionada en "Mi catálogo"
  String _busquedaMiCatalogo = '';
  final _busMiCatCtrl = TextEditingController();
  int? _categoriaSeleccionada;
  int? _marcaSeleccionada;
  String? _marcaNombre;
  int? _subcategoriaSeleccionada;
  String? _subcategoriaNombre;
  bool _cargando = false;
  bool _cargandoMas = false;
  bool _hayMas = true;
  bool _vistaMisProductos = false;
  bool _vistaSeleccionMarca = true; // empieza en selección de marca

  @override
  void initState() {
    super.initState();
    _cargarCategorias();
    _cargarMisMarcas();
    _scrollCtrl.addListener(() {
      if (_scrollCtrl.position.pixels > _scrollCtrl.position.maxScrollExtent - 300) {
        _cargarMas();
      }
    });
  }

  Future<void> _cargarMisMarcas() async {
    final res = await ApiService.get('/marcas/mis-marcas');
    if (!mounted) return;
    final marcas = res['data'] is List ? res['data'] as List : [];
    setState(() {
      _misMarcas = marcas;
      // Si no tiene marcas configuradas, ir directo al catálogo completo
      if (marcas.isEmpty) _vistaSeleccionMarca = false;
    });
  }

  void _elegirMarca(int? marcaId, String? nombre, [int? subcategoriaId, String? subcategoriaNombre]) {
    setState(() {
      _marcaSeleccionada = marcaId;
      _marcaNombre = nombre;
      _subcategoriaSeleccionada = subcategoriaId;
      _subcategoriaNombre = subcategoriaNombre;
      _vistaSeleccionMarca = false;
    });
    _buscar();
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarCategorias() async {
    final cats = await ApiService.obtenerCategorias();
    setState(() => _categorias = cats);
  }

  // Primera página de resultados (reinicia la lista al buscar/filtrar).
  Future<void> _buscar() async {
    setState(() { _cargando = true; _hayMas = true; });
    final res = await ApiService.buscarCatalogoPagina(
      busqueda: _busquedaCtrl.text,
      categoriaId: _categoriaSeleccionada,
      marcaId: _marcaSeleccionada,
      subcategoriaId: _subcategoriaSeleccionada,
      limit: _porPagina,
      offset: 0,
    );
    setState(() {
      _productos = res['productos'];
      _hayMas = res['hayMas'] ?? false;
      _cargando = false;
    });
  }

  // Página siguiente: se dispara sola al llegar cerca del final del scroll (infinite scroll).
  Future<void> _cargarMas() async {
    if (_cargandoMas || !_hayMas || _cargando || _vistaMisProductos) return;
    setState(() => _cargandoMas = true);
    final res = await ApiService.buscarCatalogoPagina(
      busqueda: _busquedaCtrl.text,
      categoriaId: _categoriaSeleccionada,
      marcaId: _marcaSeleccionada,
      subcategoriaId: _subcategoriaSeleccionada,
      limit: _porPagina,
      offset: _productos.length,
    );
    setState(() {
      _productos = [..._productos, ...(res['productos'] as List)];
      _hayMas = res['hayMas'] ?? false;
      _cargandoMas = false;
    });
  }

  Future<void> _cargarMisProductos() async {
    setState(() => _cargando = true);
    final prods = await ApiService.misProductos();
    setState(() { _misProductos = prods; _cargando = false; });
  }

  void _cambiarVista(bool misProductos) {
    setState(() {
      _vistaMisProductos = misProductos;
      _marcaFiltroMisProductos = null;
    });
    if (misProductos) _cargarMisProductos();
  }

  void _mostrarActivar(Map producto) {
    final precioCtrl = TextEditingController();
    final stockCtrl = TextEditingController(text: '10');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(producto['nombre'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _textDark)),
          Text(producto['marca'] ?? '', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 20),
          const Text('Tu precio de venta (\$)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextField(
            controller: precioCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Ej: 5500',
              prefixText: '\$ ',
              filled: true, fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
            ),
          ),
          const SizedBox(height: 12),
          const Text('Stock disponible', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextField(
            controller: stockCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              filled: true, fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity, height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _amber, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () async {
                final precio = double.tryParse(precioCtrl.text);
                final stock = int.tryParse(stockCtrl.text);
                if (precio == null || precio <= 0) return;
                Navigator.pop(context);
                final ok = await ApiService.activarProducto(
                  widget.comercioId ?? 0, producto['id'] as int, precio, stock ?? 0);
                if (ok) _cambiarVista(true);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(ok ? '${producto['nombre']} agregado al catálogo ✓' : 'Error al agregar el producto'),
                  backgroundColor: ok ? _success : Colors.red,
                ));
              },
              child: const Text('Agregar a mi catálogo', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Catálogo maestro: navegar por rubros/marcas/productos
    if (!_vistaMisProductos) {
      return _buildCatalogoMaestroWrapper();
    }

    // Mi catálogo
    return Column(children: [
      Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
        child: Column(children: [
          Row(children: [
            Expanded(child: _selectorVista()),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => const CargaMasivaScreen()));
                _cargarMisProductos();
              },
              icon: const Icon(Icons.upload_file, size: 14, color: _amber),
              label: const Text('CSV', style: TextStyle(fontSize: 11, color: _amber, fontWeight: FontWeight.w700)),
              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            ),
          ]),
          const SizedBox(height: 10),
          // Buscador de Mi catálogo
          TextField(
            controller: _busMiCatCtrl,
            onChanged: (v) => setState(() { _busquedaMiCatalogo = v; _marcaFiltroMisProductos = null; }),
            decoration: InputDecoration(
              hintText: 'Buscar marca, producto o categoría...',
              prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF888888)),
              filled: true, fillColor: const Color(0xFFF5F5F5),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              suffixIcon: _busquedaMiCatalogo.isNotEmpty
                ? IconButton(icon: const Icon(Icons.close, size: 16), onPressed: () {
                    _busMiCatCtrl.clear();
                    setState(() => _busquedaMiCatalogo = '');
                  })
                : null,
            ),
          ),
          if (_marcaFiltroMisProductos != null) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => setState(() => _marcaFiltroMisProductos = null),
              child: Row(children: [
                const Icon(Icons.arrow_back_ios_rounded, size: 13, color: Color(0xFF1E3A5F)),
                const Text('Mis marcas', style: TextStyle(fontSize: 12, color: Color(0xFF1E3A5F), fontWeight: FontWeight.w600)),
                const Icon(Icons.chevron_right, size: 14, color: Colors.grey),
                Text(_marcaFiltroMisProductos!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A))),
              ]),
            ),
          ],
        ]),
      ),
      Expanded(
        child: _cargando
          ? const Center(child: CircularProgressIndicator(color: _amber))
          : _misProductos.isEmpty
            ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey),
                const SizedBox(height: 12),
                const Text('Todavía no agregaste productos', style: TextStyle(color: Colors.grey, fontSize: 14)),
                const SizedBox(height: 8),
                const Text('Andá a Catálogo maestro y agregá productos\nde las marcas que trabajás', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A5F)),
                  onPressed: () => _cambiarVista(false),
                  child: const Text('Ir al catálogo maestro', style: TextStyle(color: Colors.white)),
                ),
              ]))
            : _busquedaMiCatalogo.isNotEmpty
              ? _buildResultadosBusqueda()
              : _marcaFiltroMisProductos == null
                ? _buildGridMarcasMiCatalogo()
                : _buildProductosPorSubcategoria(),
      ),
    ]);
  }

  // Wrapper catálogo maestro: selector de vista arriba + navegación por rubros abajo
  Widget _buildCatalogoMaestroWrapper() {
    return Column(children: [
      Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
        child: _selectorVista(),
      ),
      Expanded(child: CatalogoNavegacionScreen()),
    ]);
  }

  // Grilla de marcas dentro de "Mi catálogo"
  Widget _buildGridMarcasMiCatalogo() {
    // Agrupar por rubro → marca
    final Map<String, Map<String, List<dynamic>>> porRubroMarca = {};
    for (final p in _misProductos) {
      final rubro = (p['grupo_nombre'] as String? ?? 'Otros').trim();
      final marca = (p['marca'] as String? ?? 'Sin marca').trim();
      porRubroMarca.putIfAbsent(rubro, () => {});
      porRubroMarca[rubro]!.putIfAbsent(marca, () => []).add(p);
    }
    final rubros = porRubroMarca.keys.toList()..sort();
    final totalMarcas = porRubroMarca.values.fold(0, (s, m) => s + m.length);

    final items = <Widget>[];
    items.add(Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text('$totalMarcas marca${totalMarcas == 1 ? '' : 's'} en tu catálogo',
        style: const TextStyle(fontSize: 12, color: Color(0xFF888888), fontWeight: FontWeight.w600)),
    ));

    for (final rubro in rubros) {
      final marcasDelRubro = porRubroMarca[rubro]!;
      // Título del rubro
      items.add(Padding(
        padding: const EdgeInsets.fromLTRB(2, 8, 2, 8),
        child: Text(rubro,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900,
            color: Color(0xFF1E3A5F), letterSpacing: 0.2)),
      ));
      // Tarjetas de marcas
      for (final marca in marcasDelRubro.keys.toList()..sort()) {
        final prods = marcasDelRubro[marca]!;
        final activos = prods.where((p) => p['activo'] == true).length;
        items.add(GestureDetector(
          onTap: () => setState(() => _marcaFiltroMisProductos = marca),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4)],
            ),
            child: Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: const Color(0xFF1E3A5F).withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
                child: const Center(child: Text('🏷️', style: TextStyle(fontSize: 22))),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(marca, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A))),
                const SizedBox(height: 2),
                Text('$activos activo${activos == 1 ? '' : 's'} · ${prods.length} producto${prods.length == 1 ? '' : 's'}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF888888))),
              ])),
              const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF888888)),
            ]),
          ),
        ));
      }
    }

    return ListView(padding: const EdgeInsets.all(12), children: items);
  }

  // Resultados de búsqueda en Mi catálogo
  Widget _buildResultadosBusqueda() {
    final q = _busquedaMiCatalogo.toLowerCase().trim();
    final resultados = _misProductos.where((p) {
      final nombre = (p['nombre'] as String? ?? '').toLowerCase();
      final marca  = (p['marca']  as String? ?? '').toLowerCase();
      final sub    = (p['subcategoria'] as String? ?? '').toLowerCase();
      final grupo  = (p['grupo_nombre'] as String? ?? '').toLowerCase();
      return nombre.contains(q) || marca.contains(q) || sub.contains(q) || grupo.contains(q);
    }).toList();

    if (resultados.isEmpty) return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.search_off, size: 40, color: Colors.grey),
        const SizedBox(height: 10),
        Text('Sin resultados para "$_busquedaMiCatalogo"',
          style: const TextStyle(color: Colors.grey, fontSize: 13)),
      ]),
    );

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text('${resultados.length} resultado${resultados.length == 1 ? '' : 's'}',
            style: const TextStyle(fontSize: 12, color: Color(0xFF888888), fontWeight: FontWeight.w600)),
        ),
        ...resultados.map((p) => _cardProductoMiCatalogo(p)),
      ],
    );
  }

  Widget _cardProductoMiCatalogo(Map p) {
    final activo = p['activo'] == true;
    return GestureDetector(
      onTap: () => _abrirDetalleProducto(Map.from(p)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: p['imagen_principal_url'] != null
              ? Image.network(p['imagen_principal_url'], width: 56, height: 56, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholderImg())
              : _placeholderImg(),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p['nombre'] ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(p['marca'] ?? '', style: const TextStyle(fontSize: 10, color: Color(0xFF888888))),
            if (p['subcategoria'] != null)
              Text(p['subcategoria'], style: const TextStyle(fontSize: 10, color: Color(0xFF888888))),
            const SizedBox(height: 4),
            Row(children: [
              Text('\$${p['precio'] ?? '-'}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF1E3A5F))),
              const SizedBox(width: 8),
              Text('Stock: ${p['stock'] ?? 0}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF888888))),
            ]),
          ])),
          const SizedBox(width: 8),
          Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: activo ? const Color(0xFF2E7D32).withOpacity(0.1) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(activo ? 'Activo' : 'Inactivo',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                  color: activo ? const Color(0xFF2E7D32) : Colors.grey)),
            ),
            const SizedBox(height: 6),
            const Row(children: [
              Icon(Icons.edit_outlined, size: 13, color: Color(0xFF888888)),
              SizedBox(width: 3),
              Text('Editar', style: TextStyle(fontSize: 11, color: Color(0xFF888888))),
            ]),
          ]),
        ]),
      ),
    );
  }

  void _abrirDetalleProducto(Map prod) {
    final precioCtrl  = TextEditingController(text: '${prod['precio'] ?? ''}');
    final stockCtrl   = TextEditingController(text: '${prod['stock'] ?? ''}');
    final ofertaCtrl  = TextEditingController(text: '${prod['precio_oferta'] ?? ''}');
    bool activo        = prod['activo'] == true;
    bool ofertaActiva  = prod['oferta_activa'] == true;
    DateTime? ofertaHasta = prod['oferta_hasta'] != null
      ? DateTime.tryParse(prod['oferta_hasta'].toString()) : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => SingleChildScrollView(
          padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Encabezado
            Row(children: [
              if (prod['imagen_principal_url'] != null)
                ClipRRect(borderRadius: BorderRadius.circular(8),
                  child: Image.network(prod['imagen_principal_url'], width: 52, height: 52, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholderImg())),
              if (prod['imagen_principal_url'] != null) const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(prod['nombre'] ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A))),
                if (prod['marca'] != null) Text(prod['marca'], style: const TextStyle(fontSize: 12, color: Color(0xFF888888))),
                if (prod['subcategoria'] != null) Text(prod['subcategoria'], style: const TextStyle(fontSize: 11, color: Color(0xFF888888))),
              ])),
            ]),
            const Divider(height: 24),

            // Activo toggle
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Visible en tu tienda', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              Switch(value: activo, activeColor: _amber, onChanged: (v) async {
                setModal(() => activo = v);
                await ApiService.toggleProductoActivo(prod['producto_id'] as int, v);
                _cargarMisProductos();
              }),
            ]),
            const SizedBox(height: 12),

            // Precio normal
            const Text('Precio de venta (\$)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            TextField(controller: precioCtrl, keyboardType: TextInputType.number,
              decoration: InputDecoration(prefixText: '\$ ', filled: true, fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 12),

            // Stock
            const Text('Stock disponible', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            TextField(controller: stockCtrl, keyboardType: TextInputType.number,
              decoration: InputDecoration(filled: true, fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 20),

            // ── Sección OFERTA ──────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: ofertaActiva ? const Color(0xFFFFF8E1) : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: ofertaActiva ? _amber : Colors.grey.shade200, width: ofertaActiva ? 1.5 : 1),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Row(children: [
                    Icon(Icons.local_offer_rounded, size: 16, color: ofertaActiva ? _amber : Colors.grey),
                    const SizedBox(width: 6),
                    Text('Publicar oferta', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800,
                      color: ofertaActiva ? _amber : const Color(0xFF1A1A1A))),
                  ]),
                  Switch(value: ofertaActiva, activeColor: _amber,
                    onChanged: (v) => setModal(() => ofertaActiva = v)),
                ]),
                if (ofertaActiva) ...[
                  const SizedBox(height: 12),
                  const Text('Precio de oferta (\$)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  TextField(controller: ofertaCtrl, keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      prefixText: '\$ ',
                      hintText: 'Menor al precio normal',
                      filled: true, fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: _amber, width: 1.5)),
                    )),
                  const SizedBox(height: 12),
                  const Text('Válida hasta', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: ofertaHasta ?? DateTime.now().add(const Duration(days: 7)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        builder: (c, w) => Theme(data: ThemeData.light().copyWith(
                          colorScheme: const ColorScheme.light(primary: _amber)), child: w!),
                      );
                      if (picked != null) setModal(() => ofertaHasta = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(color: Colors.white,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(10)),
                      child: Row(children: [
                        const Icon(Icons.calendar_today_outlined, size: 16, color: _amber),
                        const SizedBox(width: 8),
                        Text(
                          ofertaHasta != null
                            ? '${ofertaHasta!.day}/${ofertaHasta!.month}/${ofertaHasta!.year}'
                            : 'Seleccioná una fecha',
                          style: TextStyle(fontSize: 13,
                            color: ofertaHasta != null ? const Color(0xFF1A1A1A) : Colors.grey),
                        ),
                      ]),
                    ),
                  ),
                ],
              ]),
            ),
            const SizedBox(height: 20),

            // Botón guardar
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: _amber, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: () async {
                  final precio = double.tryParse(precioCtrl.text);
                  final stock  = int.tryParse(stockCtrl.text);
                  final precioOferta = ofertaActiva ? double.tryParse(ofertaCtrl.text) : null;
                  if (precio == null || precio <= 0) return;
                  if (ofertaActiva && (precioOferta == null || precioOferta >= precio)) {
                    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                      content: Text('El precio de oferta debe ser menor al precio normal'),
                      backgroundColor: Colors.red));
                    return;
                  }
                  Navigator.pop(ctx);
                  await ApiService.patch('/comercio/productos/${prod['producto_id']}', {
                    'precio': precio,
                    if (stock != null) 'stock': stock,
                    'oferta_activa': ofertaActiva,
                    if (precioOferta != null) 'precio_oferta': precioOferta,
                    if (ofertaHasta != null) 'oferta_hasta': '${ofertaHasta!.year}-${ofertaHasta!.month.toString().padLeft(2,'0')}-${ofertaHasta!.day.toString().padLeft(2,'0')}',
                  });
                  _cargarMisProductos();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Producto actualizado ✓'), backgroundColor: _success));
                },
                child: const Text('Guardar cambios', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _placeholderImg() => Container(
    width: 52, height: 52, color: Colors.grey.shade100,
    child: const Icon(Icons.inventory_2_outlined, color: Colors.grey, size: 22),
  );

  // Productos agrupados por subcategoría para una marca
  Widget _buildProductosPorSubcategoria() {
    final prodsMarca = _misProductos
      .where((p) => (p['marca'] as String? ?? 'Sin marca').trim() == _marcaFiltroMisProductos)
      .toList();

    // Agrupar por subcategoría (campo 'subcategoria' del producto)
    final Map<String, List<dynamic>> porSub = {};
    for (final p in prodsMarca) {
      final sub = (p['subcategoria'] as String? ?? 'Sin subcategoría').trim();
      porSub.putIfAbsent(sub, () => []).add(p);
    }
    final subs = porSub.keys.toList()..sort();

    // Construir lista flat con headers
    final List<Widget> items = [];
    for (final sub in subs) {
      // Título de sección
      items.add(Padding(
        padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
        child: Text(sub,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF1E3A5F), letterSpacing: 0.2)),
      ));
      for (final p in porSub[sub]!) {
        items.add(_cardMiProducto(p));
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      children: items,
    );
  }

  Widget _selectorVista() {
    return Container(
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.all(3),
      child: Row(children: [
        Expanded(child: _botonVista('Catálogo maestro', !_vistaMisProductos, () => _cambiarVista(false))),
        Expanded(child: _botonVista('Mi catálogo', _vistaMisProductos, () => _cambiarVista(true))),
      ]),
    );
  }

  Widget _botonVista(String label, bool sel, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: sel ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: sel ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4)] : null,
        ),
        alignment: Alignment.center,
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: sel ? _amber : Colors.grey.shade600)),
      ),
    );
  }

  Widget _chipCategoria(int? id, String label) {
    final sel = _categoriaSeleccionada == id;
    return GestureDetector(
      onTap: () { setState(() => _categoriaSeleccionada = id); _buscar(); },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: sel ? _amber : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: sel ? Colors.white : Colors.grey.shade700)),
      ),
    );
  }

  Widget _cardProducto(Map prod) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade100)),
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: prod['imagen_principal_url'] != null
            ? CachedNetworkImage(imageUrl: prod['imagen_principal_url'], width: 60, height: 60, fit: BoxFit.cover, errorWidget: (_, __, ___) => _placeholder())
            : _placeholder(),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(prod['nombre'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _textDark), maxLines: 2, overflow: TextOverflow.ellipsis),
          if (prod['marca'] != null) Text(prod['marca'], style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 2),
          Text(prod['categoria_nombre'] ?? '', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
        ])),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () => _mostrarActivar(Map.from(prod)),
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

  Widget _placeholder() => Container(width: 60, height: 60, color: Colors.grey.shade100, child: const Icon(Icons.inventory_2_outlined, color: Colors.grey));

  void _editarPrecio(Map prod) {
    final precioCtrl = TextEditingController(text: '${prod['precio'] ?? ''}');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(prod['nombre'] ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _textDark)),
          const SizedBox(height: 16),
          const Text('Precio de venta (\$)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextField(
            controller: precioCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              prefixText: '\$ ',
              filled: true, fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity, height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _amber, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () async {
                final precio = double.tryParse(precioCtrl.text);
                if (precio == null || precio <= 0) return;
                Navigator.pop(context);
                final ok = await ApiService.actualizarPrecioProducto(prod['producto_id'] as int, precio);
                if (ok) _cargarMisProductos();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(ok ? 'Precio actualizado ✓' : 'Error al actualizar el precio'),
                  backgroundColor: ok ? _success : Colors.red,
                ));
              },
              child: const Text('Guardar', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ),
    );
  }

  Future<void> _toggleActivo(Map prod, bool nuevoValor) async {
    final ok = await ApiService.toggleProductoActivo(prod['producto_id'] as int, nuevoValor);
    if (ok) _cargarMisProductos();
  }

  Widget _cardMiProducto(Map prod) {
    final activo = prod['activo'] == true;
    return GestureDetector(
      onTap: () => _abrirDetalleProducto(Map.from(prod)),
      child: _cardMiProductoInner(prod, activo));
  }

  Widget _cardMiProductoInner(Map prod, bool activo) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade100)),
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: prod['imagen_principal_url'] != null
            ? CachedNetworkImage(imageUrl: prod['imagen_principal_url'], width: 60, height: 60, fit: BoxFit.cover, errorWidget: (_, __, ___) => _placeholder())
            : _placeholder(),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(prod['nombre'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _textDark), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text('\$${prod['precio'] ?? 0}  ·  Stock: ${prod['stock'] ?? 0}', style: const TextStyle(fontSize: 12, color: _success, fontWeight: FontWeight.w700)),
        ])),
        const SizedBox(width: 8),
        Column(mainAxisSize: MainAxisSize.min, children: [
          Switch(value: activo, activeColor: _amber, onChanged: (v) => _toggleActivo(prod, v)),
          TextButton(
            onPressed: () => _abrirDetalleProducto(Map.from(prod)),
            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            child: const Text('Editar', style: TextStyle(fontSize: 11)),
          ),
        ]),
      ]),
    );
  }

  Widget _buildSeleccionMarca() {
    // Agrupar mis marcas por rubro
    final Map<String, List<dynamic>> porRubro = {};
    for (final m in _misMarcas) {
      final r = m['rubro'] as String? ?? 'Otros';
      porRubro.putIfAbsent(r, () => []).add(m);
    }

    return Column(children: [
      Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('¿Qué marca querés cargar?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A))),
          const SizedBox(height: 2),
          const Text('Elegí una marca para ver sus productos en el catálogo', style: TextStyle(fontSize: 12, color: Color(0xFF888888))),
        ]),
      ),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            // Opción "Ver todo"
            GestureDetector(
              onTap: () => _elegirMarca(null, null),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A5F),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(children: [
                  Text('📦', style: TextStyle(fontSize: 22)),
                  SizedBox(width: 12),
                  Expanded(child: Text('Ver catálogo completo', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white))),
                  Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.white54),
                ]),
              ),
            ),
            ...porRubro.entries.map((entry) {
              final rubro = entry.key;
              final marcas = entry.value;
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(rubro, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF888888), letterSpacing: 0.5)),
                ),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 2.2,
                  children: marcas.map((m) {
                    return GestureDetector(
                      onTap: () => _elegirMarca(m['id'] as int, m['nombre'] as String),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4)],
                        ),
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          m['nombre'] as String,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 4),
              ]);
            }),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => MarcasScreen(modoEdicion: true, onGuardado: _cargarMisMarcas),
              )),
              icon: const Icon(Icons.edit_rounded, size: 16, color: Color(0xFF1E3A5F)),
              label: const Text('Editar mis marcas', style: TextStyle(fontSize: 13, color: Color(0xFF1E3A5F), fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    ]);
  }
}
