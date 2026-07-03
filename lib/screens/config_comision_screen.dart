import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../core/app_colors.dart';

const _navy = Color(0xFF1E3A5F);
const _dark = Color(0xFF1A1A1A);
const _grey = Color(0xFF888888);

class ConfigComisionScreen extends StatefulWidget {
  const ConfigComisionScreen({super.key});
  @override
  State<ConfigComisionScreen> createState() => _ConfigComisionScreenState();
}

class _ConfigComisionScreenState extends State<ConfigComisionScreen> {
  bool _cargando = true;
  bool _guardando = false;
  String _modo = 'absorber'; // 'absorber' | 'trasladar'
  bool _porProducto = false;
  bool _mostrarTooltip = false;
  static const double _pct = 10;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    // Verificar si es primera vez
    final prefs = await SharedPreferences.getInstance();
    final visto = prefs.getBool('comision_tooltip_visto') ?? false;

    final res = await ApiService.get('/comercio/config-comision');
    if (!mounted) return;
    if (res['status'] == 200) {
      final data = res['data'] as Map;
      setState(() {
        _modo = data['modo_comision_global'] as String? ?? 'absorber';
        _porProducto = data['comision_por_producto'] == true;
        _mostrarTooltip = !visto;
        _cargando = false;
      });
    } else {
      setState(() => _cargando = false);
    }
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    final res = await ApiService.put('/comercio/config-comision', {
      'modo_comision_global': _modo,
      'comision_por_producto': _porProducto,
    });
    if (!mounted) return;
    setState(() => _guardando = false);
    final ok = res['status'] == 200;
    final errorMsg = res['error'] ?? res['data']?['error'] ?? 'status ${res['status']}';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? 'Configuración guardada ✓' : 'Error al guardar: $errorMsg'),
      backgroundColor: ok ? AppColors.success : Colors.red,
      duration: const Duration(seconds: 6),
    ));
  }

  Future<void> _cerrarTooltip() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('comision_tooltip_visto', true);
    setState(() => _mostrarTooltip = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F8),
      appBar: AppBar(
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        title: Text('Precios y comisiones',
          style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700)),
        actions: [
          if (!_cargando)
            TextButton(
              onPressed: _guardando ? null : _guardar,
              child: _guardando
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text('Guardar', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
      body: _cargando
        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Tooltip primera vez
              if (_mostrarTooltip) _buildTooltip(),

              // Sección principal
              _buildSectionLabel('¿Cómo manejás la comisión de MaterialesYa (${_pct.toInt()}%)?'),
              const SizedBox(height: 8),

              _buildOpcion(
                titulo: 'Yo la absorbo',
                subtitulo: 'Tus precios son el precio final. La comisión sale de tu ganancia.',
                emoji: '💼',
                seleccionado: _modo == 'absorber',
                ejemplo: _buildEjemplo(absorber: true),
                onTap: () => setState(() => _modo = 'absorber'),
              ),
              const SizedBox(height: 10),
              _buildOpcion(
                titulo: 'La traslado al cliente',
                subtitulo: 'Al precio que cargás se le suma el ${_pct.toInt()}% automáticamente.',
                emoji: '🏷️',
                seleccionado: _modo == 'trasladar',
                ejemplo: _buildEjemplo(absorber: false),
                onTap: () => setState(() => _modo = 'trasladar'),
              ),

              const SizedBox(height: 24),

              // Opción avanzada: por producto
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Configuración avanzada',
                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: _dark)),
                  const SizedBox(height: 4),
                  Text('Podés aplicar configuraciones distintas producto por producto.',
                    style: GoogleFonts.poppins(fontSize: 11, color: _grey)),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Configurar por producto',
                        style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: _dark)),
                      Text(_porProducto
                        ? 'Cada producto tiene su propio toggle de comisión'
                        : 'Aplica la configuración global a todos los productos',
                        style: GoogleFonts.poppins(fontSize: 11, color: _grey)),
                    ])),
                    Switch(
                      value: _porProducto,
                      onChanged: (v) => setState(() => _porProducto = v),
                      activeColor: AppColors.primary,
                    ),
                  ]),
                ]),
              ),

              const SizedBox(height: 24),

              // Nota informativa
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _navy.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _navy.withOpacity(0.15)),
                ),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('ℹ️', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(
                    'Los precios que ven tus clientes nunca muestran el desglose de comisión. '
                    'Solo ven el precio final limpio.',
                    style: GoogleFonts.poppins(fontSize: 11, color: _navy),
                  )),
                ]),
              ),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  onPressed: _guardando ? null : _guardar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _guardando
                    ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    : Text('Guardar configuración',
                        style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildTooltip() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.primary.withOpacity(0.12), AppColors.primary.withOpacity(0.05)]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.4)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('💡', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Expanded(child: Text('Sobre la comisión de MaterialesYa',
            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w800, color: _dark))),
        ]),
        const SizedBox(height: 8),
        Text(
          'La plataforma cobra un ${_pct.toInt()}% de comisión por cada venta. '
          'Podés elegir si ese ${_pct.toInt()}% sale de tu ganancia o si lo sumás al precio que ve el cliente.\n\n'
          'La mayoría de los comercios lo trasladan al cliente para mantener sus márgenes.',
          style: GoogleFonts.poppins(fontSize: 12, color: _dark, height: 1.5),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _cerrarTooltip,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
            child: Text('Entendido, configurar ahora',
              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700)),
          ),
        ),
      ]),
    );
  }

  Widget _buildSectionLabel(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 4, left: 2),
    child: Text(label,
      style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: _grey)),
  );

  Widget _buildOpcion({
    required String titulo,
    required String subtitulo,
    required String emoji,
    required bool seleccionado,
    required Widget ejemplo,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: seleccionado ? AppColors.primary : Colors.grey.shade200,
            width: seleccionado ? 2 : 1,
          ),
          boxShadow: seleccionado
            ? [BoxShadow(color: AppColors.primary.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 2))]
            : [],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(titulo,
                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w800,
                  color: seleccionado ? AppColors.primary : _dark)),
              Text(subtitulo,
                style: GoogleFonts.poppins(fontSize: 11, color: _grey)),
            ])),
            Icon(seleccionado ? Icons.radio_button_checked : Icons.radio_button_off,
              color: seleccionado ? AppColors.primary : Colors.grey.shade300, size: 22),
          ]),
          const SizedBox(height: 12),
          ejemplo,
        ]),
      ),
    );
  }

  Widget _buildEjemplo({required bool absorber}) {
    final precioBase = 1000.0;
    final precioCliente = absorber ? precioBase : precioBase * (1 + _pct / 100);
    final comision = precioCliente * _pct / 100;
    final recibe = precioCliente - comision;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(children: [
        _filaCosto('Precio que cargás', '\$${_fmt(precioBase)}', _grey),
        _filaCosto('Precio que ve el cliente', '\$${_fmt(precioCliente)}',
          absorber ? _dark : AppColors.primary, bold: true),
        const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Divider(height: 1)),
        _filaCosto('Comisión MaterialesYa (${_pct.toInt()}%)', '-\$${_fmt(comision)}', Colors.red.shade400),
        _filaCosto('Vos recibís', '\$${_fmt(recibe)}',
          absorber ? Colors.red.shade600 : const Color(0xFF2E7D32), bold: true),
      ]),
    );
  }

  Widget _filaCosto(String label, String valor, Color color, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 11, color: _grey)),
        Text(valor, style: GoogleFonts.poppins(fontSize: 12,
          fontWeight: bold ? FontWeight.w800 : FontWeight.w600, color: color)),
      ]),
    );
  }

  String _fmt(double v) => v.toInt().toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
}
