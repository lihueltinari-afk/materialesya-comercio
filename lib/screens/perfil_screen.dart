import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../soporte.dart';
import '../legal_texts.dart';
import 'login_screen.dart';
import 'legal_screen.dart';
import 'mapa_confirmar_ubicacion_screen.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> with WidgetsBindingObserver {
  Map<String, dynamic>? _comercio;
  bool _cargando = true;
  bool _guardando = false;
  bool? _mpConectado;
  bool _conectandoMp = false;

  final _nombreCtrl = TextEditingController();
  int _tiempoEntrega = 60;
  final _direccionCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _cbuCtrl = TextEditingController();
  final _cuitCtrl = TextEditingController();
  double _radioEntrega = 5;
  bool _repartoPropio = false;
  double? _lat;
  double? _lng;
  String? _logoUrl;
  String? _bannerUrl;
  bool _subiendoImagen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cargarPerfil();
    _cargarEstadoMp();
  }

  // Cuando el comercio vuelve a la app después de autorizar en la pestaña de Mercado Pago
  // (resumed), reconsultamos el estado para que el "Conectado" aparezca solo, sin que tenga
  // que salir y volver a entrar a Perfil a mano.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _mpConectado != true) {
      _cargarEstadoMp();
    }
  }

  Future<void> _cargarEstadoMp() async {
    final res = await ApiService.get('/comercio/mercadopago/estado');
    if (mounted && res['status'] == 200) setState(() => _mpConectado = res['data']?['conectado'] == true);
  }

  Future<void> _conectarMercadoPago() async {
    setState(() => _conectandoMp = true);
    final res = await ApiService.get('/comercio/mercadopago/conectar');
    if (!mounted) return;
    setState(() => _conectandoMp = false);
    final url = res['data']?['url'];
    if (res['status'] == 200 && url != null) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Completá la autorización en la pestaña que se abrió y volvé acá'),
        ));
      }
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo iniciar la conexión con Mercado Pago'), backgroundColor: Colors.red));
    }
  }

  Future<void> _cambiarImagen(bool esLogo) async {
    final picker = ImagePicker();
    final archivo = await picker.pickImage(source: ImageSource.gallery, maxWidth: esLogo ? 400 : 1200, imageQuality: 80);
    if (archivo == null) return;
    setState(() => _subiendoImagen = true);
    try {
      final bytes = await archivo.readAsBytes();
      final base64Str = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      final res = await ApiService.post('/upload', {'imagen': base64Str, 'carpeta': 'comercios'});
      if (!mounted) return;
      final url = res['data']?['url'] as String?;
      if (res['status'] == 200 && url != null) {
        final ok = await ApiService.actualizarComercio({esLogo ? 'logo_url' : 'banner_url': url});
        if (!mounted) return;
        setState(() {
          _subiendoImagen = false;
          if (ok) { if (esLogo) _logoUrl = url; else _bannerUrl = url; }
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ok ? '${esLogo ? 'Logo' : 'Banner'} actualizado ✓' : 'Error al guardar la imagen'),
          backgroundColor: ok ? Colors.green : Colors.red,
        ));
      } else {
        setState(() => _subiendoImagen = false);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No se pudo subir la imagen. Verificá la conexión.'),
          backgroundColor: Colors.red,
        ));
      }
    } catch (_) {
      if (mounted) setState(() => _subiendoImagen = false);
    }
  }

  ImageProvider _imagenDesde(String url) {
    if (url.startsWith('data:')) {
      return MemoryImage(base64Decode(url.split(',').last));
    }
    return NetworkImage(url);
  }

  Widget _botonCambiarFoto(VoidCallback onTap, {bool pequeno = false}) {
    return GestureDetector(
      onTap: _subiendoImagen ? null : onTap,
      child: Container(
        width: pequeno ? 24 : 32, height: pequeno ? 24 : 32,
        decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
        child: _subiendoImagen
          ? const Padding(padding: EdgeInsets.all(4), child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : Icon(Icons.camera_alt, color: Colors.white, size: pequeno ? 13 : 16),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
          _lat = double.tryParse(comercio['lat']?.toString() ?? '');
          _lng = double.tryParse(comercio['lng']?.toString() ?? '');
          _logoUrl = comercio['logo_url'];
          _bannerUrl = comercio['banner_url'];
          _repartoPropio = comercio['reparto_propio'] == true;
          _tiempoEntrega = int.tryParse(comercio['tiempo_entrega_estimado']?.toString() ?? '60') ?? 60;
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

  bool _cuitValido(String cuit) {
    final nums = cuit.replaceAll(RegExp(r'[-\s]'), '');
    if (nums.length != 11 || !RegExp(r'^\d{11}$').hasMatch(nums)) return false;
    const prefijos = ['20', '23', '24', '27', '30', '33', '34'];
    if (!prefijos.contains(nums.substring(0, 2))) return false;
    const mults = [5, 4, 3, 2, 7, 6, 5, 4, 3, 2];
    var suma = 0;
    for (var i = 0; i < mults.length; i++) { suma += mults[i] * int.parse(nums[i]); }
    final resto = suma % 11;
    final v = resto == 0 ? 0 : resto == 1 ? 9 : 11 - resto;
    return v == int.parse(nums[10]);
  }

  Future<void> _guardar() async {
    if (_nombreCtrl.text.trim().isEmpty) {
      _mostrarError('El nombre del comercio no puede estar vacío');
      return;
    }
    final cuit = _cuitCtrl.text.trim();
    if (cuit.isNotEmpty && !_cuitValido(cuit)) {
      _mostrarError('El CUIT ingresado no es válido. Verificá los 11 dígitos y el dígito verificador.');
      return;
    }

    setState(() => _guardando = true);

    final ok = await ApiService.actualizarComercio({
      'nombre': _nombreCtrl.text.trim(),
      'direccion': _direccionCtrl.text.trim(),
      'lat': _lat,
      'lng': _lng,
      'telefono': _telefonoCtrl.text.trim(),
      'cbu_alias': _cbuCtrl.text.trim(),
      'cuit': _cuitCtrl.text.trim(),
      'radio_entrega_km': _radioEntrega.round(),
      'reparto_propio': _repartoPropio,
      'tiempo_entrega_estimado': _tiempoEntrega,
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
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mi perfil'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
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
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.secondary),
                        ),
                        const SizedBox(height: 12),
                        // Banner
                        Stack(alignment: Alignment.center, children: [
                          Container(
                            width: double.infinity, height: 100,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10),
                              image: _bannerUrl != null && _bannerUrl!.isNotEmpty
                                ? DecorationImage(image: _imagenDesde(_bannerUrl!), fit: BoxFit.cover) : null,
                            ),
                            child: _bannerUrl == null || _bannerUrl!.isEmpty ? const Icon(Icons.image_outlined, color: Colors.grey, size: 32) : null,
                          ),
                          Positioned(bottom: 6, right: 6, child: _botonCambiarFoto(() => _cambiarImagen(false))),
                        ]),
                        const SizedBox(height: 10),
                        // Logo
                        Row(children: [
                          Stack(alignment: Alignment.center, children: [
                            CircleAvatar(
                              radius: 30, backgroundColor: Colors.grey.shade100,
                              backgroundImage: _logoUrl != null && _logoUrl!.isNotEmpty ? _imagenDesde(_logoUrl!) : null,
                              child: _logoUrl == null || _logoUrl!.isEmpty ? const Icon(Icons.store, color: Colors.grey) : null,
                            ),
                            Positioned(bottom: -2, right: -2, child: _botonCambiarFoto(() => _cambiarImagen(true), pequeno: true)),
                          ]),
                          const SizedBox(width: 12),
                          const Expanded(child: Text('Tocá el ícono de la cámara para cambiar el logo o el banner de tu local.', style: TextStyle(fontSize: 12, color: Colors.grey))),
                        ]),
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
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: () async {
                            final resultado = await Navigator.push<Map<String, dynamic>>(context, MaterialPageRoute(
                              builder: (_) => MapaConfirmarUbicacionScreen(
                                direccionInicial: _direccionCtrl.text.trim(),
                                latInicial: _lat, lngInicial: _lng,
                              ),
                            ));
                            if (resultado == null || !mounted) return;
                            setState(() {
                              _lat = resultado['lat'];
                              _lng = resultado['lng'];
                              if ((resultado['direccion'] as String).isNotEmpty) _direccionCtrl.text = resultado['direccion'];
                            });
                          },
                          icon: Icon(_lat != null ? Icons.check_circle : Icons.map_outlined, color: _lat != null ? Colors.green : AppColors.primary),
                          label: Text(_lat != null ? 'Ubicación confirmada en el mapa ✓ (tocá para ajustar)' : 'Confirmar ubicación en el mapa',
                            style: TextStyle(color: _lat != null ? Colors.green : AppColors.primary)),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: _lat != null ? Colors.green : AppColors.primary),
                            minimumSize: const Size.fromHeight(44),
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
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                          ],
                        ),
                        Slider(
                          value: _radioEntrega,
                          min: 2,
                          max: 30,
                          divisions: 28,
                          activeColor: AppColors.primary,
                          label: '${_radioEntrega.round()} km',
                          onChanged: (v) => setState(() => _radioEntrega = v),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Tiempo de entrega estimado:', style: TextStyle(fontWeight: FontWeight.w600)),
                            Text(
                              _tiempoEntrega < 60
                                  ? '$_tiempoEntrega min'
                                  : _tiempoEntrega == 60 ? '1 hora'
                                  : '${(_tiempoEntrega / 60).toStringAsFixed(1).replaceAll('.0', '')} hs',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                          ],
                        ),
                        Slider(
                          value: _tiempoEntrega.toDouble(),
                          min: 15,
                          max: 180,
                          divisions: 11,
                          activeColor: AppColors.primary,
                          label: '$_tiempoEntrega min',
                          onChanged: (v) => setState(() => _tiempoEntrega = v.round()),
                        ),
                        const SizedBox(height: 8),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _repartoPropio,
                          activeColor: AppColors.primary,
                          title: const Text('Reparto propio', style: TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: const Text(
                            'Si lo activás, tus pedidos no aparecen para los repartidores de MaterialesYa: '
                            'vos mismo los marcás como "en camino" y "entregado" desde la pantalla de pedidos.',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          onChanged: (v) async {
                            if (v) {
                              // Al activar reparto propio: pedir confirmación sobre el cobro
                              final confirmo = await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('Confirmar reparto propio'),
                                  content: const Text(
                                    'Al activar el reparto propio, el costo de envío que '
                                    'se cobra al cliente se acredita en la misma cuenta '
                                    'de Mercado Pago donde recibís el pago del producto.\n\n'
                                    '¿Confirmás que entendés y aceptás esta condición?',
                                  ),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                                      child: const Text('Sí, acepto'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmo == true) setState(() => _repartoPropio = true);
                            } else {
                              setState(() => _repartoPropio = false);
                            }
                          },
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _guardando ? null : _guardar,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
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
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.secondary),
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

                // Cobros con Mercado Pago
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Cobros con Mercado Pago', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.secondary)),
                      const SizedBox(height: 8),
                      if (_mpConectado == true) ...[
                        const Row(children: [
                          Icon(Icons.check_circle, color: Colors.green, size: 18),
                          SizedBox(width: 8),
                          Expanded(child: Text('Cuenta conectada. Tus ventas se depositan directo en tu Mercado Pago (se descuenta la comisión de la plataforma automáticamente).', style: TextStyle(fontSize: 13))),
                        ]),
                      ] else ...[
                        const Text('Conectá tu cuenta de Mercado Pago para que el dinero de cada venta te llegue directo, sin esperar una transferencia manual.',
                          style: TextStyle(fontSize: 13, color: Colors.grey)),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _conectandoMp ? null : _conectarMercadoPago,
                            icon: const Icon(Icons.account_balance_wallet_outlined),
                            label: Text(_conectandoMp ? 'Abriendo...' : 'Conectar con Mercado Pago'),
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF009EE3), foregroundColor: Colors.white, minimumSize: const Size.fromHeight(46)),
                          ),
                        ),
                      ],
                    ]),
                  ),
                ),
                const SizedBox(height: 16),

                // Ayuda y legales
                Card(
                  child: Column(children: [
                    ListTile(
                      leading: const Icon(Icons.support_agent_outlined, color: AppColors.primary),
                      title: const Text('Ayuda / Soporte'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => abrirSoporteWhatsApp(),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.description_outlined, color: AppColors.primary),
                      title: const Text('Términos y condiciones'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LegalScreen(titulo: 'Términos y condiciones', texto: terminosComercio))),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.privacy_tip_outlined, color: AppColors.primary),
                      title: const Text('Política de privacidad'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LegalScreen(titulo: 'Política de privacidad', texto: politicaPrivacidad))),
                    ),
                  ]),
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



