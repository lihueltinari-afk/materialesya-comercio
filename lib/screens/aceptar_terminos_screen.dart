// Gate de primer uso: antes de poder usar la app (sea para registrarse o para entrar con una
// cuenta ya creada en otro dispositivo), hay que aceptar Términos y Privacidad una vez por
// instalación. Se guarda un flag en SharedPreferences para no volver a mostrarlo.
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../legal_texts.dart';
import 'legal_screen.dart';

const _amber = Color(0xFFE07B00);
const _textDark = Color(0xFF1A1A1A);
const String _kFlagTerminosAceptados = 'terminos_aceptados_v1';

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
  bool _acepta = false;

  Future<void> _continuar() async {
    if (!_acepta) return;
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
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 24),
            const Icon(Icons.handshake_outlined, size: 56, color: _amber),
            const SizedBox(height: 16),
            const Text('Antes de empezar', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: _textDark)),
            const SizedBox(height: 8),
            const Text('Para usar MaterialesYa Comercio necesitás aceptar nuestros Términos y la Política de Privacidad.',
              style: TextStyle(fontSize: 14, color: Colors.grey)),
            const Spacer(),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Checkbox(value: _acepta, onChanged: (v) => setState(() => _acepta = v ?? false), activeColor: _amber),
              Expanded(child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: RichText(text: TextSpan(
                  style: const TextStyle(fontSize: 13, color: _textDark),
                  children: [
                    const TextSpan(text: 'Leí y acepto los '),
                    TextSpan(text: 'Términos y condiciones', style: const TextStyle(color: _amber, fontWeight: FontWeight.w700),
                      recognizer: TapGestureRecognizer()..onTap = () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LegalScreen(titulo: 'Términos y condiciones', texto: terminosComercio)))),
                    const TextSpan(text: ' y la '),
                    TextSpan(text: 'Política de privacidad', style: const TextStyle(color: _amber, fontWeight: FontWeight.w700),
                      recognizer: TapGestureRecognizer()..onTap = () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LegalScreen(titulo: 'Política de privacidad', texto: politicaPrivacidad)))),
                  ],
                )),
              )),
            ]),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: _acepta ? _continuar : null,
                style: ElevatedButton.styleFrom(backgroundColor: _amber, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('Continuar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
