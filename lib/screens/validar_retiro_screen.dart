import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../services/api_service.dart';

class ValidarRetiroScreen extends StatefulWidget {
  const ValidarRetiroScreen({super.key});

  @override
  State<ValidarRetiroScreen> createState() => _ValidarRetiroScreenState();
}

class _ValidarRetiroScreenState extends State<ValidarRetiroScreen> {
  final _codigoCtrl = TextEditingController();
  bool _buscando = false;
  bool _confirmando = false;
  Map<String, dynamic>? _pedido;
  String? _error;

  @override
  void dispose() {
    _codigoCtrl.dispose();
    super.dispose();
  }

  Future<void> _buscarPedido() async {
    final codigo = _codigoCtrl.text.trim();
    if (codigo.isEmpty) return;
    setState(() { _buscando = true; _error = null; _pedido = null; });
    try {
      final pedidoId = int.tryParse(codigo);
      if (pedidoId == null) {
        setState(() { _error = 'Ingresá un número de pedido válido'; _buscando = false; });
        return;
      }
      final res = await ApiService.get('/comercio/pedidos/buscar?numero=$pedidoId');
      if (res['status'] == 200) {
        final data = res['data'];
        final pedido = data is Map ? data : null;
        if (pedido == null) {
          setState(() { _error = 'Pedido no encontrado'; _buscando = false; });
          return;
        }
        // modo_entrega es obligatorio desde migración 043; si está vacío el pedido es de envío
        final modoEntrega = pedido['modo_entrega']?.toString() ?? 'envio';
        if (modoEntrega != 'retiro') {
          setState(() { _error = 'El pedido #$pedidoId es de envío a domicilio, no de retiro en comercio'; _buscando = false; });
          return;
        }
        setState(() { _pedido = Map<String, dynamic>.from(pedido); _buscando = false; });
      } else {
        final msg = res['data'] is Map ? res['data']['error']?.toString() : null;
        setState(() { _error = msg ?? 'Pedido no encontrado'; _buscando = false; });
      }
    } catch (_) {
      setState(() { _error = 'Error al buscar el pedido'; _buscando = false; });
    }
  }

  Future<void> _confirmarRetiro() async {
    if (_pedido == null) return;
    final pedidoId = _pedido!['id'] is int ? _pedido!['id'] as int : int.tryParse(_pedido!['id'].toString()) ?? 0;
    setState(() => _confirmando = true);
    try {
      final ok = await ApiService.cambiarEstadoPedido(pedidoId, 'entregado');
      if (!mounted) return;
      if (ok) {
        setState(() { _pedido = null; _codigoCtrl.clear(); _confirmando = false; });
        _mostrarExito();
      } else {
        setState(() { _error = 'No se pudo confirmar la entrega'; _confirmando = false; });
      }
    } catch (_) {
      setState(() { _error = 'Error al confirmar la entrega'; _confirmando = false; });
    }
  }

  void _mostrarExito() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 72, height: 72,
            decoration: const BoxDecoration(color: Color(0xFFD1FAE5), shape: BoxShape.circle),
            child: const Icon(Icons.check_rounded, color: Color(0xFF10B981), size: 40),
          ),
          const SizedBox(height: 16),
          const Text('¡Retiro confirmado!',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
          const SizedBox(height: 8),
          const Text('El cliente recibió su pedido correctamente.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey)),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F3),
      appBar: AppBar(
        title: const Text('Validar retiro', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Instrucciones
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'El cliente te muestra su número de pedido. Ingresalo para confirmar que retiró su compra.',
                  style: TextStyle(fontSize: 13, color: AppColors.primary, height: 1.4),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 24),

          // Input de código
          const Text('Número de pedido',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _codigoCtrl,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _buscarPedido(),
                decoration: InputDecoration(
                  hintText: 'Ej: 1042',
                  prefixIcon: const Icon(Icons.tag_rounded, color: AppColors.textSecondary),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.divider),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.divider),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                  errorText: _error,
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _buscando ? null : _buscarPedido,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                ),
                child: _buscando
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Buscar', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ]),

          // Resultado del pedido
          if (_pedido != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Pedido #${_pedido!['id']}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDE9FE),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Retiro en comercio',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF7C3AED))),
                  ),
                ]),
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 14),

                // Datos del cliente
                _dataRow(Icons.person_outline_rounded, 'Cliente',
                  _pedido!['cliente_nombre']?.toString() ?? '—'),
                const SizedBox(height: 10),
                _dataRow(Icons.phone_outlined, 'Teléfono',
                  _pedido!['cliente_telefono']?.toString() ?? '—'),
                const SizedBox(height: 10),
                _dataRow(Icons.attach_money_rounded, 'Total',
                  '\$${_formatPrecio(_pedido!['total'])}'),
                const SizedBox(height: 10),
                _dataRow(Icons.payment_rounded, 'Pago',
                  _pedido!['metodo_pago']?.toString().toUpperCase() ?? '—'),

                const SizedBox(height: 16),

                // Productos
                if (_pedido!['items'] is List) ...[
                  const Text('Productos', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
                  const SizedBox(height: 8),
                  ...(_pedido!['items'] as List).map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(children: [
                      const Icon(Icons.circle, size: 6, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Expanded(child: Text('${item['cantidad']}× ${item['nombre']}',
                        style: const TextStyle(fontSize: 13, color: Color(0xFF374151)))),
                    ]),
                  )),
                  const SizedBox(height: 8),
                ],

                // Botón confirmar
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _confirmando ? null : _confirmarRetiro,
                    icon: _confirmando
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.check_circle_outline_rounded),
                    label: Text(_confirmando ? 'Confirmando…' : 'Confirmar entrega al cliente',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ]),
            ),
          ],

          const SizedBox(height: 40),
        ]),
      ),
    );
  }

  Widget _dataRow(IconData icon, String label, String valor) {
    return Row(children: [
      Icon(icon, size: 16, color: AppColors.textSecondary),
      const SizedBox(width: 8),
      Text('$label: ', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
      Expanded(child: Text(valor, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E)))),
    ]);
  }

  String _formatPrecio(dynamic v) {
    if (v == null) return '0';
    final n = double.tryParse(v.toString()) ?? 0;
    return n.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  }
}
