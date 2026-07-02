import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../core/app_colors.dart';

const _amber = Color(0xFFE07B00);
const _textDark = Color(0xFF1A1A1A);
const _textGrey = Color(0xFF888888);
const _bgPage = Color(0xFFF7F7F8);

class CatalogoPorRubrosScreen extends StatefulWidget {
  final int? comercioId;
  const CatalogoPorRubrosScreen({super.key, this.comercioId});

  @override
  State<CatalogoPorRubrosScreen> createState() => _CatalogoPorRubrosScreenState();
}

class _CatalogoPorRubrosScreenState extends State<CatalogoPorRubrosScreen> {
  List<dynamic> _rubros = [];
  Map<String, dynamic> _completitud = {};
  bool _cargando = true;
  Set<int> _expandidos = {};

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    final res = await ApiService.get('/rubros/comercio/catalogo');
    if (!mounted) return;
    if (res['status'] == 200) {
      final data = res['data'] as Map<String, dynamic>;
      final rubros = data['rubros'] as List;
      setState(() {
        _rubros = rubros;
        _completitud = Map<String, dynamic>.from(data['completitud'] ?? {});
        _expandidos = rubros
            .where((r) => r['tipo'] == 'principal')
            .map((r) => r['id'] as int)
            .toSet();
        _cargando = false;
      });
    } else {
      setState(() => _cargando = false);
    }
  }

  Future<void> _mostrarActivar(Map producto) async {
    final precioCtrl = TextEditingController();
    final stockCtrl = TextEditingController(text: '10');
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(producto['nombre'] ?? '', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: _textDark)),
          if (producto['marca'] != null)
            Text(producto['marca'].toString(), style: GoogleFonts.poppins(fontSize: 12, color: _textGrey)),
          const SizedBox(height: 20),
          Text('Tu precio de venta (\$)', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextField(
            controller: precioCtrl,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Ej: 5500',
              prefixText: '\$ ',
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 12),
          Text('Stock disponible', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextField(
            controller: stockCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _amber,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                final precio = double.tryParse(precioCtrl.text);
                if (precio == null || precio <= 0) return;
                Navigator.pop(ctx);
                final ok = await ApiService.activarProducto(
                  widget.comercioId ?? 0,
                  producto['catalogo_id'] as int,
                  precio,
                  int.tryParse(stockCtrl.text) ?? 0,
                );
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(ok ? '${producto['nombre']} agregado ✓' : 'Error al agregar'),
                  backgroundColor: ok ? AppColors.success : Colors.red,
                ));
                if (ok) _cargar();
              },
              child: Text('Agregar al catálogo', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator(color: _amber));
    }

    if (_rubros.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.category_outlined, size: 56, color: AppColors.primary),
            const SizedBox(height: 16),
            Text('Configurá tus rubros primero',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text('Andá a Perfil → Mis rubros para elegir en qué se especializa tu negocio.',
              style: GoogleFonts.poppins(fontSize: 13, color: _textGrey),
              textAlign: TextAlign.center),
          ]),
        ),
      );
    }

    final principales = _rubros.where((r) => r['tipo'] == 'principal').toList();
    final secundarios = _rubros.where((r) => r['tipo'] == 'secundario').toList();

    return RefreshIndicator(
      onRefresh: _cargar,
      color: _amber,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          if (principales.isNotEmpty) _buildCompletitudBanner(principales),
          ...principales.map((r) => _buildSeccionRubro(r, esPrincipal: true)),
          if (secundarios.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text('Rubros adicionales',
                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: _textGrey)),
            ),
            ...secundarios.map((r) => _buildSeccionRubro(r, esPrincipal: false)),
          ],
        ],
      ),
    );
  }

  Widget _buildCompletitudBanner(List principales) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _amber.withValues(alpha: 0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Completitud de tu catálogo',
          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: _textDark)),
        const SizedBox(height: 10),
        ...principales.map((r) {
          final comp = _completitud[r['id'].toString()];
          if (comp == null) return const SizedBox();
          final pct = (comp['porcentaje'] as int?) ?? 0;
          final activados = (comp['activados'] as int?) ?? 0;
          final total = (comp['total'] as int?) ?? 0;
          final colorHex = (r['color_hex'] as String).replaceAll('#', '');
          final color = Color(int.parse('0xFF$colorHex'));
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(r['icono_emoji'] as String, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Expanded(child: Text(r['nombre'] as String,
                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600))),
                Text('$activados / $total', style: GoogleFonts.poppins(fontSize: 11, color: _textGrey)),
                const SizedBox(width: 6),
                Text('$pct%', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
              ]),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct / 100,
                  backgroundColor: Colors.grey.shade100,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 6,
                ),
              ),
            ]),
          );
        }),
      ]),
    );
  }

  Widget _buildSeccionRubro(dynamic rubro, {required bool esPrincipal}) {
    final id = rubro['id'] as int;
    final colorHex = (rubro['color_hex'] as String).replaceAll('#', '');
    final color = Color(int.parse('0xFF$colorHex'));
    final expandido = _expandidos.contains(id);
    final productos = (rubro['productos'] as List?) ?? [];
    final activados = productos.where((p) => p['activo'] == true).length;
    final total = productos.length;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: esPrincipal ? color.withValues(alpha: 0.4) : Colors.grey.shade200,
          width: esPrincipal ? 1.5 : 1,
        ),
      ),
      child: Column(children: [
        InkWell(
          onTap: () => setState(() {
            if (expandido) _expandidos.remove(id);
            else _expandidos.add(id);
          }),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: esPrincipal ? color.withValues(alpha: 0.07) : Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
            ),
            child: Row(children: [
              Text(rubro['icono_emoji'] as String, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(rubro['nombre'] as String,
                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: _textDark))),
                  if (esPrincipal)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
                      child: Text('PRINCIPAL',
                        style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white)),
                    ),
                ]),
                const SizedBox(height: 2),
                Text('$activados activados de $total disponibles',
                  style: GoogleFonts.poppins(fontSize: 11, color: _textGrey)),
              ])),
              const SizedBox(width: 8),
              Icon(expandido ? Icons.expand_less : Icons.expand_more, color: _textGrey),
            ]),
          ),
        ),
        if (expandido) ...[
          if (productos.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('No hay productos del catálogo en este rubro.',
                style: GoogleFonts.poppins(fontSize: 12, color: _textGrey)),
            )
          else
            ...productos.take(20).map((p) => _buildProductoTile(Map.from(p as Map), color)),
          if (productos.length > 20)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Text('... y ${productos.length - 20} productos más',
                style: GoogleFonts.poppins(fontSize: 11, color: _textGrey)),
            ),
        ],
      ]),
    );
  }

  Widget _buildProductoTile(Map producto, Color rubroColor) {
    final activo = producto['activo'] == true;
    final precio = producto['precio'];
    final imgUrl = producto['foto_url'] as String?;

    return Container(
      decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey.shade100))),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: _bgPage, borderRadius: BorderRadius.circular(8)),
          clipBehavior: Clip.antiAlias,
          child: imgUrl != null
            ? Image.network(imgUrl, fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(Icons.construction, color: _amber, size: 20))
            : const Icon(Icons.construction, color: _amber, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(producto['nombre']?.toString() ?? '',
            style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: _textDark),
            maxLines: 2, overflow: TextOverflow.ellipsis),
          if (producto['marca'] != null)
            Text(producto['marca'].toString(),
              style: GoogleFonts.poppins(fontSize: 10, color: _textGrey)),
          if (activo && precio != null)
            Text('\$$precio',
              style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: rubroColor)),
        ])),
        const SizedBox(width: 8),
        if (activo)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: AppColors.successBg, borderRadius: BorderRadius.circular(8)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.check_circle_rounded, size: 12, color: AppColors.success),
              const SizedBox(width: 4),
              Text('Activo',
                style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.success)),
            ]),
          )
        else
          GestureDetector(
            onTap: () => _mostrarActivar(producto),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: rubroColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('+ Agregar',
                style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700, color: rubroColor)),
            ),
          ),
      ]),
    );
  }
}
