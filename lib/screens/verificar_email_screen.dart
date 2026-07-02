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
  bool _cambiandoEmail = false;
  String? _error;
  String? _info;
  late String _emailActual;

  @override
  void initState() {
    super.initState();
    _emailActual = widget.email;
  }

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
      {'email': _emailActual, 'codigo': _codigoCtrl.text.trim()},
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
    await ApiService.post('/auth/reenviar-verificacion', {'email': _emailActual});
    if (!mounted) return;
    setState(() {
      _reenviando = false;
      _info = 'Te enviamos un código nuevo a $_emailActual';
    });
  }

  Future<void> _mostrarDialogoModificarEmail() async {
    final nuevoEmailCtrl = TextEditingController();
    String? errorLocal;

    await showDialog(
      context: context,
      barrierDismissible: !_cambiandoEmail,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Modificar email', style: TextStyle(fontWeight: FontWeight.w800)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Email actual: $_emailActual', style: const TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 16),
            TextField(
              controller: nuevoEmailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Nuevo email',
                hintText: 'ejemplo@gmail.com',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                errorText: errorLocal,
              ),
            ),
            const SizedBox(height: 8),
            const Text('Te enviaremos un nuevo código de verificación al email nuevo.', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ]),
          actions: [
            TextButton(
              onPressed: _cambiandoEmail ? null : () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _amber, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: _cambiandoEmail ? null : () async {
                final nuevo = nuevoEmailCtrl.text.trim();
                if (nuevo.isEmpty || !nuevo.contains('@')) {
                  setStateDialog(() => errorLocal = 'Email inválido');
                  return;
                }
                setStateDialog(() { _cambiandoEmail = true; errorLocal = null; });
                final res = await ApiService.post('/auth/cambiar-email', {'email_actual': _emailActual, 'email_nuevo': nuevo});
                if (!ctx.mounted) return;
                if (res['status'] == 200) {
                  Navigator.pop(ctx);
                  setState(() {
                    _emailActual = nuevo;
                    _codigoCtrl.clear();
                    _error = null;
                    _info = '✓ Email actualizado. Te enviamos el código a $nuevo';
                    _cambiandoEmail = false;
                  });
                } else {
                  setStateDialog(() {
                    errorLocal = res['data']?['error'] ?? 'Error al cambiar email';
                    _cambiandoEmail = false;
                  });
                }
              },
              child: _cambiandoEmail
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Cambiar y reenviar'),
            ),
          ],
        ),
      ),
    );
    setState(() => _cambiandoEmail = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: Navigator.canPop(context)
        ? AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: _textDark),
              onPressed: () => Navigator.pop(context),
              tooltip: 'Volver a editar datos',
            ),
          )
        : null,
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
              'Te enviamos un código de 6 dígitos a $_emailActual.\nIngresalo acá abajo para activar tu cuenta.',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: _mostrarDialogoModificarEmail,
              child: Row(children: [
                const Icon(Icons.edit_outlined, size: 14, color: _amber),
                const SizedBox(width: 4),
                const Text('¿Email incorrecto? Modificar', style: TextStyle(fontSize: 13, color: _amber, fontWeight: FontWeight.w600)),
              ]),
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
