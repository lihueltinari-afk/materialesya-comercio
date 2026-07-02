import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_colors.dart';
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
  Map<String, dynamic>? _reclamo;
  bool _cargando = true;
  bool _procesando = false;
  bool _repartoPropio = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _cargarPedido();
    _cargarReclamo();
    _cargarRepartoPropio();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _cargarPedido());
  }

  Future<void> _cargarRepartoPropio() async {
    final comercio = await ApiService.comercioActual();
    if (mounted) setState(() => _repartoPropio = comercio?['reparto_propio'] == true);
  }

  Future<void> _cargarReclamo() async {
    final res = await ApiService.get('/comercio/reclamos');
    if (!mounted || res['status'] != 200 || res['data'] is! List) return;
    final lista = (res['data'] as List).cast<Map>();
    final encontrado = lista.where((r) => r['pedido_id'] == widget.pedidoId);
    if (encontrado.isNotEmpty) setState(() => _reclamo = Map<String, dynamic>.from(encontrado.first));
  }

  Future<void> _responderReclamo(bool aceptar) async {
    final respuestaCtrl = TextEditingController();
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(aceptar ? 'Aceptar reclamo' : 'Rechazar reclamo'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Escribí tu respuesta para el cliente:'),
          const SizedBox(height: 12),
          TextField(controller: respuestaCtrl, maxLines: 3, decoration: const InputDecoration(border: OutlineInputBorder())),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: aceptar ? Colors.green : Colors.red, foregroundColor: Colors.white),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;
    final res = await ApiService.patch('/comercio/reclamos/${_reclamo!['id']}/responder', {
      'respuesta': respuestaCtrl.text.trim(),
      'aceptar': aceptar,
    });
    if (!mounted) return;
    if (res['status'] == 200) {
      setState(() => _reclamo = Map<String, dynamic>.from(res['data']));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Respuesta enviada'), backgroundColor: Colors.green));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al responder el reclamo'), backgroundColor: Colors.red));
    }
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

  DateTime _parsearFecha(String iso) {
    final s = (iso.contains('+') || iso.toUpperCase().endsWith('Z')) ? iso : '${iso}Z';
    return DateTime.parse(s).toLocal();
  }

  String _formatearFecha(String iso) {
    try {
      final dt = _parsearFecha(iso);
      final dias = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];
      final meses = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
      return '${dias[dt.weekday - 1]} ${dt.day} ${meses[dt.month - 1]} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} hs';
    } catch (_) { return iso; }
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

  Future<void> _cambiarEstadoRepartoPropio(String nuevoEstado) async {
    setState(() => _procesando = true);
    final ok = await ApiService.cambiarEstadoPedido(widget.pedidoId, nuevoEstado);
    if (!mounted) return;
    setState(() => _procesando = false);
    if (ok) {
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_pedido != null ? 'Pedido #${_pedido!['numero'] ?? _pedido!['id']}' : 'Detalle del pedido'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
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
      color: AppColors.primary,
      onRefresh: _cargarPedido,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Estado + timestamps
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('Estado:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _labelEstado(estado),
                          style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  if (pedido['creado_en'] != null) ...[
                    const SizedBox(height: 8),
                    Text('Recibido: ${_formatearFecha(pedido['creado_en'].toString())}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                  if (pedido['actualizado_en'] != null && estado != 'pendiente') ...[
                    const SizedBox(height: 2),
                    Text('Última actualización: ${_formatearFecha(pedido['actualizado_en'].toString())}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
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
                  const Text('Cliente', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.secondary)),
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

          // Repartidor asignado
          if ((pedido['repartidor_nombre'] ?? '').toString().isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Repartidor', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.secondary)),
                    const Divider(),
                    _infoRow(Icons.delivery_dining, pedido['repartidor_nombre'].toString()),
                    if ((pedido['repartidor_telefono'] ?? '').toString().isNotEmpty)
                      _infoRow(Icons.phone, pedido['repartidor_telefono'].toString()),
                    if (pedido['repartidor_calificacion'] != null)
                      _infoRow(Icons.star, '${double.tryParse(pedido['repartidor_calificacion'].toString())?.toStringAsFixed(1) ?? '-'} / 5'),
                  ],
                ),
              ),
            ),
          if ((pedido['repartidor_nombre'] ?? '').toString().isNotEmpty) const SizedBox(height: 12),

          // Productos
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Productos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.secondary)),
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
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary),
                      ),
                    ],
                  ),
                  // Desglose de comisión para el comercio
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F7F8),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(children: [
                      _filaDesglose('Precio cobrado al cliente', total, Colors.black87),
                      _filaDesglose('Comisión MaterialesYa (10%)', -(total * 0.10), Colors.red.shade400),
                      const Divider(height: 12),
                      _filaDesglose('Lo que recibís vos', total * 0.90, const Color(0xFF2E7D32), bold: true),
                    ]),
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
                    const Text('Calificación recibida', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.secondary)),
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

          if (_reclamo != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const Icon(Icons.report_problem_outlined, color: Colors.red, size: 18),
                    const SizedBox(width: 8),
                    const Text('Reclamo del cliente', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.secondary)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _reclamo!['estado'] == 'resuelto' ? Colors.green.shade50 : _reclamo!['estado'] == 'rechazado' ? Colors.red.shade50 : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _reclamo!['estado'] == 'resuelto' ? 'Resuelto' : _reclamo!['estado'] == 'rechazado' ? 'Rechazado' : 'En revisión',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                          color: _reclamo!['estado'] == 'resuelto' ? Colors.green : _reclamo!['estado'] == 'rechazado' ? Colors.red : Colors.orange),
                      ),
                    ),
                  ]),
                  const Divider(),
                  Text('Tipo: ${_reclamo!['tipo']}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  if ((_reclamo!['comentario'] ?? '').toString().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(_reclamo!['comentario'].toString(), style: const TextStyle(fontSize: 13, color: Colors.grey)),
                  ],
                  if (_reclamo!['estado'] == 'en_revision') ...[
                    const SizedBox(height: 14),
                    Row(children: [
                      Expanded(child: OutlinedButton(
                        onPressed: () => _responderReclamo(false),
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                        child: const Text('Rechazar'),
                      )),
                      const SizedBox(width: 8),
                      Expanded(child: ElevatedButton(
                        onPressed: () => _responderReclamo(true),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                        child: const Text('Aceptar'),
                      )),
                    ]),
                  ] else if ((_reclamo!['respuesta_comercio'] ?? '').toString().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text('Tu respuesta: ${_reclamo!['respuesta_comercio']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ]),
              ),
            ),
          if (_reclamo != null) const SizedBox(height: 12),

          const SizedBox(height: 16),

          // Acciones según estado
          if (_procesando)
            const Center(child: CircularProgressIndicator(color: AppColors.primary))
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
          ] else if (estado == 'listo_para_retirar' && !_repartoPropio && pedido['repartidor_id'] == null) ...[
            Builder(builder: (context) {
              final actualizadoEn = DateTime.tryParse(pedido['actualizado_en']?.toString() ?? '');
              final esperando = actualizadoEn != null ? DateTime.now().difference(actualizadoEn) : Duration.zero;
              final tardando = esperando.inMinutes >= 8;
              if (!tardando) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Text('Buscando un repartidor disponible…', style: TextStyle(color: Colors.grey, fontSize: 13)),
                );
              }
              return Column(children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.orange.shade200)),
                  child: const Row(children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                    SizedBox(width: 8),
                    Expanded(child: Text('Nadie tomó este pedido todavía. Podés entregarlo vos mismo si no querés esperar más.', style: TextStyle(fontSize: 13, color: Colors.black87))),
                  ]),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => _cambiarEstadoRepartoPropio('en_camino'),
                  icon: const Icon(Icons.delivery_dining),
                  label: const Text('Entregar yo mismo este pedido'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(50)),
                ),
              ]);
            }),
          ] else if (estado == 'listo_para_retirar' && _repartoPropio) ...[
            ElevatedButton.icon(
              onPressed: () => _cambiarEstadoRepartoPropio('en_camino'),
              icon: const Icon(Icons.delivery_dining),
              label: const Text('Salí a entregar (reparto propio)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ] else if (estado == 'en_camino') ...[
            ElevatedButton.icon(
              onPressed: () => _cambiarEstadoRepartoPropio('entregado'),
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Marcar como entregado'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
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

  Widget _filaDesglose(String label, double valor, Color color, {bool bold = false}) {
    final negativo = valor < 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        Text('${negativo ? '-' : ''}\$${valor.abs().toStringAsFixed(0)}',
          style: TextStyle(fontSize: 12, fontWeight: bold ? FontWeight.w800 : FontWeight.w600, color: color)),
      ]),
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
            activeColor: AppColors.primary,
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


