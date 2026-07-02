import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../core/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

class SeleccionRubrosScreen extends StatefulWidget {
  final bool esRegistro; // true = viene del registro, false = desde configuración
  const SeleccionRubrosScreen({super.key, this.esRegistro = true});

  @override
  State<SeleccionRubrosScreen> createState() => _SeleccionRubrosScreenState();
}

class _SeleccionRubrosScreenState extends State<SeleccionRubrosScreen> {
  List<dynamic> _rubros = [];
  List<int> _principales = [];
  List<int> _secundarios = [];
  int _paso = 0; // 0=principales, 1=secundarios, 2=confirmacion
  bool _cargando = true;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _cargarRubros();
  }

  Future<void> _cargarRubros() async {
    final res = await ApiService.get('/rubros');
    if (mounted && res['status'] == 200) {
      setState(() {
        _rubros = res['data'] as List;
        _cargando = false;
      });
    } else if (mounted) {
      setState(() => _cargando = false);
    }
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    final res = await ApiService.post('/rubros/comercio', {
      'principales': _principales,
      'secundarios': _secundarios,
    });
    if (!mounted) return;
    if (res['status'] == 200) {
      if (widget.esRegistro) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rubros actualizados'), backgroundColor: AppColors.success),
        );
        Navigator.pop(context);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res['data']?['error'] ?? 'Error al guardar'),
        backgroundColor: AppColors.error,
      ));
      setState(() => _guardando = false);
    }
  }

  void _togglePrincipal(int id) {
    setState(() {
      if (_principales.contains(id)) {
        _principales.remove(id);
      } else if (_principales.length < 3) {
        _principales.add(id);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Ya elegiste tus 3 rubros principales. Podés agregar más como secundarios.'),
          backgroundColor: AppColors.warning,
        ));
      }
    });
  }

  void _toggleSecundario(int id) {
    if (_principales.contains(id)) return;
    setState(() {
      if (_secundarios.contains(id)) {
        _secundarios.remove(id);
      } else {
        _secundarios.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _paso == 0
              ? 'Tus especialidades'
              : _paso == 1
                  ? 'Rubros adicionales'
                  : 'Confirmar rubros',
        ),
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
        leading: _paso > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _paso--),
              )
            : null,
      ),
      body: Column(children: [
        // Stepper visual
        Container(
          color: AppColors.secondary,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Row(children: [
            _StepDot(numero: 1, activo: _paso >= 0, label: 'Principales'),
            Expanded(
              child: Container(
                height: 2,
                color: _paso >= 1 ? AppColors.primary : Colors.white24,
              ),
            ),
            _StepDot(numero: 2, activo: _paso >= 1, label: 'Adicionales'),
            Expanded(
              child: Container(
                height: 2,
                color: _paso >= 2 ? AppColors.primary : Colors.white24,
              ),
            ),
            _StepDot(numero: 3, activo: _paso >= 2, label: 'Confirmar'),
          ]),
        ),

        // Contenido
        Expanded(child: _buildPaso()),

        // Botón siguiente
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: (_paso == 0 && _principales.isEmpty) || _guardando
                  ? null
                  : () {
                      if (_paso < 2) {
                        setState(() => _paso++);
                      } else {
                        _guardar();
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _guardando
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                    )
                  : Text(
                      _paso == 2 ? 'Confirmar y ver mi catálogo' : 'Siguiente',
                      style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildPaso() {
    if (_paso == 0) {
      return _buildGridRubros(
        titulo: '¿Cuál es el fuerte de tu negocio?',
        subtitulo: 'Elegí hasta 3 rubros principales. Estos van a aparecer primero en tu catálogo.',
        seleccionados: _principales,
        onTap: _togglePrincipal,
        deshabilitados: const [],
      );
    }
    if (_paso == 1) {
      return _buildGridRubros(
        titulo: '¿También manejás algo de estos rubros?',
        subtitulo: 'Son productos que tenés pero no son tu especialidad.',
        seleccionados: _secundarios,
        onTap: _toggleSecundario,
        deshabilitados: _principales,
      );
    }
    return _buildConfirmacion();
  }

  Widget _buildGridRubros({
    required String titulo,
    required String subtitulo,
    required List<int> seleccionados,
    required Function(int) onTap,
    required List<int> deshabilitados,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          titulo,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitulo,
          style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.1,
          ),
          itemCount: _rubros.length,
          itemBuilder: (ctx, i) {
            final r = _rubros[i];
            final id = r['id'] as int;
            final seleccionado = seleccionados.contains(id);
            final deshabilitado = deshabilitados.contains(id);
            final colorHex = (r['color_hex'] as String).replaceAll('#', '');
            final color = Color(int.parse('0xFF$colorHex'));

            return GestureDetector(
              onTap: deshabilitado ? null : () => onTap(id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: seleccionado ? color.withValues(alpha: 0.1) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: seleccionado
                        ? color
                        : (deshabilitado ? AppColors.divider : const Color(0xFFE5E7EB)),
                    width: seleccionado ? 2.5 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(14),
                child: Stack(children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(
                      r['icono_emoji'] as String,
                      style: const TextStyle(fontSize: 28),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      r['nombre'] as String,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: deshabilitado ? AppColors.textLight : AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (deshabilitado)
                      Text(
                        'Rubro principal',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ]),
                  if (seleccionado)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                        child: const Icon(Icons.check, color: Colors.white, size: 14),
                      ),
                    ),
                ]),
              ),
            );
          },
        ),
      ]),
    );
  }

  Widget _buildConfirmacion() {
    final principalesData =
        _rubros.where((r) => _principales.contains(r['id'] as int)).toList();
    final secundariosData =
        _rubros.where((r) => _secundarios.contains(r['id'] as int)).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          'Resumen de tus rubros',
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 20),
        Text(
          '⭐ Rubros principales',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        ...principalesData.map((r) => _RubroChip(rubro: r, tipo: 'principal')),
        if (secundariosData.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'También manejás',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          ...secundariosData.map((r) => _RubroChip(rubro: r, tipo: 'secundario')),
        ],
      ]),
    );
  }
}

class _StepDot extends StatelessWidget {
  final int numero;
  final bool activo;
  final String label;
  const _StepDot({required this.numero, required this.activo, required this.label});

  @override
  Widget build(BuildContext context) => Column(children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: activo ? AppColors.primary : Colors.white24,
          ),
          child: Center(
            child: Text(
              '$numero',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.poppins(fontSize: 9, color: Colors.white70)),
      ]);
}

class _RubroChip extends StatelessWidget {
  final dynamic rubro;
  final String tipo;
  const _RubroChip({required this.rubro, required this.tipo});

  @override
  Widget build(BuildContext context) {
    final colorHex = (rubro['color_hex'] as String).replaceAll('#', '');
    final color = Color(int.parse('0xFF$colorHex'));
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: tipo == 'principal' ? color.withValues(alpha: 0.1) : AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tipo == 'principal' ? color : AppColors.divider),
      ),
      child: Row(children: [
        Text(rubro['icono_emoji'] as String, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 10),
        Text(
          rubro['nombre'] as String,
          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ]),
    );
  }
}
