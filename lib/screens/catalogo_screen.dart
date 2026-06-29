import 'package:flutter/material.dart';
import '../services/api_service.dart';

const _amber = Color(0xFFE07B00);
const _textDark = Color(0xFF1A1A1A);
const _success = Color(0xFF2E7D32);

class CatalogoScreen extends StatefulWidget {
  final int? comercioId;
  const CatalogoScreen({super.key, required this.comercioId});
  @override
  State<CatalogoScreen> createState() => _CatalogoScreenState();
}

class _CatalogoScreenState extends State<CatalogoScreen> {
  final _busquedaCtrl = TextEditingController();
  List<dynamic> _productos = [];
  List<dynamic> _categorias = [];
  int? _categoriaSeleccionada;
  bool _cargando = false;

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
                if (widget.comercioId == null) return;
                Navigator.pop(context);
                final ok = await ApiService.activarProducto(
                  widget.comercioId!, producto['id'] as int, precio, stock ?? 0);
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
        ]),
      ),
      Expanded(
        child: _cargando
          ? const Center(child: CircularProgressIndicator(color: _amber))
          : _productos.isEmpty
            ? const Center(child: Text('No se encontraron productos', style: TextStyle(color: Colors.grey)))
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _productos.length,
                itemBuilder: (_, i) => _cardProducto(_productos[i]),
              ),
      ),
    ]);
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
}
