import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'catalogo_screen.dart';
import 'login_screen.dart';

const _amber = Color(0xFFE07B00);
const _bgPage = Color(0xFFF5F5F3);
const _textDark = Color(0xFF1A1A1A);
const _success = Color(0xFF2E7D32);
const _successBg = Color(0xFFE8F5E9);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;
  Map<String, dynamic>? _comercio;
  bool _cargandoComercio = true;

  @override
  void initState() {
    super.initState();
    _cargarComercio();
  }

  Future<void> _cargarComercio() async {
    final c = await ApiService.miComercio();
    if (mounted) setState(() { _comercio = c; _cargandoComercio = false; });
  }

  Future<void> _toggleAbierto(bool v) async {
    if (_comercio == null) return;
    setState(() => _comercio!['abierto'] = v);
    await ApiService.actualizarAbierto(_comercio!['id'] as int, v);
  }

  void _cerrarSesion() async {
    await ApiService.cerrarSesion();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final abierto = _comercio?['abierto'] == true;
    final comercioId = _comercio?['id'] as int?;

    final screens = [
      _InicioTab(comercioId: comercioId, comercio: _comercio),
      CatalogoScreen(comercioId: comercioId),
      _PedidosTab(comercioId: comercioId),
      _ConfigTab(onCerrarSesion: _cerrarSesion, comercio: _comercio),
    ];

    return Scaffold(
      backgroundColor: _bgPage,
      body: SafeArea(child: Column(children: [
        _header(abierto),
        Expanded(child: _cargandoComercio
          ? const Center(child: CircularProgressIndicator(color: _amber))
          : IndexedStack(index: _navIndex, children: screens)),
      ])),
      bottomNavigationBar: _navBar(),
    );
  }

  Widget _header(bool abierto) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(children: [
        Container(width: 34, height: 34, decoration: BoxDecoration(color: _amber, borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.store, color: Colors.white, size: 18)),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          RichText(text: const TextSpan(style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: _textDark, letterSpacing: -0.5), children: [
            TextSpan(text: 'Materiales'), TextSpan(text: 'Ya', style: TextStyle(color: _amber)),
          ])),
          Text(_comercio?['nombre'] ?? 'Panel del comercio', style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ]),
        const Spacer(),
        GestureDetector(
          onTap: () => _toggleAbierto(!abierto),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: abierto ? _successBg : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 6, height: 6, decoration: BoxDecoration(color: abierto ? _success : Colors.grey, shape: BoxShape.circle)),
              const SizedBox(width: 5),
              Text(abierto ? 'Abierto' : 'Cerrado', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: abierto ? _success : Colors.grey)),
            ]),
          ),
        ),
        Switch(value: abierto, onChanged: _toggleAbierto, activeColor: _amber, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
      ]),
    );
  }

  Widget _navBar() {
    final items = [
      {'icono': Icons.home_outlined, 'label': 'Inicio'},
      {'icono': Icons.inventory_2_outlined, 'label': 'Catálogo'},
      {'icono': Icons.receipt_long_outlined, 'label': 'Pedidos'},
      {'icono': Icons.settings_outlined, 'label': 'Config'},
    ];
    return Container(
      decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.shade100))),
      child: SafeArea(top: false, child: Row(
        children: List.generate(items.length, (i) {
          final sel = i == _navIndex;
          return Expanded(child: GestureDetector(
            onTap: () => setState(() => _navIndex = i),
            child: Container(color: Colors.transparent, padding: const EdgeInsets.symmetric(vertical: 10), child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(items[i]['icono'] as IconData, color: sel ? _amber : Colors.grey, size: 24),
              const SizedBox(height: 2),
              Text(items[i]['label'] as String, style: TextStyle(fontSize: 10, color: sel ? _amber : Colors.grey, fontWeight: sel ? FontWeight.w700 : FontWeight.normal)),
            ])),
          ));
        }),
      )),
    );
  }
}

// ─── TAB INICIO ───────────────────────────────────────────────────────────────
class _InicioTab extends StatefulWidget {
  final int? comercioId;
  final Map<String, dynamic>? comercio;
  const _InicioTab({required this.comercioId, required this.comercio});
  @override
  State<_InicioTab> createState() => _InicioTabState();
}

class _InicioTabState extends State<_InicioTab> {
  List<dynamic> _pedidos = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    if (widget.comercioId == null) return;
    setState(() => _cargando = true);
    // Cargar pedidos activos (no entregados ni cancelados)
    final todos = await ApiService.pedidosDelComercio(widget.comercioId!);
    if (mounted) {
      setState(() {
        _pedidos = todos.where((p) => !['entregado', 'cancelado'].contains(p['estado'])).toList();
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalHoy = _pedidos.length;
    final pendientes = _pedidos.where((p) => p['estado'] == 'pendiente').length;
    final ventaHoy = _pedidos.fold<double>(0, (a, b) => a + double.tryParse(b['total'].toString())!);

    return RefreshIndicator(
      onRefresh: _cargar,
      color: _amber,
      child: ListView(children: [
        // Stats
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            _statCard('$totalHoy', 'Activos', Icons.receipt_long_outlined, _amber),
            const SizedBox(width: 8),
            _statCard('\$${_fmt(ventaHoy)}', 'En curso', Icons.trending_up, _success),
            const SizedBox(width: 8),
            _statCard('$pendientes', 'Pendientes', Icons.pending_outlined, Colors.orange),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Row(children: [
            const Text('Pedidos activos', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _textDark)),
            const Spacer(),
            GestureDetector(onTap: _cargar, child: const Icon(Icons.refresh, color: _amber, size: 20)),
          ]),
        ),
        if (_cargando)
          const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: _amber)))
        else if (_pedidos.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.all(40), child: Column(children: [
            Icon(Icons.check_circle_outline, size: 48, color: Colors.grey),
            SizedBox(height: 10),
            Text('No hay pedidos activos', style: TextStyle(color: Colors.grey, fontSize: 14)),
          ])))
        else
          ..._pedidos.map((p) => _CardPedido(pedido: p, onCambioEstado: _cargar)),
        const SizedBox(height: 20),
      ]),
    );
  }

  Widget _statCard(String valor, String label, IconData icono, Color color) {
    return Expanded(child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade100)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icono, color: color, size: 20),
        const SizedBox(height: 6),
        Text(valor, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color)),
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey)),
      ]),
    ));
  }
}

// ─── CARD PEDIDO ──────────────────────────────────────────────────────────────
class _CardPedido extends StatefulWidget {
  final dynamic pedido;
  final VoidCallback onCambioEstado;
  const _CardPedido({required this.pedido, required this.onCambioEstado});
  @override
  State<_CardPedido> createState() => _CardPedidoState();
}

class _CardPedidoState extends State<_CardPedido> {
  bool _procesando = false;

  Future<void> _cambiar(String estado) async {
    setState(() => _procesando = true);
    final ok = await ApiService.cambiarEstadoPedido(widget.pedido['id'] as int, estado);
    if (!mounted) return;
    setState(() => _procesando = false);
    if (ok) widget.onCambioEstado();
    else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Error al actualizar el pedido'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final pedido = widget.pedido;
    final estado = pedido['estado'] as String;
    final total = double.tryParse(pedido['total'].toString()) ?? 0;
    final cant = pedido['cantidad_items']?.toString() ?? '?';

    final colores = {
      'pendiente': [const Color(0xFFFFF3E0), Colors.orange],
      'confirmado': [const Color(0xFFE3F2FD), Colors.blue],
      'preparando': [const Color(0xFFE3F2FD), Colors.blue],
      'listo_para_retirar': [_successBg, _success],
      'en_camino': [const Color(0xFFF3E5F5), Colors.purple],
    };
    final labels = {
      'pendiente': 'Pendiente',
      'confirmado': 'Confirmado',
      'preparando': 'Preparando',
      'listo_para_retirar': 'Listo ✓',
      'en_camino': 'En camino',
    };
    final color = colores[estado] ?? [Colors.grey.shade100, Colors.grey];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade100)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('Pedido #${pedido['id']}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: _textDark)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: color[0] as Color, borderRadius: BorderRadius.circular(20)),
            child: Text(labels[estado] ?? estado, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color[1] as Color)),
          ),
        ]),
        const SizedBox(height: 6),
        Text(pedido['cliente_nombre'] ?? 'Cliente', style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 2),
        Text('$cant producto${cant == "1" ? "" : "s"} · ${pedido['dir_entrega'] ?? ''}',
          style: const TextStyle(fontSize: 12, color: _textDark), maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 2),
        Text(pedido['metodo_pago'] == 'efectivo' ? '💵 Efectivo' : pedido['metodo_pago'] == 'transferencia' ? '🏦 Transferencia' : '💳 Mercado Pago',
          style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 8),
        Row(children: [
          if (pedido['vehiculo_requerido'] != null) ...[
            const Icon(Icons.local_shipping_outlined, size: 13, color: Colors.grey),
            const SizedBox(width: 3),
            Text(pedido['vehiculo_requerido'], style: const TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(width: 10),
          ],
          const Spacer(),
          Text('\$${_fmt(total)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _textDark)),
        ]),
        if (_procesando)
          const Padding(padding: EdgeInsets.only(top: 10), child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: _amber))))
        else ...[
          if (estado == 'pendiente') ...[
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: OutlinedButton(
                onPressed: () => _cambiar('cancelado'),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                child: const Text('Rechazar', style: TextStyle(fontSize: 12)),
              )),
              const SizedBox(width: 8),
              Expanded(child: ElevatedButton(
                onPressed: () => _cambiar('preparando'),
                style: ElevatedButton.styleFrom(backgroundColor: _amber, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                child: const Text('Aceptar', style: TextStyle(fontSize: 12)),
              )),
            ]),
          ],
          if (estado == 'confirmado' || estado == 'preparando') ...[
            const SizedBox(height: 10),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: () => _cambiar('listo_para_retirar'),
              style: ElevatedButton.styleFrom(backgroundColor: _success, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              child: const Text('Marcar listo para retirar', style: TextStyle(fontSize: 12)),
            )),
          ],
          if (estado == 'listo_para_retirar') ...[
            const SizedBox(height: 10),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: () => _cambiar('en_camino'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              child: const Text('Repartidor salió', style: TextStyle(fontSize: 12)),
            )),
          ],
          if (estado == 'en_camino') ...[
            const SizedBox(height: 10),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: () => _cambiar('entregado'),
              style: ElevatedButton.styleFrom(backgroundColor: _success, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              child: const Text('Marcar como entregado', style: TextStyle(fontSize: 12)),
            )),
          ],
        ],
      ]),
    );
  }
}

// ─── TAB PEDIDOS (historial) ──────────────────────────────────────────────────
class _PedidosTab extends StatefulWidget {
  final int? comercioId;
  const _PedidosTab({required this.comercioId});
  @override
  State<_PedidosTab> createState() => _PedidosTabState();
}

class _PedidosTabState extends State<_PedidosTab> {
  List<dynamic> _pedidos = [];
  bool _cargando = true;
  String _filtro = 'todos';

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    if (widget.comercioId == null) return;
    setState(() => _cargando = true);
    final todos = await ApiService.pedidosDelComercio(widget.comercioId!);
    if (mounted) setState(() { _pedidos = todos; _cargando = false; });
  }

  List<dynamic> get _filtrados {
    if (_filtro == 'todos') return _pedidos;
    return _pedidos.where((p) => p['estado'] == _filtro).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            _chip('todos', 'Todos'),
            _chip('pendiente', 'Pendientes'),
            _chip('preparando', 'Preparando'),
            _chip('entregado', 'Entregados'),
            _chip('cancelado', 'Cancelados'),
          ]),
        ),
      ),
      Expanded(child: _cargando
        ? const Center(child: CircularProgressIndicator(color: _amber))
        : _filtrados.isEmpty
          ? const Center(child: Text('No hay pedidos', style: TextStyle(color: Colors.grey)))
          : RefreshIndicator(
              onRefresh: _cargar, color: _amber,
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _filtrados.length,
                itemBuilder: (_, i) => _CardPedido(pedido: _filtrados[i], onCambioEstado: _cargar),
              ),
            ),
      ),
    ]);
  }

  Widget _chip(String val, String label) {
    final sel = _filtro == val;
    return GestureDetector(
      onTap: () => setState(() => _filtro = val),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: sel ? _amber : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: sel ? Colors.white : Colors.grey.shade700)),
      ),
    );
  }
}

// ─── TAB CONFIG ───────────────────────────────────────────────────────────────
class _ConfigTab extends StatelessWidget {
  final VoidCallback onCerrarSesion;
  final Map<String, dynamic>? comercio;
  const _ConfigTab({required this.onCerrarSesion, required this.comercio});

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Mi comercio', style: TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(comercio?['nombre'] ?? '-', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _textDark)),
          const SizedBox(height: 2),
          Text(comercio?['direccion'] ?? '-', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 2),
          Text('ID: ${comercio?['id'] ?? '-'}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ]),
      ),
      const SizedBox(height: 16),
      SizedBox(
        width: double.infinity, height: 50,
        child: OutlinedButton.icon(
          onPressed: onCerrarSesion,
          icon: const Icon(Icons.logout, color: Colors.red),
          label: const Text('Cerrar sesión', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
          style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        ),
      ),
    ]);
  }
}

String _fmt(double v) => v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
