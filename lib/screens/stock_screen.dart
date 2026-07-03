import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_colors.dart';
import '../services/api_service.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  List<dynamic> _productos = [];
  bool _cargando = true;
  String _filtro = 'todos';

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    final query = _filtro == 'todos' ? '' : '?filtro=$_filtro';
    final res = await ApiService.get('/stock$query');
    if (!mounted) return;
    setState(() {
      _cargando = false;
      if (res['status'] == 200) {
        final data = res['data'];
        _productos = List<dynamic>.from(data['productos'] ?? []);
      }
    });
  }

  String _estadoStock(Map p) {
    final actual = p['stock_actual'];
    final minimo = p['stock_minimo_alerta'];
    if (actual == null) return 'sin_datos';
    if (actual == 0) return 'sin_stock';
    if (minimo != null && actual <= minimo) return 'bajo';
    return 'ok';
  }

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'ok': return AppColors.success;
      case 'bajo': return AppColors.warning;
      case 'sin_stock': return AppColors.error;
      default: return Colors.grey;
    }
  }

  String _labelEstado(String estado) {
    switch (estado) {
      case 'ok': return 'OK';
      case 'bajo': return 'Stock bajo';
      case 'sin_stock': return 'Sin stock';
      default: return 'Sin datos';
    }
  }

  Future<void> _editarStock(Map producto) async {
    final stockCtrl = TextEditingController(text: producto['stock_actual']?.toString() ?? '');
    final minimoCtrl = TextEditingController(text: producto['stock_minimo_alerta']?.toString() ?? '');
    final motivoCtrl = TextEditingController();
    bool ocultarSinStock = producto['ocultar_sin_stock'] == true;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                producto['nombre'] ?? 'Producto',
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.secondary),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: stockCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Stock actual',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.inventory_2_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: minimoCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Stock mínimo de alerta',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.warning_amber_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: motivoCtrl,
                decoration: const InputDecoration(
                  labelText: 'Motivo del ajuste (opcional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.edit_note),
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: ocultarSinStock,
                activeColor: AppColors.primary,
                title: Text('Ocultar cuando no haya stock', style: GoogleFonts.poppins(fontSize: 13)),
                onChanged: (v) => setModalState(() => ocultarSinStock = v),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final body = <String, dynamic>{
                      'ocultar_sin_stock': ocultarSinStock,
                    };
                    if (stockCtrl.text.trim().isNotEmpty) {
                      body['stock_actual'] = int.tryParse(stockCtrl.text.trim());
                    }
                    if (minimoCtrl.text.trim().isNotEmpty) {
                      body['stock_minimo_alerta'] = int.tryParse(minimoCtrl.text.trim());
                    }
                    if (motivoCtrl.text.trim().isNotEmpty) {
                      body['motivo'] = motivoCtrl.text.trim();
                    }
                    final res = await ApiService.patch('/stock/${producto['id']}', body);
                    if (!mounted) return;
                    if (res['status'] == 200) {
                      _cargar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Stock actualizado'), backgroundColor: Colors.green),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Error al actualizar'), backgroundColor: Colors.red),
                      );
                    }
                  },
                  child: Text('Guardar', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _reposicionMasiva() async {
    final bajos = _productos.where((p) {
      final e = _estadoStock(p as Map);
      return e == 'bajo' || e == 'sin_stock';
    }).toList();

    if (bajos.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay productos con stock bajo o sin stock')),
      );
      return;
    }

    final controllers = <int, TextEditingController>{};
    for (final p in bajos) {
      controllers[p['id'] as int] = TextEditingController();
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        builder: (_, sc) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Reposición masiva',
                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.secondary),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Ingresá el nuevo stock para cada producto',
                  style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  controller: sc,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: bajos.length,
                  itemBuilder: (_, i) {
                    final p = bajos[i] as Map;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(p['nombre'] ?? '', style: GoogleFonts.poppins(fontSize: 13)),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 90,
                            child: TextField(
                              controller: controllers[p['id'] as int],
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Cantidad',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                    ),
                    onPressed: () async {
                      final items = <Map<String, dynamic>>[];
                      for (final p in bajos) {
                        final v = controllers[p['id'] as int]?.text.trim();
                        if (v != null && v.isNotEmpty) {
                          items.add({'id': p['id'], 'stock_actual': int.tryParse(v) ?? 0});
                        }
                      }
                      if (items.isEmpty) { Navigator.pop(ctx); return; }
                      Navigator.pop(ctx);
                      final res = await ApiService.post('/stock/reposicion-masiva', {'items': items});
                      if (!mounted) return;
                      if (res['status'] == 200) {
                        _cargar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Reposición aplicada'), backgroundColor: Colors.green),
                        );
                      }
                    },
                    child: Text('Guardar reposición', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Mi Stock', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _reposicionMasiva,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_box_outlined),
        label: Text('Reposición masiva', style: GoogleFonts.poppins()),
      ),
      body: Column(
        children: [
          // Chips de filtro
          Padding(
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final f in [
                    ('todos', 'Todos'),
                    ('bajo', 'Stock bajo'),
                    ('sin_stock', 'Sin stock'),
                    ('ok', 'OK'),
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(f.$2, style: GoogleFonts.poppins(fontSize: 13)),
                        selected: _filtro == f.$1,
                        onSelected: (_) {
                          setState(() => _filtro = f.$1);
                          _cargar();
                        },
                        selectedColor: AppColors.primary.withValues(alpha: 0.15),
                        checkmarkColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: _filtro == f.$1 ? AppColors.primary : AppColors.textSecondary,
                          fontWeight: _filtro == f.$1 ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Lista
          Expanded(
            child: _cargando
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _productos.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text('Sin productos con stock cargado', style: GoogleFonts.poppins(color: Colors.grey)),
                        const SizedBox(height: 8),
                        Text('Tocá un producto para configurar su stock', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: _cargar,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 100),
                      itemCount: _productos.length,
                      itemBuilder: (_, i) {
                        final p = _productos[i] as Map;
                        final estado = _estadoStock(p);
                        final color = _colorEstado(estado);
                        final actual = p['stock_actual'] as int? ?? 0;
                        final minimo = p['stock_minimo_alerta'] as int?;
                        final progreso = minimo != null && minimo > 0
                          ? (actual / (minimo * 2)).clamp(0.0, 1.0)
                          : null;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => _editarStock(p),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          p['nombre'] ?? '',
                                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: color.withValues(alpha: 0.13),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          _labelEstado(estado),
                                          style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: color),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Text('Stock: ', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary)),
                                      Text('$actual${p['unidad'] != null ? ' ${p['unidad']}' : ''}',
                                        style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
                                      if (minimo != null) ...[
                                        Text(' / mínimo: $minimo', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary)),
                                      ],
                                    ],
                                  ),
                                  if (progreso != null) ...[
                                    const SizedBox(height: 8),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: LinearProgressIndicator(
                                        value: progreso,
                                        backgroundColor: Colors.grey.shade200,
                                        color: color,
                                        minHeight: 6,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
