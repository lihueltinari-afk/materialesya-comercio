import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'home_screen.dart';

const _amber = Color(0xFFE07B00);
const _bgPage = Color(0xFFF5F5F3);
const _textDark = Color(0xFF1A1A1A);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _verPass = false;
  bool _cargando = false;
  String? _error;

  Future<void> _login() async {
    if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
      setState(() => _error = 'Completá todos los campos');
      return;
    }
    setState(() { _cargando = true; _error = null; });
    try {
      final res = await ApiService.login(_emailCtrl.text.trim(), _passCtrl.text);
      if (res['status'] == 200) {
        final usuario = res['data']['usuario'];
        if (usuario['rol'] != 'comercio') {
          setState(() { _error = 'Esta app es solo para comercios'; _cargando = false; });
          return;
        }
        // Cargar y guardar el comercio_id
        final comercio = await ApiService.miComercio();
        if (!mounted) return;
        if (comercio == null) {
          setState(() { _error = 'No encontramos tu comercio registrado'; _cargando = false; });
          return;
        }
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
      } else {
        setState(() => _error = res['data']['error'] ?? 'Error al ingresar');
      }
    } catch (_) {
      setState(() => _error = 'No se pudo conectar al servidor');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgPage,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 40),
            Row(children: [
              Container(width: 44, height: 44, decoration: BoxDecoration(color: _amber, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.store, color: Colors.white, size: 24)),
              const SizedBox(width: 10),
              RichText(text: const TextSpan(
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: _textDark, letterSpacing: -0.5),
                children: [TextSpan(text: 'Materiales'), TextSpan(text: 'Ya', style: TextStyle(color: _amber)), TextSpan(text: ' Comercio')],
              )),
            ]),
            const SizedBox(height: 48),
            const Text('Ingresá a tu cuenta', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: _textDark, letterSpacing: -0.5)),
            const SizedBox(height: 4),
            const Text('Gestioná tu corralón desde acá', style: TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 32),
            const Text('Email', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _textDark)),
            const SizedBox(height: 6),
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'tucorreo@email.com',
                prefixIcon: const Icon(Icons.email_outlined),
                filled: true, fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Contraseña', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _textDark)),
            const SizedBox(height: 6),
            TextField(
              controller: _passCtrl,
              obscureText: !_verPass,
              decoration: InputDecoration(
                hintText: '••••••••',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(icon: Icon(_verPass ? Icons.visibility_off_outlined : Icons.visibility_outlined), onPressed: () => setState(() => _verPass = !_verPass)),
                filled: true, fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.shade200)),
                child: Text(_error!, style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: _cargando ? null : _login,
                style: ElevatedButton.styleFrom(backgroundColor: _amber, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: _cargando
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Ingresar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
