import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme.dart';
import 'login_screen.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  Map<String, dynamic>? _comercio;
  bool _cargando = true;
  bool _guardando = false;

  final _nombreCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _cbuCtrl = TextEditingController();
  final _cuitCtrl = TextEditingController();
  double _radioEntrega = 5;

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _direccionCtrl.dispose();
    _telefonoCtrl.dispose();
    _cbuCtrl.dispose();
    _cuitCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarPerfil() async {
    try {
      final comercio = await ApiService.miComercio();
      if (!mounted) return;
      if (comercio != null) {
        setState(() {
          _comercio = comercio;
          _nombreCtrl.text = comercio['nombre'] ?? '';
          _direccionCtrl.text = comercio['direccion'] ?? '';
          _telefonoCtrl.text = comercio['telefono'] ?? '';
          _cbuCtrl.text = comercio['cbu_alias'] ?? '';
          _cuitCtrl.text = comercio['cuit'] ?? '';
          final radio = comercio['radio_entrega_km'];
          if (radio != null) {
            _radioEntrega = double.tryParse(radio.toString()) ?? 5;
            if (_radioEntrega < 2) _radioEntrega = 2;
            if (_radioEntrega > 30) _radioEntrega = 30;
          }
          _cargando = false;
        });
      } else {
        setState(() => _cargando = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _cargando = false);
    }
  }

  Future<void> _guardar() async {
    if (_nombreCtrl.text.trim().isEmpty) {
      _mostrarError('El nombre del comercio no puede estar vacío');
      return;
    }

    setState(() => _guardando = true);

    final ok = await ApiService.actualizarComercio({
      'nombre': _nombreCtrl.text.trim(),
      'direccion': _direccionCtrl.text.trim(),
      'telefono': _telefonoCtrl.text.trim(),
      'cbu_alias': _cbuCtrl.text.trim(),
      'cuit': _cuitCtrl.text.trim(),
      'radio_entrega_km': _radioEntrega.round(),
    });

    if (!mounted) return;
    setState(() => _guardando = false);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil actualizado correctamente'), backgroundColor: Colors.green),
      );
    } else {
      _mostrarError('Error al guardar los cambios');
    }
  }

  void _mostrarError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  Future<void> _cambiarPassword() async {
    final passActualCtrl = TextEditingController();
    final passNuevaCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cambiar contraseña'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: passActualCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Contraseña actual',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passNuevaCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Nueva contraseña',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (passNuevaCtrl.text.length < 6) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('La nueva contraseña debe tener al menos 6 caracteres'), backgroundColor: Colors.red),
                );
                return;
              }
              Navigator.of(ctx).pop();
              final res = await ApiService.patch('/auth/cambiar-password', {
                'password_actual': passActualCtrl.text,
                'password_nueva': passNuevaCtrl.text,
              });
              if (!context.mounted) return;
              if (res['status'] == 200) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Contraseña actualizada'), backgroundColor: Colors.green),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Error al cambiar la contraseña'), backgroundColor: Colors.red),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: kNaranja, foregroundColor: Colors.white),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _cerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que querés cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    await ApiService.cerrarSesion();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kFondo,
      appBar: AppBar(
        title: const Text('Mi perfil'),
        backgroundColor: kNaranja,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: kNaranja))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Datos del comercio
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Datos del comercio',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kAzul),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _nombreCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Nombre del comercio',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.store),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _direccionCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Dirección',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.location_on),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _telefonoCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Teléfono',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.phone),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _cuitCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'CUIT',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.badge),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _cbuCtrl,
                          decoration: const InputDecoration(
                            labelText: 'CBU o Alias',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.account_balance),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Radio de entrega:', style: TextStyle(fontWeight: FontWeight.w600)),
                            Text(
                              '${_radioEntrega.round()} km',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: kNaranja),
                            ),
                          ],
                        ),
                        Slider(
                          value: _radioEntrega,
                          min: 2,
                          max: 30,
                          divisions: 28,
                          activeColor: kNaranja,
                          label: '${_radioEntrega.round()} km',
                          onChanged: (v) => setState(() => _radioEntrega = v),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _guardando ? null : _guardar,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kNaranja,
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(48),
                            ),
                            child: _guardando
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Text('Guardar cambios'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Mi cuenta
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Mi cuenta',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kAzul),
                        ),
                        const SizedBox(height: 12),
                        if (_comercio?['email'] != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.email, color: Colors.grey, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _comercio!['email'].toString(),
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                ),
                                const Text('(solo lectura)', style: TextStyle(fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        OutlinedButton.icon(
                          onPressed: _cambiarPassword,
                          icon: const Icon(Icons.lock_outline),
                          label: const Text('Cambiar contraseña'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(44),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Cerrar sesión
                OutlinedButton.icon(
                  onPressed: _cerrarSesion,
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text('Cerrar sesión', style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    minimumSize: const Size.fromHeight(50),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
    );
  }
}
