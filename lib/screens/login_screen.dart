import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_colors.dart';
import '../services/api_service.dart';
import '../services/google_auth_service.dart';
import '../theme.dart';
import 'registro_screen.dart';
import 'main_screen.dart';
import 'verificar_email_screen.dart';

class LoginScreen extends StatefulWidget {
  final bool sesionExpirada;
  const LoginScreen({super.key, this.sesionExpirada = false});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController(text: 'comercio@demo.com');
  final _passCtrl  = TextEditingController(text: 'demo123');
  bool _cargando = false;
  bool _cargandoGoogle = false;
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

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _loginConGoogle() async {
    setState(() { _cargandoGoogle = true; });
    try {
      final data = await GoogleAuthService.signIn(rol: 'comercio');
      if (data == null) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo iniciar sesión con Google'), backgroundColor: Colors.red),
        );
        return;
      }
      if (data['usuario']?['rol'] != 'comercio') {
        await ApiService.cerrarSesion();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Esta app es solo para comercios.'), backgroundColor: Colors.red),
        );
        return;
      }
      await ApiService.guardarSesion(data['token'], data['usuario']);
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainScreen()));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error Google: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _cargandoGoogle = false);
    }
  }

  Future<void> _ingresar() async {
    final email = _emailCtrl.text.trim();
    final pass  = _passCtrl.text.trim();
    if (email.isEmpty || pass.isEmpty) return;
    setState(() => _cargando = true);

    final res = await ApiService.login(email, pass);
    if (!mounted) return;
    setState(() => _cargando = false);

    if (res['status'] == 200) {
      final data = res['data'];
      if (data['usuario']?['rol'] != 'comercio') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Esta app es solo para comercios.'), backgroundColor: Colors.red),
        );
        await ApiService.cerrarSesion();
        return;
      }
      await ApiService.miComercio();
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainScreen()));

    } else if (res['status'] == 403 && res['data']?['error'] == 'email_no_verificado') {
      final emailNoVerificado = res['data']?['email'] as String? ?? email;
      await ApiService.guardarEmailUsuario(emailNoVerificado);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verificá tu email para poder ingresar'), backgroundColor: Colors.orange, duration: Duration(seconds: 3)),
      );
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => VerificarEmailScreen(email: emailNoVerificado)));

    } else {
      final msg = res['data']?['error'] ?? 'Error de conexión';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(children: [
            const SizedBox(height: 48),
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(20)),
              child: const Icon(Icons.store, size: 44, color: Colors.white),
            ),
            const SizedBox(height: 20),
            const Text('MaterialesYa', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.secondary)),
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
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const _RecuperarPasswordScreen())),
                child: const Text('¿Olvidaste tu contraseña?', style: TextStyle(color: AppColors.secondary, fontSize: 13)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _cargando ? null : _ingresar,
                child: _cargando
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Ingresar'),
              ),
            ),
            const SizedBox(height: 12),
            Row(children: [
              const Expanded(child: Divider()),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('o', style: TextStyle(color: Colors.grey.shade500, fontSize: 13))),
              const Expanded(child: Divider()),
            ]),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _cargandoGoogle ? null : _loginConGoogle,
                icon: _cargandoGoogle
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.g_mobiledata, size: 22),
                label: const Text('Continuar con Google'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  side: const BorderSide(color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegistroScreen())),
              child: const Text('¿No tenés cuenta? Registrá tu comercio', style: TextStyle(color: AppColors.secondary)),
            ),
          ]),
        ),
      ),
    );
  }
}

// ─── RECUPERAR CONTRASEÑA ─────────────────────────────────────────────────────

class _RecuperarPasswordScreen extends StatefulWidget {
  const _RecuperarPasswordScreen();
  @override
  State<_RecuperarPasswordScreen> createState() => _RecuperarPasswordScreenState();
}

class _RecuperarPasswordScreenState extends State<_RecuperarPasswordScreen> {
  // Paso 1: pedir email → envía código
  // Paso 2: ingresar código + nueva contraseña
  int _paso = 0;
  final _emailCtrl   = TextEditingController();
  final _codigoCtrl  = TextEditingController();
  final _nuevaPassCtrl = TextEditingController();
  bool _cargando = false;
  bool _verPass  = false;
  String? _error;
  String? _exito;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _codigoCtrl.dispose();
    _nuevaPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _enviarCodigo() async {
    if (_emailCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Ingresá tu email');
      return;
    }
    setState(() { _cargando = true; _error = null; });
    final res = await ApiService.post('/auth/recuperar-password', {'email': _emailCtrl.text.trim()});
    if (!mounted) return;
    setState(() {
      _cargando = false;
      if (res['status'] == 200) _paso = 1;
      else _error = 'No se pudo enviar el email. Intentá de nuevo.';
    });
  }

  Future<void> _cambiarPassword() async {
    if (_codigoCtrl.text.trim().length != 6) {
      setState(() => _error = 'El código tiene 6 dígitos');
      return;
    }
    if (_nuevaPassCtrl.text.length < 6) {
      setState(() => _error = 'La contraseña debe tener al menos 6 caracteres');
      return;
    }
    setState(() { _cargando = true; _error = null; });
    final res = await ApiService.post('/auth/cambiar-password', {
      'email': _emailCtrl.text.trim(),
      'codigo': _codigoCtrl.text.trim(),
      'nuevaPassword': _nuevaPassCtrl.text,
    });
    if (!mounted) return;
    setState(() {
      _cargando = false;
      if (res['status'] == 200) _exito = '¡Contraseña actualizada! Ya podés iniciar sesión.';
      else _error = res['data']?['error'] ?? 'Código incorrecto o expirado';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Recuperar contraseña'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: _exito != null ? _PantallaExito(mensaje: _exito!, onVolver: () => Navigator.pop(context)) :
               _paso == 0 ? _buildPaso1() : _buildPaso2(),
      ),
    );
  }

  Widget _buildPaso1() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 16),
      const Icon(Icons.lock_reset, size: 48, color: AppColors.primary),
      const SizedBox(height: 16),
      const Text('Recuperar contraseña', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.secondary)),
      const SizedBox(height: 8),
      const Text('Ingresá el email de tu comercio y te enviamos un código para restablecer la contraseña.',
        style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.5)),
      const SizedBox(height: 28),
      TextField(
        controller: _emailCtrl,
        keyboardType: TextInputType.emailAddress,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Email de tu cuenta', prefixIcon: Icon(Icons.email_outlined), border: OutlineInputBorder()),
      ),
      if (_error != null) ...[
        const SizedBox(height: 12),
        Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
      ],
      const SizedBox(height: 24),
      SizedBox(
        width: double.infinity, height: 50,
        child: ElevatedButton(
          onPressed: _cargando ? null : _enviarCodigo,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
          child: _cargando
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Text('Enviar código', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ),
      ),
    ]);
  }

  Widget _buildPaso2() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 16),
      const Icon(Icons.mark_email_read_outlined, size: 48, color: AppColors.primary),
      const SizedBox(height: 16),
      const Text('Revisá tu email', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.secondary)),
      const SizedBox(height: 8),
      Text('Enviamos un código de 6 dígitos a ${_emailCtrl.text.trim()}. Ingresalo abajo junto con tu nueva contraseña.',
        style: const TextStyle(fontSize: 14, color: Colors.grey, height: 1.5)),
      const SizedBox(height: 28),
      TextField(
        controller: _codigoCtrl,
        keyboardType: TextInputType.number,
        maxLength: 6,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 8),
        decoration: InputDecoration(
          counterText: '',
          labelText: 'Código de 6 dígitos',
          border: const OutlineInputBorder(),
          filled: true, fillColor: Colors.white,
        ),
      ),
      const SizedBox(height: 16),
      TextField(
        controller: _nuevaPassCtrl,
        obscureText: !_verPass,
        decoration: InputDecoration(
          labelText: 'Nueva contraseña',
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.lock_outline),
          suffixIcon: IconButton(
            icon: Icon(_verPass ? Icons.visibility_off : Icons.visibility),
            onPressed: () => setState(() => _verPass = !_verPass),
          ),
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
        width: double.infinity, height: 50,
        child: ElevatedButton(
          onPressed: _cargando ? null : _cambiarPassword,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
          child: _cargando
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Text('Cambiar contraseña', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ),
      ),
      const SizedBox(height: 12),
      Center(
        child: TextButton(
          onPressed: _cargando ? null : _enviarCodigo,
          child: const Text('Reenviar código', style: TextStyle(color: AppColors.secondary)),
        ),
      ),
    ]);
  }
}

class _PantallaExito extends StatelessWidget {
  final String mensaje;
  final VoidCallback onVolver;
  const _PantallaExito({required this.mensaje, required this.onVolver});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const SizedBox(height: 60),
        Container(
          width: 90, height: 90,
          decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
          child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 54),
        ),
        const SizedBox(height: 24),
        Text(mensaje, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: Colors.black87, height: 1.5)),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity, height: 50,
          child: ElevatedButton(
            onPressed: onVolver,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: const Text('Ir al inicio de sesión', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ),
      ]),
    );
  }
}


