import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../core/app_colors.dart';
import 'pedidos_screen.dart';
import 'login_screen.dart';
import 'validar_retiro_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _comercio;
  Map<String, dynamic>? _estadisticas;
  List<dynamic> _pedidosPendientes = [];
  List<dynamic> _datosSemanales = [];
  bool _cargando = true;
  bool _procesandoToggle = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _cargarEstadisticas());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);
    await Future.wait([_cargarComercio(), _cargarEstadisticas()]);
    if (mounted) setState(() => _cargando = false);
  }

  Future<void> _cargarComercio() async {
    try {
      final comercio = await ApiService.miComercio();
      if (!mounted) return;
      if (comercio != null) setState(() => _comercio = comercio);
    } catch (_) {}
  }

  Future<void> _cargarEstadisticas() async {
    try {
      final results = await Future.wait([
        ApiService.estadisticasHoy(),
        ApiService.pedidosDelComercio(0, estado: 'pendiente'),
        ApiService.get('/comercio/estadisticas/semana'),
      ]);
      if (!mounted) return;
      setState(() {
        _estadisticas = results[0] as Map<String, dynamic>?;
        final pedidos = results[1] as List<dynamic>;
        _pedidosPendientes = pedidos.length > 3 ? pedidos.sublist(0, 3) : pedidos;
        _datosSemanales = (results[2] as Map<String, dynamic>)['data'] is List
            ? (results[2] as Map<String, dynamic>)['data'] as List<dynamic>
            : [];
      });
    } catch (_) {}
  }

  Future<void> _toggleAbierto() async {
    if (_comercio == null || _procesandoToggle) return;
    setState(() => _procesandoToggle = true);
    final comercioId = _comercio!['id'];
    final estadoActual = _comercio!['abierto'] == true;
    // Optimistic update
    setState(() => _comercio!['abierto'] = !estadoActual);
    final ok = await ApiService.actualizarAbierto(
      comercioId is int ? comercioId : int.tryParse(comercioId.toString()) ?? 0,
      !estadoActual,
    );
    if (!mounted) return;
    if (!ok) {
      // Revertir
      setState(() => _comercio!['abierto'] = estadoActual);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al cambiar el estado'), backgroundColor: Colors.red),
      );
    }
    setState(() => _procesandoToggle = false);
  }

  Future<void> _cerrarSesion() async {
    await ApiService.cerrarSesion();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  String _tiempoDesde(String? fechaStr) {
    if (fechaStr == null) return '';
    try {
      final fecha = DateTime.parse(fechaStr);
      final diff = DateTime.now().difference(fecha);
      if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
      if (diff.inHours < 24) return 'hace ${diff.inHours} h';
      return 'hace ${diff.inDays} días';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final abierto = _comercio?['abierto'] == true;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: RichText(
          text: TextSpan(
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
            children: [
              const TextSpan(text: 'Materiales'),
              TextSpan(text: 'Ya', style: TextStyle(color: AppColors.primary)),
            ],
          ),
        ),
        actions: [
          // Toggle abierto en el header
          _ToggleAbierto(
            abierto: abierto,
            procesando: _procesandoToggle,
            onToggle: _toggleAbierto,
          ),
          IconButton(
            icon: const Icon(Icons.logout, size: 20),
            tooltip: 'Cerrar sesión',
            onPressed: _cerrarSesion,
          ),
        ],
      ),
      body: _cargando
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _cargarDatos,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Header comercio
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [BoxShadow(color: Color(0x14000000), offset: Offset(0, 2), blurRadius: 8)],
                    ),
                    child: Row(children: [
                      Container(
                        width: 52, height: 52,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.store, color: AppColors.primary, size: 28),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(_comercio?['nombre'] ?? 'Mi comercio',
                          style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                        Text(_comercio?['tipo'] ?? '',
                          style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 13)),
                      ])),
                    ]),
                  ),
                  const SizedBox(height: 16),

                  // Métricas del día en grid 2x2
                  Text('Resumen de hoy', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  const SizedBox(height: 10),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.5,
                    children: [
                      _MetricCard(icon: Icons.receipt_long, label: 'Pedidos hoy', value: '${_estadisticas?['recibidos'] ?? 0}', color: AppColors.primary),
                      _MetricCard(icon: Icons.inventory_2_outlined, label: 'En preparación', value: '${_estadisticas?['en_preparacion'] ?? 0}', color: AppColors.warning),
                      _MetricCard(icon: Icons.check_circle_outline, label: 'Entregados', value: '${_estadisticas?['entregados'] ?? 0}', color: AppColors.success),
                      _MetricCard(icon: Icons.attach_money, label: 'Ingresos del día', value: '\$${(num.tryParse('${_estadisticas?['ingresos'] ?? 0}') ?? 0).toStringAsFixed(0)}', color: const Color(0xFF6366F1)),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Botón validar retiro
                  OutlinedButton.icon(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ValidarRetiroScreen())),
                    icon: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.primary),
                    label: Text('Validar retiro de cliente', style: GoogleFonts.poppins(color: AppColors.primary, fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      minimumSize: const Size(double.infinity, 0),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Gráfico semanal
                  if (_datosSemanales.isNotEmpty) ...[
                    Text('Esta semana', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    const SizedBox(height: 8),
                    _GraficoBarras(datos: _datosSemanales),
                    const SizedBox(height: 16),
                  ],

                  // Pedidos pendientes
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('Pedidos pendientes', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    if (_pedidosPendientes.isNotEmpty)
                      TextButton(
                        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PedidosScreen())),
                        child: Text('Ver todos', style: GoogleFonts.poppins(color: AppColors.primary, fontWeight: FontWeight.w600)),
                      ),
                  ]),
                  const SizedBox(height: 4),
                  if (_pedidosPendientes.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [BoxShadow(color: Color(0x14000000), offset: Offset(0, 2), blurRadius: 8)],
                      ),
                      child: Center(child: Text('No hay pedidos pendientes', style: GoogleFonts.poppins(color: AppColors.textSecondary))),
                    )
                  else
                    ..._pedidosPendientes.map((p) => _pedidoItem(p as Map<String, dynamic>)),

                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PedidosScreen())),
                    icon: const Icon(Icons.receipt_long),
                    label: Text('Ver todos los pedidos', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _pedidoItem(Map<String, dynamic> pedido) {
    final numero = pedido['numero'] ?? pedido['id'] ?? '?';
    final clienteNombre = pedido['cliente']?['nombre'] ?? pedido['cliente_nombre'] ?? 'Cliente';
    final total = double.tryParse(pedido['total']?.toString() ?? '0') ?? 0;
    final tiempo = _tiempoDesde(pedido['created_at']);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Color(0x14000000), offset: Offset(0, 2), blurRadius: 8)],
      ),
      child: ListTile(
        leading: Container(
          width: 40, height: 40,
          decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
          child: const Icon(Icons.receipt, color: AppColors.primary, size: 20),
        ),
        title: Text('Pedido #$numero', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary)),
        subtitle: Text(clienteNombre, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary)),
        trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('\$${total.toStringAsFixed(0)}', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: AppColors.primary)),
          if (tiempo.isNotEmpty)
            Text(tiempo, style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textLight)),
        ]),
      ),
    );
  }
}

// ─── METRIC CARD ──────────────────────────────────────────────────────────────
class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  const _MetricCard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x14000000), offset: Offset(0, 2), blurRadius: 8)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 18),
        ),
        const Spacer(),
        Text(value, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        Text(label, style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textSecondary)),
      ]),
    );
  }
}

// ─── TOGGLE ABIERTO ───────────────────────────────────────────────────────────
class _ToggleAbierto extends StatelessWidget {
  final bool abierto, procesando;
  final VoidCallback onToggle;
  const _ToggleAbierto({required this.abierto, required this.procesando, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: GestureDetector(
        onTap: procesando ? null : onToggle,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: abierto ? const Color(0xFF0D5C37) : const Color(0xFF374151),
            borderRadius: BorderRadius.circular(20),
          ),
          child: procesando
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: abierto ? AppColors.success : AppColors.textLight)),
                const SizedBox(width: 6),
                Text(abierto ? 'ABIERTO' : 'CERRADO',
                  style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
              ]),
        ),
      ),
    );
  }
}

// ─── GRÁFICO DE BARRAS SEMANAL ────────────────────────────────────────────────
class _GraficoBarras extends StatefulWidget {
  final List<dynamic> datos;
  const _GraficoBarras({required this.datos});
  @override
  State<_GraficoBarras> createState() => _GraficoBarrasState();
}

class _GraficoBarrasState extends State<_GraficoBarras> {
  // 0=ingresos, 1=pedidos
  int _metrica = 0;

  static const _dias = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

  @override
  Widget build(BuildContext context) {
    final datos = widget.datos;
    final valores = datos.map((d) {
      if (_metrica == 0) return (num.tryParse(d['ingresos'].toString()) ?? 0).toDouble();
      return (num.tryParse(d['total_pedidos'].toString()) ?? 0).toDouble();
    }).toList();
    final maxVal = valores.isEmpty ? 1.0 : (valores.reduce((a, b) => a > b ? a : b));
    final maxDisplay = maxVal == 0 ? 1.0 : maxVal;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Selector
          Row(children: [
            _chip('Ingresos', 0),
            const SizedBox(width: 8),
            _chip('Pedidos', 1),
            const Spacer(),
            if (maxVal > 0)
              Text(
                _metrica == 0
                    ? 'Total: \$${valores.reduce((a, b) => a + b).toStringAsFixed(0)}'
                    : 'Total: ${valores.reduce((a, b) => a + b).toStringAsFixed(0)} pedidos',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
          ]),
          const SizedBox(height: 16),
          // Barras
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(datos.length, (i) {
                final val = valores[i];
                final ratio = maxDisplay == 0 ? 0.0 : val / maxDisplay;
                final fecha = datos[i]['fecha']?.toString() ?? '';
                final diasem = _diaSemana(fecha);
                return Expanded(child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (val > 0)
                      Text(
                        _metrica == 0 ? '\$${_fmt(val)}' : '${val.toInt()}',
                        style: const TextStyle(fontSize: 8, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    const SizedBox(height: 2),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOut,
                      height: ratio * 90,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: _esHoy(fecha) ? AppColors.primary : AppColors.primary.withValues(alpha: 0.35),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(diasem, style: TextStyle(fontSize: 10,
                      fontWeight: _esHoy(fecha) ? FontWeight.bold : FontWeight.normal,
                      color: _esHoy(fecha) ? AppColors.primary : AppColors.textSecondary)),
                  ],
                ));
              }),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _chip(String label, int idx) => GestureDetector(
    onTap: () => setState(() => _metrica = idx),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _metrica == idx ? AppColors.primary : AppColors.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(
        fontSize: 11, fontWeight: FontWeight.w600,
        color: _metrica == idx ? Colors.white : Colors.grey)),
    ),
  );

  String _diaSemana(String fecha) {
    try {
      final dt = DateTime.parse(fecha);
      return _dias[dt.weekday - 1];
    } catch (_) { return '?'; }
  }

  bool _esHoy(String fecha) {
    final hoy = DateTime.now();
    final s = '${hoy.year}-${hoy.month.toString().padLeft(2, '0')}-${hoy.day.toString().padLeft(2, '0')}';
    return fecha.startsWith(s);
  }

  String _fmt(double v) {
    if (v >= 1000000) return '${(v/1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v/1000).toStringAsFixed(0)}k';
    return v.toStringAsFixed(0);
  }
}
