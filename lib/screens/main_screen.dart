import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'home_screen.dart';
import 'pedidos_screen.dart';
import 'catalogo_screen.dart';
import 'perfil_screen.dart';
import 'seleccion_rubros_screen.dart';
import 'onboarding_comercio_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/reporte_error_button.dart';
import '../widgets/offline_banner.dart';
import '../widgets/adaptive_scaffold.dart';

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
    // Verificar rubros y onboarding al primer ingreso
    WidgetsBinding.instance.addPostFrameCallback((_) => _verificarRubrosYOnboarding());
  }

  Future<void> _verificarRubrosYOnboarding() async {
    final res = await ApiService.get('/rubros/comercio');
    if (!mounted) return;
    if (res['status'] == 200 && res['data'] is List && (res['data'] as List).isEmpty) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SeleccionRubrosScreen(esRegistro: true)),
      );
    }
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final done = prefs.getBool('onboarding_comercio_done') ?? false;
    if (!done && mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingComercioScreen()),
      );
    }
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
    return OfflineBanner(
      child: AdaptiveScaffold(
        selectedIndex: _tabActual,
        onDestinationSelected: (i) => setState(() => _tabActual = i),
        floatingActionButton: ReporteErrorButton(
          pantalla: _pantallaNames[_tabActual],
          appNombre: 'Comercio',
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endContained,
        items: [
          const NavItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Inicio'),
          NavItem(icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long, label: 'Pedidos', badge: _pedidosPendientes),
          const NavItem(icon: Icons.inventory_2_outlined, activeIcon: Icons.inventory_2, label: 'Catálogo'),
          const NavItem(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Perfil'),
        ],
        body: IndexedStack(
          index: _tabActual,
          children: _pantallas,
        ),
      ),
    );
  }
}
