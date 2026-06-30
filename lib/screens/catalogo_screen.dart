import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'carga_masiva_screen.dart';

const _amber = Color(0xFFE07B00);
const _textDark = Color(0xFF1A1A1A);
const _success = Color(0xFF2E7D32);

class CatalogoScreen extends StatefulWidget {
  final int? comercioId;
  const CatalogoScreen({super.key, this.comercioId});
  @override
  State<CatalogoScreen> createState() => _CatalogoScreenState();
}

class _CatalogoScreenState extends State<CatalogoScreen> {
  final _busquedaCtrl = TextEditingController();
  List<dynamic> _productos = [];
  List<dynamic> _categorias = [];
  List<dynamic> _misProductos = [];
  int? _categoriaSeleccionada;
  bool _cargando = false;
  bool _vistaMisProductos = false;

  @override
  void initState() {
    super.initState();
    _cargarCategorias();
    _buscar();
  }

  Future<void> _cargarCategorias() async {
    final cats = await ApiService.obtenerCategorias();
    setState(() => _categorias = cats);
  }

  Future<void> _buscar() async {
    setState(() => _cargando = true);
    final prods = await ApiService.buscarCatalogo(
      busqueda: _busquedaCtrl.text,
      categoriaId: _categoriaSeleccionada,
    );
    setState(() { _productos = prods; _cargando = false; });
  }

  Future<void> _cargarMisProductos() async {
    setState(() => _cargando = true);
    final prods = await ApiService.misProductos();
    setState(() { _misProductos = prods; _cargando = false; });
  }

  void _cambiarVista(bool misProductos) {
    setState(() => _vistaMisProductos = misProductos);
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
    return Column(children: [
      Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Column(children: [
          _selectorVista(),
          const SizedBox(height: 10),
          if (!_vistaMisProductos) ...[
            TextField(
              controller: _busquedaCtrl,
              onSubmitted: (_) => _buscar(),
              decoration: InputDecoration(
                hintText: 'Buscar en el catálogo...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _busquedaCtrl.text.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () { _busquedaCtrl.clear(); _buscar(); })
                  : null,
                filled: true, fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 36,
              child: ListView(scrollDirection: Axis.horizontal, children: [
                _chipCategoria(null, 'Todos'),
                ..._categorias.map((c) => _chipCategoria(c['id'], c['nombre'])),
              ]),
            ),
            const SizedBox(height: 10),
          ] else ...[
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (_) => const CargaMasivaScreen()));
                  _cargarMisProductos();
                },
                icon: const Icon(Icons.upload_file, size: 16, color: _amber),
                label: const Text('Carga masiva (CSV)', style: TextStyle(fontSize: 12, color: _amber, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 4),
          ],
        ]),
      ),
      Expanded(
        child: _cargando
          ? const Center(child: CircularProgressIndicator(color: _amber))
          : _vistaMisProductos
            ? (_misProductos.isEmpty
                ? const Center(child: Text('Todavía no agregaste productos a tu catálogo', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _misProductos.length,
                    itemBuilder: (_, i) => _cardMiProducto(_misProductos[i]),
                  ))
            : (_productos.isEmpty
                ? const Center(child: Text('No se encontraron productos', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _productos.length,
                    itemBuilder: (_, i) => _cardProducto(_productos[i]),
                  )),
      ),
    ]);
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
            ? Image.network(prod['imagen_principal_url'], width: 60, height: 60, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _placeholder())
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
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade100)),
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: prod['imagen_principal_url'] != null
            ? Image.network(prod['imagen_principal_url'], width: 60, height: 60, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _placeholder())
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
            onPressed: () => _editarPrecio(Map.from(prod)),
            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            child: const Text('Editar precio', style: TextStyle(fontSize: 11)),
          ),
        ]),
      ]),
    );
  }
}
