import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme.dart';

class DetallePedidoScreen extends StatefulWidget {
  final int pedidoId;

  const DetallePedidoScreen({super.key, required this.pedidoId});

  @override
  State<DetallePedidoScreen> createState() => _DetallePedidoScreenState();
}

class _DetallePedidoScreenState extends State<DetallePedidoScreen> {
  Map<String, dynamic>? _pedido;
  bool _cargando = true;
  bool _procesando = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _cargarPedido();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _cargarPedido());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _cargarPedido() async {
    try {
      final pedido = await ApiService.detallePedido(widget.pedidoId);
      if (!mounted) return;
      setState(() {
        _pedido = pedido;
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
      'preparando': 'En preparación',
      'listo': 'Listo para retirar',
      'listo_para_retirar': 'Listo para retirar',
      'en_camino': 'En camino',
      'entregado': 'Entregado',
      'cancelado': 'Cancelado',
    };
    return labels[estado] ?? estado;
  }

  Future<void> _aceptar() async {
    // Dialog para elegir tiempo estimado
    final tiempoSeleccionado = await showDialog<int>(
      context: context,
      builder: (ctx) => _DialogTiempoEstimado(),
    );
    if (tiempoSeleccionado == null || !mounted) return;

    setState(() => _procesando = true);
    final ok = await ApiService.aceptarPedido(widget.pedidoId, tiempoSeleccionado);
    if (!mounted) return;
    setState(() => _procesando = false);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pedido aceptado'), backgroundColor: Colors.green),
      );
      await _cargarPedido();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al aceptar el pedido'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _rechazar() async {
    final motivoCtrl = TextEditingController();
    final confirmar = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rechazar pedido'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Indicá el motivo del rechazo:'),
            const SizedBox(height: 12),
            TextField(
              controller: motivoCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Ej: Producto sin stock',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(motivoCtrl.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );

    if (confirmar == null || !mounted) return;

    setState(() => _procesando = true);
    final ok = await ApiService.rechazarPedido(widget.pedidoId, confirmar);
    if (!mounted) return;
    setState(() => _procesando = false);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pedido rechazado'), backgroundColor: Colors.orange),
      );
      await _cargarPedido();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al rechazar el pedido'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _marcarListo() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Marcar como listo'),
        content: const Text('¿El pedido está listo para que lo retire el repartidor?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
            child: const Text('Sí, está listo'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    setState(() => _procesando = true);
    final ok = await ApiService.pedidoListo(widget.pedidoId);
    if (!mounted) return;
    setState(() => _procesando = false);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pedido marcado como listo'), backgroundColor: Colors.purple),
      );
      await _cargarPedido();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al actualizar el pedido'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kFondo,
      appBar: AppBar(
        title: Text(_pedido != null ? 'Pedido #${_pedido!['numero'] ?? _pedido!['id']}' : 'Detalle del pedido'),
        backgroundColor: kNaranja,
        foregroundColor: Colors.white,
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: kNaranja))
          : _pedido == null
              ? const Center(child: Text('No se pudo cargar el pedido'))
              : _buildContenido(),
    );
  }

  Widget _buildContenido() {
    final pedido = _pedido!;
    final estado = pedido['estado'] ?? '';
    final color = _colorEstado(estado);
    final cliente = pedido['cliente'] ?? {};
    final items = List<dynamic>.from(pedido['items'] ?? pedido['productos'] ?? []);
    final total = double.tryParse(pedido['total']?.toString() ?? '0') ?? 0;
    final calificacion = pedido['calificacion'];

    return RefreshIndicator(
      color: kNaranja,
      onRefresh: _cargarPedido,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Estado
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text('Estado:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _labelEstado(estado),
                      style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Datos del cliente
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Cliente', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: kAzul)),
                  const Divider(),
                  _infoRow(Icons.person, cliente['nombre'] ?? 'Sin nombre'),
                  if ((cliente['telefono'] ?? '').toString().isNotEmpty)
                    _infoRow(Icons.phone, cliente['telefono'].toString()),
                  if ((pedido['direccion_entrega'] ?? pedido['dir_entrega'] ?? '').toString().isNotEmpty)
                    _infoRow(Icons.location_on, (pedido['direccion_entrega'] ?? pedido['dir_entrega']).toString()),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Productos
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Productos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: kAzul)),
                  const Divider(),
                  if (items.isEmpty)
                    const Text('Sin productos', style: TextStyle(color: Colors.grey))
                  else
                    ...items.map((item) => _itemRow(item)),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(
                        '\$${total.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: kNaranja),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Calificación (si entregado)
          if (estado == 'entregado' && calificacion != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Calificación recibida', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: kAzul)),
                    const Divider(),
                    Row(
                      children: List.generate(5, (i) {
                        final puntaje = int.tryParse(calificacion['puntaje']?.toString() ?? '0') ?? 0;
                        return Icon(
                          i < puntaje ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                        );
                      }),
                    ),
                    if ((calificacion['comentario'] ?? '').toString().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(calificacion['comentario'].toString(), style: const TextStyle(color: Colors.grey)),
                    ],
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Acciones según estado
          if (_procesando)
            const Center(child: CircularProgressIndicator(color: kNaranja))
          else if (estado == 'pendiente') ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _rechazar,
                    icon: const Icon(Icons.close, color: Colors.red),
                    label: const Text('Rechazar', style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _aceptar,
                    icon: const Icon(Icons.check),
                    label: const Text('Aceptar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                ),
              ],
            ),
          ] else if (estado == 'aceptado' || estado == 'preparando' || estado == 'confirmado') ...[
            ElevatedButton.icon(
              onPressed: _marcarListo,
              icon: const Icon(Icons.done_all),
              label: const Text('Pedido listo para retirar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icono, String texto) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icono, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(child: Text(texto, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  Widget _itemRow(dynamic item) {
    final nombre = item['nombre'] ?? item['producto']?['nombre'] ?? 'Producto';
    final cantidad = item['cantidad'] ?? 1;
    final precio = double.tryParse(item['precio']?.toString() ?? '0') ?? 0;
    final subtotal = double.tryParse(item['subtotal']?.toString() ?? '0') ?? (precio * cantidad);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nombre, style: const TextStyle(fontWeight: FontWeight.w500)),
                Text('x$cantidad · \$${precio.toStringAsFixed(0)} c/u', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          Text('\$${subtotal.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// ─── DIALOG TIEMPO ESTIMADO ────────────────────────────────────────────────────

class _DialogTiempoEstimado extends StatefulWidget {
  @override
  State<_DialogTiempoEstimado> createState() => _DialogTiempoEstimadoState();
}

class _DialogTiempoEstimadoState extends State<_DialogTiempoEstimado> {
  int _seleccionado = 30;
  final List<int> _opciones = [15, 30, 45, 60];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tiempo estimado de preparación'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: _opciones.map((min) {
          return RadioListTile<int>(
            value: min,
            groupValue: _seleccionado,
            title: Text('$min minutos'),
            activeColor: kNaranja,
            onChanged: (v) => setState(() => _seleccionado = v!),
          );
        }).toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_seleccionado),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
          child: const Text('Confirmar'),
        ),
      ],
    );
  }
}
