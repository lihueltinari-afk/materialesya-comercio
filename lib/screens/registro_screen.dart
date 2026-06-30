import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../legal_texts.dart';
import 'verificar_email_screen.dart';
import 'legal_screen.dart';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  int _currentStep = 0;
  bool _cargando = false;

  // Paso 1
  final _nombreNegocioCtrl = TextEditingController();
  String? _tipoSeleccionado;
  final _cuitCtrl = TextEditingController();

  // Paso 2
  final _direccionCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  double _radioEntrega = 5;
  final _cbuCtrl = TextEditingController();

  // Paso 3
  final _nombrePropietarioCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _verPassword = false;
  bool _aceptaTerminos = false;

  final List<String> _tipos = [
    'corralon',
    'ferreteria',
    'pintureria',
    'plomeria',
    'electricidad',
    'sanitarios',
    'vidrieria',
  ];

  final Map<String, String> _tiposLabel = {
    'corralon': 'Corralón',
    'ferreteria': 'Ferretería',
    'pintureria': 'Pinturería',
    'plomeria': 'Plomería',
    'electricidad': 'Electricidad',
    'sanitarios': 'Sanitarios',
    'vidrieria': 'Vidriería',
  };

  @override
  void dispose() {
    _nombreNegocioCtrl.dispose();
    _cuitCtrl.dispose();
    _direccionCtrl.dispose();
    _telefonoCtrl.dispose();
    _cbuCtrl.dispose();
    _nombrePropietarioCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  bool _validarPaso(int paso) {
    switch (paso) {
      case 0:
        if (_nombreNegocioCtrl.text.trim().isEmpty) {
          _mostrarError('Ingresá el nombre del negocio');
          return false;
        }
        if (_tipoSeleccionado == null) {
          _mostrarError('Seleccioná el tipo de comercio');
          return false;
        }
        if (_cuitCtrl.text.trim().isEmpty) {
          _mostrarError('Ingresá el CUIT');
          return false;
        }
        return true;
      case 1:
        if (_direccionCtrl.text.trim().isEmpty) {
          _mostrarError('Ingresá la dirección');
          return false;
        }
        if (_telefonoCtrl.text.trim().isEmpty) {
          _mostrarError('Ingresá el teléfono');
          return false;
        }
        return true;
      case 2:
        if (_nombrePropietarioCtrl.text.trim().isEmpty) {
          _mostrarError('Ingresá el nombre del propietario');
          return false;
        }
        if (_emailCtrl.text.trim().isEmpty) {
          _mostrarError('Ingresá el email');
          return false;
        }
        if (_passCtrl.text.length < 6) {
          _mostrarError('La contraseña debe tener al menos 6 caracteres');
          return false;
        }
        if (!_aceptaTerminos) {
          _mostrarError('Tenés que aceptar los Términos y la Política de Privacidad');
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  void _mostrarError(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: Colors.red),
    );
  }

  Future<void> _registrar() async {
    if (!_validarPaso(2)) return;
    setState(() => _cargando = true);

    try {
      // Paso 1: Crear usuario
      final resAuth = await ApiService.post('/auth/registro', {
        'nombre': _nombrePropietarioCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'password': _passCtrl.text,
        'rol': 'comercio',
      });

      if (!mounted) return;

      if (resAuth['status'] != 200 && resAuth['status'] != 201) {
        final msg = resAuth['data']?['error'] ?? resAuth['data']?['mensaje'] ?? 'Error al crear el usuario';
        _mostrarError(msg);
        setState(() => _cargando = false);
        return;
      }

      final token = resAuth['data']?['token'];
      if (token == null) {
        _mostrarError('Error al crear el usuario. Intentá de nuevo.');
        setState(() => _cargando = false);
        return;
      }

      await ApiService.guardarToken(token);

      // Paso 2: Crear comercio
      final resComercio = await ApiService.post('/comercios', {
        'nombre': _nombreNegocioCtrl.text.trim(),
        'tipo': _tipoSeleccionado,
        'cuit': _cuitCtrl.text.trim(),
        'direccion': _direccionCtrl.text.trim(),
        'telefono': _telefonoCtrl.text.trim(),
        'radio_entrega_km': _radioEntrega.round(),
        'cbu_alias': _cbuCtrl.text.trim(),
      });

      if (!mounted) return;

      if (resComercio['status'] != 200 && resComercio['status'] != 201) {
        final msg = resComercio['data']?['error'] ?? resComercio['data']?['mensaje'] ?? 'Error al crear el comercio';
        _mostrarError(msg);
        setState(() => _cargando = false);
        return;
      }

      final comercioData = resComercio['data']?['comercio'] ?? resComercio['data'];
      if (comercioData != null) {
        await ApiService.guardarComercio(comercioData);
      }

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => VerificarEmailScreen(email: _emailCtrl.text.trim())),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      _mostrarError('Error de conexión: ${e.toString()}');
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kFondo,
      appBar: AppBar(
        title: const Text('Registrar comercio'),
        backgroundColor: kNaranja,
        foregroundColor: Colors.white,
      ),
      body: Stepper(
        currentStep: _currentStep,
        type: StepperType.vertical,
        connectorColor: WidgetStateProperty.all(kNaranja),
        steps: [
          Step(
            title: const Text('Datos del negocio'),
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.indexed,
            content: _buildPaso1(),
          ),
          Step(
            title: const Text('Ubicación y entrega'),
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : StepState.indexed,
            content: _buildPaso2(),
          ),
          Step(
            title: const Text('Cuenta de acceso'),
            isActive: _currentStep >= 2,
            state: StepState.indexed,
            content: _buildPaso3(),
          ),
        ],
        onStepContinue: () {
          if (_validarPaso(_currentStep)) {
            if (_currentStep < 2) {
              setState(() => _currentStep++);
            } else {
              _registrar();
            }
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) setState(() => _currentStep--);
        },
        controlsBuilder: (context, details) {
          final esUltimoPaso = _currentStep == 2;
          return Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: _cargando ? null : details.onStepContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kNaranja,
                    foregroundColor: Colors.white,
                  ),
                  child: _cargando && esUltimoPaso
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(esUltimoPaso ? 'Registrar' : 'Continuar'),
                ),
                if (_currentStep > 0) ...[
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: details.onStepCancel,
                    child: const Text('Atrás'),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPaso1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _nombreNegocioCtrl,
          decoration: const InputDecoration(
            labelText: 'Nombre del negocio *',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Tipo de comercio *', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _tipos.map((tipo) {
            final seleccionado = _tipoSeleccionado == tipo;
            return ChoiceChip(
              label: Text(_tiposLabel[tipo] ?? tipo),
              selected: seleccionado,
              selectedColor: kNaranja,
              labelStyle: TextStyle(
                color: seleccionado ? Colors.white : Colors.black87,
              ),
              onSelected: (_) => setState(() => _tipoSeleccionado = tipo),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _cuitCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'CUIT *',
            hintText: '20-12345678-9',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildPaso2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _direccionCtrl,
          decoration: const InputDecoration(
            labelText: 'Dirección *',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _telefonoCtrl,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Teléfono *',
            border: OutlineInputBorder(),
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
        const SizedBox(height: 16),
        TextField(
          controller: _cbuCtrl,
          decoration: const InputDecoration(
            labelText: 'CBU o Alias (para recibir pagos)',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildPaso3() {
    return Column(
      children: [
        TextField(
          controller: _nombrePropietarioCtrl,
          decoration: const InputDecoration(
            labelText: 'Nombre del propietario *',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email *',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passCtrl,
          obscureText: !_verPassword,
          decoration: InputDecoration(
            labelText: 'Contraseña *',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: Icon(_verPassword ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _verPassword = !_verPassword),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Checkbox(value: _aceptaTerminos, onChanged: (v) => setState(() => _aceptaTerminos = v ?? false)),
          Expanded(child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: GestureDetector(
              onTap: () => setState(() => _aceptaTerminos = !_aceptaTerminos),
              child: RichText(text: TextSpan(
                style: const TextStyle(fontSize: 12, color: kAzul),
                children: [
                  const TextSpan(text: 'Acepto los '),
                  TextSpan(text: 'Términos y condiciones', style: const TextStyle(color: kNaranja, fontWeight: FontWeight.w700),
                    recognizer: TapGestureRecognizer()..onTap = () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LegalScreen(titulo: 'Términos y condiciones', texto: terminosComercio)))),
                  const TextSpan(text: ' y la '),
                  TextSpan(text: 'Política de privacidad', style: const TextStyle(color: kNaranja, fontWeight: FontWeight.w700),
                    recognizer: TapGestureRecognizer()..onTap = () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LegalScreen(titulo: 'Política de privacidad', texto: politicaPrivacidad)))),
                ],
              )),
            ),
          )),
        ]),
      ],
    );
  }
}
