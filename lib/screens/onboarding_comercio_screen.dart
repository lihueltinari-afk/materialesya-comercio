import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme.dart';

class OnboardingComercioScreen extends StatefulWidget {
  const OnboardingComercioScreen({super.key});

  @override
  State<OnboardingComercioScreen> createState() => _OnboardingComercioScreenState();
}

class _OnboardingComercioScreenState extends State<OnboardingComercioScreen> {
  final PageController _ctrl = PageController();
  int _page = 0;

  static const _pasos = [
    _Paso(
      icono: Icons.storefront_outlined,
      color: Color(0xFF6C63FF),
      titulo: '¡Bienvenido a MaterialesYa!',
      texto: 'Tu comercio ya está listo. Ahora te mostramos cómo sacarle el máximo provecho a la plataforma.',
    ),
    _Paso(
      icono: Icons.inventory_2_outlined,
      color: Color(0xFFFF6B35),
      titulo: 'Activá tus productos',
      texto: 'Ingresá a "Catálogo", buscá los productos que vendés, activálos y poné tu precio. Solo te aparecen pedidos de lo que tenés activo.',
    ),
    _Paso(
      icono: Icons.notifications_active_outlined,
      color: Color(0xFF27AE60),
      titulo: 'Recibís pedidos al instante',
      texto: 'Cuando un cliente hace un pedido, te llega una notificación. Tenés que aceptarlo y prepararlo. Usá la pestaña "Pedidos" para gestionarlos.',
    ),
    _Paso(
      icono: Icons.local_shipping_outlined,
      color: Color(0xFF2980B9),
      titulo: 'El repartidor va a retirar',
      texto: 'Un repartidor de la red llega a retirar el pedido preparado. Marcalo como "Listo" cuando esté empaquetado y esperá al repartidor.',
    ),
    _Paso(
      icono: Icons.payments_outlined,
      color: Color(0xFFE67E22),
      titulo: 'Cobrás directo en tu cuenta MP',
      texto: 'El pago del cliente se deposita automáticamente en tu cuenta de Mercado Pago. La comisión de la plataforma se descuenta antes de la acreditación.',
    ),
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _finalizar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_comercio_done', true);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final ultimo = _page == _pasos.length - 1;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(children: [
          Align(
            alignment: Alignment.topRight,
            child: TextButton(
              onPressed: _finalizar,
              child: const Text('Saltar', style: TextStyle(color: Colors.grey)),
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: _ctrl,
              itemCount: _pasos.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (_, i) => _PasoWidget(paso: _pasos[i]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(children: [
              // Indicadores de página
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pasos.length, (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _page == i ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _page == i ? AppColors.primary : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(3),
                  ),
                )),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (ultimo) {
                    _finalizar();
                  } else {
                    _ctrl.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Text(
                  ultimo ? '¡Empezar a vender!' : 'Siguiente',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _Paso {
  final IconData icono;
  final Color color;
  final String titulo;
  final String texto;
  const _Paso({required this.icono, required this.color, required this.titulo, required this.texto});
}

class _PasoWidget extends StatelessWidget {
  final _Paso paso;
  const _PasoWidget({super.key, required this.paso});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: paso.color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(paso.icono, size: 56, color: paso.color),
        ),
        const SizedBox(height: 36),
        Text(
          paso.titulo,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary, height: 1.3),
        ),
        const SizedBox(height: 16),
        Text(
          paso.texto,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.65),
        ),
      ]),
    );
  }
}
