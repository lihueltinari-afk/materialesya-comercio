import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme.dart';
import 'registro_screen.dart';
import 'main_screen.dart';

class LoginScreen extends StatefulWidget {
  final bool sesionExpirada;
  const LoginScreen({super.key, this.sesionExpirada = false});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _cargando = false;
  bool _verPass  = false;

  @override
  void initState() {
    super.initState();
    if (widget.sesionExpirada) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tu sesión expiró, ingresá de nuevo.'), backgroundColor: Colors.red),
        );
      });
    }
  }

  Future<void> _ingresar() async {
    final email = _emailCtrl.text.trim();
    final pass  = _passCtrl.text.trim();
    if (email.isEmpty || pass.isEmpty) return;
    setState(() => _cargando = true);
    final res = await ApiService.login(email, pass);
    setState(() => _cargando = false);
    if (!mounted) return;

    if (res['status'] == 200) {
      final data = res['data'];
      if (data['usuario']?['rol'] != 'comercio') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Esta app es solo para comercios.'), backgroundColor: Colors.red),
        );
        await ApiService.cerrarSesion();
        return;
      }
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainScreen()));
    } else {
      final msg = res['data']?['error'] ?? 'Error de conexión';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kFondo,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(children: [
            const SizedBox(height: 48),
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(color: kNaranja, borderRadius: BorderRadius.circular(20)),
              child: const Icon(Icons.store, size: 44, color: Colors.white),
            ),
            const SizedBox(height: 20),
            const Text('MaterialesYa', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: kAzul)),
            const Text('Panel del Comercio', style: TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 40),
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passCtrl,
              obscureText: !_verPass,
              onSubmitted: (_) => _ingresar(),
              decoration: InputDecoration(
                labelText: 'Contraseña',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_verPass ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _verPass = !_verPass),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _cargando ? null : _ingresar,
                child: _cargando
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Ingresar'),
              ),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegistroScreen())),
              child: const Text('¿No tenés cuenta? Registrá tu comercio', style: TextStyle(color: kAzul)),
            ),
          ]),
        ),
      ),
    );
  }
}
