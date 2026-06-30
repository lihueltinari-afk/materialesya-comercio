import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme.dart';
import 'detalle_pedido_screen.dart';

class PedidosScreen extends StatefulWidget {
  const PedidosScreen({super.key});

  @override
  State<PedidosScreen> createState() => _PedidosScreenState();
}

class _PedidosScreenState extends State<PedidosScreen> {
  List<dynamic> _pedidos = [];
  bool _cargando = true;
  String _filtroEstado = 'todos';
  Timer? _timer;

  final List<Map<String, String>> _filtros = [
    {'valor': 'todos', 'label': 'Todos'},
    {'valor': 'pendiente', 'label': 'Pendientes'},
    {'valor': 'aceptado', 'label': 'Aceptados'},
    {'valor': 'listo', 'label': 'Listos'},
    {'valor': 'entregado', 'label': 'Entregados'},
    {'valor': 'cancelado', 'label': 'Cancelados'},
  ];

  @override
  void initState() {
    super.initState();
    _cargarPedidos();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => _cargarPedidos());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _cargarPedidos() async {
    try {
      final estado = _filtroEstado == 'todos' ? null : _filtroEstado;
      final pedidos = await ApiService.pedidosDelComercio(0, estado: estado);
      if (!mounted) return;
      setState(() {
        _pedidos = pedidos;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _cargando = false);
    }
  }

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'pendiente':
        return Colors.orange;
      case 'aceptado':
      case 'confirmado':
      case 'preparando':
        return Colors.blue;
      case 'listo':
      case 'listo_para_retirar':
        return Colors.purple;
      case 'en_camino':
        return Colors.indigo;
      case 'entregado':
        return Colors.green;
      case 'cancelado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _labelEstado(String estado) {
    const labels = {
      'pendiente': 'Pendiente',
      'aceptado': 'Aceptado',
      'confirmado': 'Confirmado',
      'preparando': 'Preparando',
      'listo': 'Listo',
      'listo_para_retirar': 'Listo',
      'en_camino': 'En camino',
      'entregado': 'Entregado',
      'cancelado': 'Cancelado',
    };
    return labels[estado] ?? estado;
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
    return Scaffold(
      backgroundColor: kFondo,
      appBar: AppBar(
        title: const Text('Pedidos'),
        backgroundColor: kNaranja,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Chips de filtro
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: _filtros.map((f) {
                  final sel = _filtroEstado == f['valor'];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _filtroEstado = f['valor']!;
                        _cargando = true;
                      });
                      _cargarPedidos();
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: sel ? kNaranja : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        f['label']!,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: sel ? Colors.white : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Lista de pedidos
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator(color: kNaranja))
                : _pedidos.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long, size: 56, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text(
                              'No hay pedidos ${_filtroEstado == "todos" ? "" : _labelEstado(_filtroEstado).toLowerCase() + "s"}',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        color: kNaranja,
                        onRefresh: _cargarPedidos,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _pedidos.length,
                          itemBuilder: (_, i) => _pedidoCard(_pedidos[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _pedidoCard(Map<String, dynamic> pedido) {
    final estado = pedido['estado'] ?? '';
    final color = _colorEstado(estado);
    final numero = pedido['numero'] ?? pedido['id'] ?? '?';
    final clienteNombre = pedido['cliente']?['nombre'] ?? pedido['cliente_nombre'] ?? 'Cliente';
    final total = double.tryParse(pedido['total']?.toString() ?? '0') ?? 0;
    final tiempo = _tiempoDesde(pedido['created_at']);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          final id = pedido['id'];
          if (id != null) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => DetallePedidoScreen(pedidoId: id is int ? id : int.parse(id.toString())),
              ),
            ).then((_) => _cargarPedidos());
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.12),
                child: Icon(Icons.receipt, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pedido #$numero',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(clienteNombre, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    if (tiempo.isNotEmpty)
                      Text(tiempo, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _labelEstado(estado),
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${total.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
