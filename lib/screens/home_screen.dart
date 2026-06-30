import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme.dart';
import 'pedidos_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _comercio;
  Map<String, dynamic>? _estadisticas;
  List<dynamic> _pedidosPendientes = [];
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
      final est = await ApiService.estadisticasHoy();
      final pedidos = await ApiService.pedidosDelComercio(0, estado: 'pendiente');
      if (!mounted) return;
      setState(() {
        _estadisticas = est;
        _pedidosPendientes = pedidos.length > 3 ? pedidos.sublist(0, 3) : pedidos;
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
      backgroundColor: kFondo,
      appBar: AppBar(
        title: RichText(
          text: const TextSpan(
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
            children: [
              TextSpan(text: 'Materiales'),
              TextSpan(text: 'Ya', style: TextStyle(color: Color(0xFFFFD280))),
            ],
          ),
        ),
        backgroundColor: kNaranja,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: _cerrarSesion,
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: kNaranja))
          : RefreshIndicator(
              color: kNaranja,
              onRefresh: _cargarDatos,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Header comercio
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: kNaranja.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.store, color: kNaranja, size: 28),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _comercio?['nombre'] ?? 'Mi comercio',
                                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: kAzul),
                                ),
                                Text(
                                  _comercio?['tipo'] ?? '',
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Toggle abierto/cerrado
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      child: Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                abierto ? 'ABIERTO' : 'CERRADO',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: abierto ? Colors.green : Colors.red,
                                ),
                              ),
                              Text(
                                abierto ? 'Recibiendo pedidos' : 'No recibís pedidos',
                                style: const TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                            ],
                          ),
                          const Spacer(),
                          _procesandoToggle
                              ? const SizedBox(
                                  width: 32,
                                  height: 32,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: kNaranja),
                                )
                              : Switch(
                                  value: abierto,
                                  activeColor: Colors.green,
                                  onChanged: (_) => _toggleAbierto(),
                                ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Estadísticas del día
                  const Text(
                    'Resumen de hoy',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: kAzul),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _statCard('${_estadisticas?['recibidos'] ?? 0}', 'Recibidos', Icons.inbox, Colors.blue),
                      const SizedBox(width: 8),
                      _statCard('${_estadisticas?['en_preparacion'] ?? 0}', 'Preparando', Icons.construction, Colors.orange),
                      const SizedBox(width: 8),
                      _statCard('${_estadisticas?['entregados'] ?? 0}', 'Entregados', Icons.check_circle, Colors.green),
                      const SizedBox(width: 8),
                      _statCard(
                        '\$${((_estadisticas?['ingresos'] ?? 0) as num).toStringAsFixed(0)}',
                        'Ingresos',
                        Icons.attach_money,
                        Colors.teal,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Pedidos pendientes
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Pedidos pendientes',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: kAzul),
                      ),
                      if (_pedidosPendientes.isNotEmpty)
                        TextButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const PedidosScreen()),
                          ),
                          child: const Text('Ver todos', style: TextStyle(color: kNaranja)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (_pedidosPendientes.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(
                          child: Text('No hay pedidos pendientes', style: TextStyle(color: Colors.grey)),
                        ),
                      ),
                    )
                  else
                    ..._pedidosPendientes.map((p) => _pedidoItem(p as Map<String, dynamic>)),

                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PedidosScreen()),
                    ),
                    icon: const Icon(Icons.receipt_long),
                    label: const Text('Ver todos los pedidos'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kAzul,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _statCard(String valor, String label, IconData icono, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Column(
            children: [
              Icon(icono, color: color, size: 20),
              const SizedBox(height: 4),
              Text(valor, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
              Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pedidoItem(Map<String, dynamic> pedido) {
    final numero = pedido['numero'] ?? pedido['id'] ?? '?';
    final clienteNombre = pedido['cliente']?['nombre'] ?? pedido['cliente_nombre'] ?? 'Cliente';
    final total = double.tryParse(pedido['total']?.toString() ?? '0') ?? 0;
    final tiempo = _tiempoDesde(pedido['created_at']);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFFFF3E0),
          child: Icon(Icons.receipt, color: Colors.orange),
        ),
        title: Text('Pedido #$numero', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(clienteNombre),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('\$${total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            if (tiempo.isNotEmpty)
              Text(tiempo, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
