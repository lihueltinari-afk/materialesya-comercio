import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_colors.dart';

class MyStockPromoScreen extends StatelessWidget {
  const MyStockPromoScreen({super.key});

  static const _url = 'https://stock.materialesya.com.ar';

  Future<void> _abrir() async {
    await launchUrl(Uri.parse(_url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        foregroundColor: Colors.white,
        title: RichText(
          text: const TextSpan(
            children: [
              TextSpan(text: 'MaterialesYa', style: TextStyle(color: Color(0xFFE8601C), fontWeight: FontWeight.w800, fontSize: 17)),
              TextSpan(text: 'Stock', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17)),
            ],
          ),
        ),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFF2A2A4A)),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(children: [
          // HERO
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 36, 24, 36),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF16213E), Color(0xFF0D0D1A)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8601C).withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE8601C).withOpacity(0.4), width: 2),
                ),
                child: const Center(child: Text('📦', style: TextStyle(fontSize: 38))),
              ),
              const SizedBox(height: 20),
              Text(
                '¿Cuánto tiempo perdés\nactualizando precios\na mano?',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 24, fontWeight: FontWeight.w900,
                  color: Colors.white, height: 1.25,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Con MaterialesYaStock subís la lista de tu proveedor y la IA actualiza todo tu catálogo en segundos.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFFAAAACC), height: 1.6),
              ),
              const SizedBox(height: 28),
              // STATS ROW
              Row(children: [
                _StatChip(numero: '2 min', label: 'por lista'),
                _StatChip(numero: '14 días', label: 'prueba gratis'),
                _StatChip(numero: '\$0', label: 'tarjeta'),
              ]),
            ]),
          ),

          // CÓMO FUNCIONA
          _Section(
            title: 'Cómo funciona',
            child: Column(children: [
              _Paso(numero: '1', titulo: 'Subís la lista del proveedor', desc: 'PDF, Excel o imagen. Lo que te manden, lo procesamos.'),
              _Paso(numero: '2', titulo: 'La IA extrae los productos', desc: 'Detecta nombre, precio, unidad y marca automáticamente.'),
              _Paso(numero: '3', titulo: 'Configurás tu margen', desc: 'Ponés cuánto querés ganar y el precio de venta se calcula solo.'),
              _Paso(numero: '4', titulo: 'Se sincroniza con MaterialesYa', desc: 'Tus precios se actualizan en tu catálogo sin que hagas nada más.'),
            ]),
          ),

          // BENEFICIOS
          _Section(
            title: 'Para ferreterías y corralones como el tuyo',
            child: Column(children: [
              _Beneficio(icon: '🤖', titulo: 'IA entrenada con marcas argentinas', desc: 'Klaukol, Loma Negra, Sika, Alba, Tersuave, Sherwin Williams y más.'),
              _Beneficio(icon: '📊', titulo: 'Márgenes por producto', desc: 'Configurá márgenes distintos para cada categoría o proveedor.'),
              _Beneficio(icon: '🔄', titulo: 'Sincronización automática', desc: 'Los precios se actualizan solos en MaterialesYa cuando confirmás.'),
              _Beneficio(icon: '📋', titulo: 'Historial completo', desc: 'Revertí a precios anteriores con un click si algo salió mal.'),
              _Beneficio(icon: '📤', titulo: 'Exportar a Excel y WhatsApp', desc: 'Compartí tu lista actualizada con clientes en segundos.'),
            ]),
          ),

          // PRECIO
          _Section(
            title: 'Precio',
            child: Column(children: [
              // Fundadores banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8601C).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE8601C).withOpacity(0.4)),
                ),
                child: Row(children: [
                  const Text('🔥', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Precio fundador disponible',
                      style: GoogleFonts.poppins(color: const Color(0xFFE8601C), fontWeight: FontWeight.w800, fontSize: 14)),
                    Text('Los primeros 30 comercios pagan \$5.990/mes para siempre.',
                      style: GoogleFonts.poppins(color: const Color(0xFFAAAACC), fontSize: 12, height: 1.4)),
                  ])),
                ]),
              ),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: _PriceCard(plan: 'Mensual', precio: '\$8.990', sub: '/mes', destacado: false)),
                const SizedBox(width: 10),
                Expanded(child: _PriceCard(plan: 'Anual', precio: '\$79.990', sub: '/año', destacado: true, ahorro: 'Ahorrás \$27.890')),
              ]),
              const SizedBox(height: 10),
              _PriceCard(plan: '🔥 Fundador', precio: '\$5.990', sub: '/mes para siempre', destacado: false, full: true, nota: 'Solo para los primeros 30 — precio congelado de por vida'),
            ]),
          ),

          // CTA FINAL
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
            decoration: const BoxDecoration(
              color: Color(0xFF16213E),
              border: Border(top: BorderSide(color: Color(0xFF2A2A4A))),
            ),
            child: Column(children: [
              Text(
                '14 días gratis, sin tarjeta',
                style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Cancelás cuando querés. Soporte en español.',
                style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFFAAAACC)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _abrir,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE8601C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: Text('Empezar prueba gratuita →',
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _abrir,
                child: Text('Ver más en stock.materialesya.com.ar',
                  style: GoogleFonts.poppins(color: const Color(0xFF8888AA), fontSize: 12)),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ── WIDGETS AUXILIARES ────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(20, 28, 20, 4),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
      const SizedBox(height: 16),
      child,
      const SizedBox(height: 8),
      const Divider(color: Color(0xFF2A2A4A), height: 32),
    ]),
  );
}

class _StatChip extends StatelessWidget {
  final String numero;
  final String label;
  const _StatChip({required this.numero, required this.label});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2A2A4A)),
      ),
      child: Column(children: [
        Text(numero, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w900, color: const Color(0xFFE8601C))),
        Text(label, style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF8888AA))),
      ]),
    ),
  );
}

class _Paso extends StatelessWidget {
  final String numero;
  final String titulo;
  final String desc;
  const _Paso({required this.numero, required this.titulo, required this.desc});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFFE8601C).withOpacity(0.15),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE8601C).withOpacity(0.5)),
        ),
        child: Center(child: Text(numero, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w900, color: const Color(0xFFE8601C)))),
      ),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(titulo, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
        const SizedBox(height: 3),
        Text(desc, style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFFAAAACC), height: 1.5)),
      ])),
    ]),
  );
}

class _Beneficio extends StatelessWidget {
  final String icon;
  final String titulo;
  final String desc;
  const _Beneficio({required this.icon, required this.titulo, required this.desc});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(icon, style: const TextStyle(fontSize: 22)),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(titulo, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
        const SizedBox(height: 3),
        Text(desc, style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFFAAAACC), height: 1.5)),
      ])),
    ]),
  );
}

class _PriceCard extends StatelessWidget {
  final String plan;
  final String precio;
  final String sub;
  final bool destacado;
  final bool full;
  final String? ahorro;
  final String? nota;
  const _PriceCard({required this.plan, required this.precio, required this.sub, required this.destacado, this.full = false, this.ahorro, this.nota});

  @override
  Widget build(BuildContext context) => Container(
    width: full ? double.infinity : null,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF1A1A2E),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: destacado ? const Color(0xFFE8601C) : const Color(0xFF2A2A4A), width: destacado ? 2 : 1),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (destacado) ...[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: const Color(0xFFE8601C), borderRadius: BorderRadius.circular(999)),
          child: Text('MÁS POPULAR', style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 1)),
        ),
        const SizedBox(height: 8),
      ],
      Text(plan, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF8888AA))),
      const SizedBox(height: 4),
      Text(precio, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w900, color: destacado ? const Color(0xFFE8601C) : Colors.white)),
      Text(sub, style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF8888AA))),
      if (ahorro != null) ...[
        const SizedBox(height: 4),
        Text(ahorro!, style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF27AE60), fontWeight: FontWeight.w700)),
      ],
      if (nota != null) ...[
        const SizedBox(height: 6),
        Text(nota!, style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFFAAAACC), height: 1.4)),
      ],
    ]),
  );
}
