// Pantalla de verificación de email. Se llega acá desde:
// - El registro (justo después de crear usuario + comercio)
// - El login (cuando el backend devuelve 403 email_no_verificado)
// - El splash (cuando el usuario tiene token pero email_verificado = false)
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'main_screen.dart';

const _amber = Color(0xFFE07B00);
const _textDark = Color(0xFF1A1A1A);

class VerificarEmailScreen extends StatefulWidget {
  final String email;
  const VerificarEmailScreen({super.key, required this.email});
  @override
  State<VerificarEmailScreen> createState() => _VerificarEmailScreenState();
}

class _VerificarEmailScreenState extends State<VerificarEmailScreen> {
  final _codigoCtrl = TextEditingController();
  bool _cargando = false;
  bool _reenviando = false;
  String? _error;
  String? _info;

  @override
  void dispose() {
    _codigoCtrl.dispose();
    super.dispose();
  }

  Future<void> _verificar() async {
    if (_codigoCtrl.text.trim().length != 6) {
      setState(() => _error = 'El código tiene 6 dígitos');
      return;
    }
    setState(() { _cargando = true; _error = null; });

    final res = await ApiService.post(
      '/auth/verificar-email',
      {'email': widget.email, 'codigo': _codigoCtrl.text.trim()},
    );
    if (!mounted) return;

    if (res['status'] == 200) {
      // Cargar el comercio del servidor antes de ir al panel
      // (puede que no esté en caché si el usuario volvió desde un login)
      await ApiService.miComercio();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
        (_) => false,
      );
    } else {
      setState(() {
        _cargando = false;
        _error = res['data']?['error'] ?? 'Código incorrecto';
      });
    }
  }

  Future<void> _reenviar() async {
    setState(() { _reenviando = true; _info = null; _error = null; });
    await ApiService.post('/auth/reenviar-verificacion', {'email': widget.email});
    if (!mounted) return;
    setState(() {
      _reenviando = false;
      _info = 'Te enviamos un código nuevo a ${widget.email}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 40),
            const Icon(Icons.mark_email_unread_outlined, size: 56, color: _amber),
            const SizedBox(height: 20),
            const Text(
              'Verificá tu email',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: _textDark),
            ),
            const SizedBox(height: 8),
            Text(
              'Te enviamos un código de 6 dígitos a ${widget.email}.\nIngresalo acá abajo para activar tu cuenta.',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 28),
            TextField(
              controller: _codigoCtrl,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 8),
              decoration: InputDecoration(
                counterText: '',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              onChanged: (v) { if (v.length == 6) _verificar(); },
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Row(children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 16),
                const SizedBox(width: 6),
                Expanded(child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13))),
              ]),
            ],
            if (_info != null) ...[
              const SizedBox(height: 12),
              Row(children: [
                const Icon(Icons.check_circle_outline, color: Colors.green, size: 16),
                const SizedBox(width: 6),
                Expanded(child: Text(_info!, style: const TextStyle(color: Colors.green, fontSize: 13))),
              ]),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: _cargando ? null : _verificar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _amber,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _cargando
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Verificar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: _reenviando ? null : _reenviar,
                child: Text(
                  _reenviando ? 'Enviando...' : 'No me llegó el código, reenviar',
                  style: const TextStyle(color: _amber),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.info_outline, color: _amber, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Si no ves el email, revisá la carpeta de spam. El código expira en 30 minutos.',
                    style: TextStyle(fontSize: 12, color: Colors.orange.shade900),
                  ),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
