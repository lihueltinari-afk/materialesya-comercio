import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme.dart';
import '../core/app_colors.dart';

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

  // El último paso real es _pasos.length - 1; después viene el slide de MyStock (índice _pasos.length)
  bool get _esSlideMyStock => _page == _pasos.length;
  int get _totalSlides => _pasos.length + 1;

  @override
  Widget build(BuildContext context) {
    final ultimo = _page == _totalSlides - 1;
    return Scaffold(
      backgroundColor: _esSlideMyStock ? const Color(0xFF0D0D1A) : Colors.white,
      body: SafeArea(
        child: Column(children: [
          Align(
            alignment: Alignment.topRight,
            child: TextButton(
              onPressed: _finalizar,
              child: Text('Saltar', style: TextStyle(color: _esSlideMyStock ? Colors.white54 : Colors.grey)),
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: _ctrl,
              itemCount: _totalSlides,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (_, i) => i < _pasos.length
                  ? _PasoWidget(paso: _pasos[i])
                  : const _SlideMyStock(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_totalSlides, (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _page == i ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _page == i
                        ? (_esSlideMyStock ? const Color(0xFFE8601C) : AppColors.primary)
                        : (_esSlideMyStock ? Colors.white24 : Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(3),
                  ),
                )),
              ),
              const SizedBox(height: 24),
              if (_esSlideMyStock) ...[
                ElevatedButton(
                  onPressed: () => launchUrl(
                    Uri.parse('https://stock.materialesya.com.ar'),
                    mode: LaunchMode.externalApplication,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE8601C),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: const Text('Probar 14 días gratis', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _finalizar,
                  child: const Text('Ahora no', style: TextStyle(color: Colors.white54, fontSize: 14)),
                ),
              ] else
                ElevatedButton(
                  onPressed: () {
                    if (_page == _pasos.length - 1) {
                      _ctrl.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
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
                  child: const Text('Siguiente', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _SlideMyStock extends StatelessWidget {
  const _SlideMyStock();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 120, height: 120,
          decoration: BoxDecoration(
            color: const Color(0xFFE8601C).withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: const Text('📦', style: TextStyle(fontSize: 56), textAlign: TextAlign.center),
        ),
        const SizedBox(height: 32),
        const Text(
          'Actualizá precios automáticamente',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white, height: 1.3),
        ),
        const SizedBox(height: 16),
        const Text(
          'Con MaterialesYaStock subís la lista de precios del proveedor (PDF, Excel o foto) y la IA actualiza todo tu catálogo en segundos.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Color(0xFFAAAAAA), height: 1.65),
        ),
        const SizedBox(height: 28),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE8601C).withOpacity(0.5)),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: const [
            _Stat(numero: '14', label: 'días gratis'),
            _Divider(),
            _Stat(numero: '2 min', label: 'para subir una lista'),
            _Divider(),
            _Stat(numero: '0', label: 'tarjeta requerida'),
          ]),
        ),
      ]),
    );
  }
}

class _Stat extends StatelessWidget {
  final String numero;
  final String label;
  const _Stat({required this.numero, required this.label});

  @override
  Widget build(BuildContext context) => Column(mainAxisSize: MainAxisSize.min, children: [
    Text(numero, style: const TextStyle(color: Color(0xFFE8601C), fontWeight: FontWeight.w900, fontSize: 18)),
    const SizedBox(height: 2),
    Text(label, style: const TextStyle(color: Color(0xFF888888), fontSize: 11), textAlign: TextAlign.center),
  ]);
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) => Container(width: 1, height: 32, color: Colors.white12);
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
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary, height: 1.3),
        ),
        const SizedBox(height: 16),
        Text(
          paso.texto,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.65),
        ),
      ]),
    );
  }
}
