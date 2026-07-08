// Gate de primer uso: hay que desplazarse hasta el final antes de poder aceptar.
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/app_colors.dart';
import '../legal_texts.dart';
import 'legal_screen.dart';

const _textDark = Color(0xFF1A1A1A);
const String _kFlagTerminosAceptados = 'terminos_aceptados_v3';

Future<bool> terminosYaAceptados() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_kFlagTerminosAceptados) ?? false;
}

class AceptarTerminosScreen extends StatefulWidget {
  final Widget destino;
  const AceptarTerminosScreen({super.key, required this.destino});
  @override
  State<AceptarTerminosScreen> createState() => _AceptarTerminosScreenState();
}

class _AceptarTerminosScreenState extends State<AceptarTerminosScreen> {
  final ScrollController _scroll = ScrollController();
  bool _llegueFinal = false;
  bool _acepta = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 60) {
      if (!_llegueFinal) setState(() => _llegueFinal = true);
    }
  }

  Future<void> _continuar() async {
    if (!_acepta || !_llegueFinal) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kFlagTerminosAceptados, true);
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => widget.destino));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.handshake_outlined, size: 48, color: AppColors.primary),
              const SizedBox(height: 12),
              const Text('Antes de empezar',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: _textDark)),
              const SizedBox(height: 6),
              const Text('Leé los Términos y condiciones completos. Podés aceptar cuando llegues al final.',
                style: TextStyle(fontSize: 13, color: Colors.grey)),
              if (!_llegueFinal) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(children: [
                    Icon(Icons.arrow_downward, size: 14, color: AppColors.primary),
                    SizedBox(width: 6),
                    Text('Desplazate hasta el final para continuar',
                      style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ],
            ]),
          ),
          Expanded(
            child: Container(
              color: Colors.white,
              margin: const EdgeInsets.only(top: 1),
              child: Scrollbar(
                controller: _scroll,
                child: SingleChildScrollView(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(terminosComercio,
                      style: const TextStyle(fontSize: 13, color: _textDark, height: 1.55)),
                    const Divider(height: 32),
                    Text(politicaPrivacidadComercio,
                      style: const TextStyle(fontSize: 13, color: _textDark, height: 1.55)),
                    const SizedBox(height: 40),
                    Center(child: Column(children: [
                      Icon(Icons.check_circle_outline,
                        color: _llegueFinal ? Colors.green : Colors.grey.shade300, size: 36),
                      const SizedBox(height: 8),
                      Text(_llegueFinal ? '¡Llegaste al final!' : 'Seguí leyendo...',
                        style: TextStyle(
                          fontSize: 13,
                          color: _llegueFinal ? Colors.green : Colors.grey,
                          fontWeight: FontWeight.w600,
                        )),
                    ])),
                    const SizedBox(height: 20),
                  ]),
                ),
              ),
            ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
            ),
            child: Column(children: [
              Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                Checkbox(
                  value: _acepta,
                  onChanged: _llegueFinal ? (v) => setState(() => _acepta = v ?? false) : null,
                  activeColor: AppColors.primary,
                ),
                Expanded(child: RichText(text: TextSpan(
                  style: TextStyle(fontSize: 13, color: _llegueFinal ? _textDark : Colors.grey),
                  children: [
                    const TextSpan(text: 'Leí y acepto los '),
                    TextSpan(
                      text: 'Términos y condiciones',
                      style: TextStyle(
                        color: _llegueFinal ? AppColors.primary : Colors.grey,
                        fontWeight: FontWeight.w700,
                      ),
                      recognizer: TapGestureRecognizer()..onTap = () => Navigator.push(
                        context, MaterialPageRoute(builder: (_) => const LegalScreen(
                          titulo: 'Términos y condiciones', texto: terminosComercio))),
                    ),
                    const TextSpan(text: ' y la '),
                    TextSpan(
                      text: 'Política de privacidad',
                      style: TextStyle(
                        color: _llegueFinal ? AppColors.primary : Colors.grey,
                        fontWeight: FontWeight.w700,
                      ),
                      recognizer: TapGestureRecognizer()..onTap = () => Navigator.push(
                        context, MaterialPageRoute(builder: (_) => const LegalScreen(
                          titulo: 'Política de privacidad', texto: politicaPrivacidadComercio))),
                    ),
                  ],
                ))),
              ]),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton(
                  onPressed: (_acepta && _llegueFinal) ? _continuar : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade200,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Acepto y continúo',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}
