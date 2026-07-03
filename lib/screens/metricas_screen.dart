import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_colors.dart';
import '../services/api_service.dart';

class MetricasScreen extends StatefulWidget {
  const MetricasScreen({super.key});

  @override
  State<MetricasScreen> createState() => _MetricasScreenState();
}

class _MetricasScreenState extends State<MetricasScreen> {
  String _periodo = '30d';
  bool _cargando = true;
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    final res = await ApiService.get('/comercio/metricas?periodo=$_periodo');
    if (!mounted) return;
    setState(() {
      _cargando = false;
      if (res['status'] == 200) _data = res['data'];
    });
  }

  String _formatearMoneda(double v) {
    if (v >= 1000000) return '\$${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '\$${(v / 1000).toStringAsFixed(1)}k';
    return '\$${v.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final ventas = List<dynamic>.from(_data?['ventas'] ?? []);
    final productosTop = List<dynamic>.from(_data?['productos_top'] ?? []);
    final totalIngresos = double.tryParse(_data?['total_ingresos']?.toString() ?? '0') ?? 0;
    final totalPedidos = int.tryParse(_data?['total_pedidos']?.toString() ?? '0') ?? 0;
    final ticketPromedio = totalPedidos > 0 ? totalIngresos / totalPedidos : 0.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Metricas', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _cargando
        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
        : RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _cargar,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Chips de período
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final p in [('7d', '7 días'), ('30d', '30 días'), ('90d', '90 días')])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(p.$2, style: GoogleFonts.poppins(fontSize: 13)),
                            selected: _periodo == p.$1,
                            onSelected: (_) {
                              setState(() => _periodo = p.$1);
                              _cargar();
                            },
                            selectedColor: AppColors.primary.withValues(alpha: 0.15),
                            checkmarkColor: AppColors.primary,
                            labelStyle: TextStyle(
                              color: _periodo == p.$1 ? AppColors.primary : AppColors.textSecondary,
                              fontWeight: _periodo == p.$1 ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                if (_data == null || (ventas.isEmpty && productosTop.isEmpty))
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      child: Column(
                        children: [
                          const Icon(Icons.bar_chart_outlined, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text('Sin datos para este período', style: GoogleFonts.poppins(color: Colors.grey)),
                        ],
                      ),
                    ),
                  )
                else ...[
                  // Tarjetas resumen
                  Row(
                    children: [
                      Expanded(child: _tarjeta('Total ingresos', _formatearMoneda(totalIngresos), Icons.attach_money, AppColors.success)),
                      const SizedBox(width: 10),
                      Expanded(child: _tarjeta('Total pedidos', '$totalPedidos', Icons.receipt_long_outlined, AppColors.primary)),
                      const SizedBox(width: 10),
                      Expanded(child: _tarjeta('Ticket promedio', _formatearMoneda(ticketPromedio), Icons.trending_up, AppColors.warning)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Gráfico de barras manual (últimos 7 registros de ventas)
                  if (ventas.isNotEmpty) ...[
                    Text('Ingresos por día', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.secondary)),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: _buildBarras(ventas),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Top 5 productos
                  if (productosTop.isNotEmpty) ...[
                    Text('Top 5 productos más vendidos', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.secondary)),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              child: Row(
                                children: [
                                  Expanded(child: Text('Producto', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
                                  SizedBox(width: 60, child: Text('Cant.', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary), textAlign: TextAlign.center)),
                                  SizedBox(width: 80, child: Text('Total', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary), textAlign: TextAlign.right)),
                                ],
                              ),
                            ),
                            const Divider(height: 1),
                            ...productosTop.asMap().entries.map((e) {
                              final p = e.value as Map;
                              final vendidos = int.tryParse(p['vendidos']?.toString() ?? '0') ?? 0;
                              final totalVendido = double.tryParse(p['total_vendido']?.toString() ?? '0') ?? 0;
                              return Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 12,
                                          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                          child: Text('${e.key + 1}', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(child: Text(p['nombre'] ?? '', style: GoogleFonts.poppins(fontSize: 13))),
                                        SizedBox(width: 60, child: Text('$vendidos', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600), textAlign: TextAlign.center)),
                                        SizedBox(width: 80, child: Text(_formatearMoneda(totalVendido), style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.success), textAlign: TextAlign.right)),
                                      ],
                                    ),
                                  ),
                                  if (e.key < productosTop.length - 1) const Divider(height: 1),
                                ],
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
    );
  }

  Widget _tarjeta(String titulo, String valor, IconData icono, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icono, size: 22, color: color),
            const SizedBox(height: 8),
            Text(valor, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(titulo, style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildBarras(List<dynamic> ventas) {
    final ultimos = ventas.length > 7 ? ventas.sublist(ventas.length - 7) : ventas;
    final maxIngresos = ultimos.fold<double>(0, (m, v) {
      final ing = double.tryParse(v['ingresos']?.toString() ?? '0') ?? 0;
      return ing > m ? ing : m;
    });
    if (maxIngresos == 0) {
      return Center(child: Text('Sin datos', style: GoogleFonts.poppins(color: Colors.grey)));
    }

    return SizedBox(
      height: 140,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: ultimos.map((v) {
          final ingresos = double.tryParse(v['ingresos']?.toString() ?? '0') ?? 0;
          final porcentaje = ingresos / maxIngresos;
          final dia = v['dia']?.toString() ?? '';
          final diaLabel = dia.length >= 10 ? dia.substring(8) : dia;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (ingresos > 0)
                    Text(
                      _formatearMoneda(ingresos),
                      style: GoogleFonts.poppins(fontSize: 8, color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  const SizedBox(height: 2),
                  Container(
                    height: (porcentaje * 90).clamp(4.0, 90.0),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    diaLabel,
                    style: GoogleFonts.poppins(fontSize: 9, color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
