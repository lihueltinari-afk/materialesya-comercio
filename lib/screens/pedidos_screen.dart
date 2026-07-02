import 'dart:async';
import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../services/api_service.dart';
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
  Timer? _tickerCountdown;

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
    // Ticker liviano solo para refrescar el countdown visual de pedidos pendientes (no pide datos nuevos).
    _tickerCountdown = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _pedidos.any((p) => p['estado'] == 'pendiente')) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tickerCountdown?.cancel();
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

  // El backend envía timestamps UTC sin sufijo Z → hay que forzar interpretación UTC
  DateTime _parsearFecha(String iso) {
    final s = (iso.contains('+') || iso.toUpperCase().endsWith('Z')) ? iso : '${iso}Z';
    return DateTime.parse(s).toLocal();
  }

  // Para pedidos pendientes: minutos y segundos restantes (límite 35 min para aceptar/rechazar).
  String? _tiempoRestanteParaAceptar(String? fechaStr) {
    if (fechaStr == null) return null;
    try {
      final creado = _parsearFecha(fechaStr);
      final limite = creado.add(const Duration(minutes: 35));
      final restante = limite.difference(DateTime.now());
      if (restante.isNegative) return 'Vencido';
      final min = restante.inMinutes;
      final seg = restante.inSeconds % 60;
      return '$min:${seg.toString().padLeft(2, '0')}';
    } catch (_) {
      return null;
    }
  }

  String _horaExacta(String? fechaStr) {
    if (fechaStr == null) return '';
    try {
      final fecha = _parsearFecha(fechaStr);
      final h = fecha.hour.toString().padLeft(2, '0');
      final m = fecha.minute.toString().padLeft(2, '0');
      return '$h:$m';
    } catch (_) {
      return '';
    }
  }

  String _tiempoDesde(String? fechaStr) {
    if (fechaStr == null) return '';
    try {
      final fecha = _parsearFecha(fechaStr);
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pedidos'),
        backgroundColor: AppColors.primary,
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
                        color: sel ? AppColors.primary : Colors.grey.shade100,
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
                ? ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: 3,
                    itemBuilder: (_, __) => _PedidoSkeleton(),
                  )
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
                        color: AppColors.primary,
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
    final tiempo = _tiempoDesde(pedido['creado_en']?.toString());

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
                backgroundColor: color.withValues(alpha: 0.12),
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
                    if (_horaExacta(pedido['creado_en']?.toString()).isNotEmpty)
                      Text(_horaExacta(pedido['creado_en']?.toString()),
                        style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w600)),
                    if (estado == 'pendiente' && _tiempoRestanteParaAceptar(pedido['creado_en']?.toString()) != null)
                      Text('⏱ ${_tiempoRestanteParaAceptar(pedido['creado_en']?.toString())} para responder',
                        style: const TextStyle(color: Colors.deepOrange, fontSize: 11, fontWeight: FontWeight.w700))
                    else if (tiempo.isNotEmpty)
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
                      color: color.withValues(alpha: 0.12),
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

class _PedidoSkeleton extends StatefulWidget {
  @override
  State<_PedidoSkeleton> createState() => _PedidoSkeletonState();
}
class _PedidoSkeletonState extends State<_PedidoSkeleton> with SingleTickerProviderStateMixin {
  late AnimationController _ac;
  late Animation<double> _anim;
  @override
  void initState() {
    super.initState();
    _ac = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ac, curve: Curves.easeInOut);
  }
  @override
  void dispose() { _ac.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final c1 = Color.lerp(Colors.grey.shade200, Colors.grey.shade100, _anim.value)!;
        final c2 = Color.lerp(Colors.grey.shade300, Colors.grey.shade200, _anim.value)!;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: const Color(0x0A000000), blurRadius: 6)]),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(height: 13, width: 140, decoration: BoxDecoration(color: c2, borderRadius: BorderRadius.circular(6))),
              const SizedBox(height: 8),
              Container(height: 10, width: 100, decoration: BoxDecoration(color: c1, borderRadius: BorderRadius.circular(6))),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Container(width: 60, height: 22, decoration: BoxDecoration(color: c1, borderRadius: BorderRadius.circular(12))),
              const SizedBox(height: 6),
              Container(width: 50, height: 13, decoration: BoxDecoration(color: c1, borderRadius: BorderRadius.circular(6))),
            ]),
          ]),
        );
      },
    );
  }
}



