import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme.dart';
import 'home_screen.dart';
import 'pedidos_screen.dart';
import 'catalogo_screen.dart';
import 'perfil_screen.dart';
import '../widgets/reporte_error_button.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _tabActual = 0;
  int _pedidosPendientes = 0;
  Timer? _timer;

  // Clave para que IndexedStack mantenga el estado de cada tab
  final List<GlobalKey> _tabKeys = List.generate(4, (_) => GlobalKey());

  @override
  void initState() {
    super.initState();
    _actualizarBadge();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _actualizarBadge());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _actualizarBadge() async {
    try {
      final cantidad = await ApiService.contarPedidosPendientes();
      if (!mounted) return;
      setState(() => _pedidosPendientes = cantidad);
    } catch (_) {}
  }

  final List<String> _pantallaNames = const ['Inicio', 'Pedidos', 'Catálogo', 'Perfil'];

  final List<Widget> _pantallas = const [
    HomeScreen(),
    PedidosScreen(),
    CatalogoScreen(comercioId: null),
    PerfilScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tabActual,
        children: _pantallas,
      ),
      bottomNavigationBar: _buildNavBar(),
      floatingActionButton: ReporteErrorButton(
        pantalla: _pantallaNames[_tabActual],
        appNombre: 'Comercio',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endContained,
    );
  }

  Widget _buildNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              _navItem(0, Icons.home_outlined, Icons.home, 'Inicio'),
              _navItemConBadge(1, Icons.receipt_long_outlined, Icons.receipt_long, 'Pedidos', _pedidosPendientes),
              _navItem(2, Icons.inventory_2_outlined, Icons.inventory_2, 'Catálogo'),
              _navItem(3, Icons.person_outline, Icons.person, 'Perfil'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData iconoInactivo, IconData iconoActivo, String label) {
    final activo = _tabActual == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _tabActual = index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              activo ? iconoActivo : iconoInactivo,
              color: activo ? kNaranja : Colors.grey,
              size: 26,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: activo ? kNaranja : Colors.grey,
                fontWeight: activo ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItemConBadge(int index, IconData iconoInactivo, IconData iconoActivo, String label, int badge) {
    final activo = _tabActual == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _tabActual = index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  activo ? iconoActivo : iconoInactivo,
                  color: activo ? kNaranja : Colors.grey,
                  size: 26,
                ),
                if (badge > 0)
                  Positioned(
                    right: -6,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        badge > 99 ? '99+' : badge.toString(),
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: activo ? kNaranja : Colors.grey,
                fontWeight: activo ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
