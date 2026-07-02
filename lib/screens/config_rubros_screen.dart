import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../core/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'seleccion_rubros_screen.dart';

class ConfigRubrosScreen extends StatefulWidget {
  const ConfigRubrosScreen({super.key});

  @override
  State<ConfigRubrosScreen> createState() => _ConfigRubrosScreenState();
}

class _ConfigRubrosScreenState extends State<ConfigRubrosScreen> {
  List<dynamic> _rubros = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    final res = await ApiService.get('/rubros/comercio');
    if (!mounted) return;
    setState(() {
      _rubros = res['status'] == 200 ? (res['data'] as List) : [];
      _cargando = false;
    });
  }

  Future<void> _eliminar(int rubroId, String nombre) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Quitar rubro?'),
        content: Text('¿Querés quitar "$nombre" de tus rubros?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Quitar', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;

    final res = await ApiService.delete('/rubros/comercio/$rubroId');
    if (!mounted) return;
    if (res['status'] == 200) {
      _cargar();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res['data']?['error'] ?? 'Error al quitar rubro'),
        backgroundColor: AppColors.error,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Mis rubros', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
        actions: [
          TextButton.icon(
            onPressed: () async {
              final resultado = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => const SeleccionRubrosScreen(esRegistro: false),
                ),
              );
              if (resultado == true || resultado == null) _cargar();
            },
            icon: const Icon(Icons.edit_rounded, color: Colors.white, size: 18),
            label: Text('Editar', style: GoogleFonts.poppins(color: Colors.white, fontSize: 13)),
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _rubros.isEmpty
              ? _buildVacio()
              : _buildLista(),
    );
  }

  Widget _buildVacio() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.category_outlined, size: 40, color: AppColors.primary),
          ),
          const SizedBox(height: 20),
          Text(
            'Aún no configuraste tus rubros',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Los rubros le permiten a tus clientes encontrarte más fácil según lo que vendés.',
            style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              final resultado = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => const SeleccionRubrosScreen(esRegistro: false),
                ),
              );
              if (resultado == true || resultado == null) _cargar();
            },
            icon: const Icon(Icons.add_rounded),
            label: Text(
              'Configurar rubros',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildLista() {
    final principales = _rubros.where((r) => r['tipo'] == 'principal').toList();
    final secundarios = _rubros.where((r) => r['tipo'] == 'secundario').toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Rubros principales',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Son tu especialidad — aparecen primero en el catálogo.',
          style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        ...principales.map((r) => _RubroTile(
              rubro: r,
              esPrincipal: true,
              onEliminar: () => _eliminar(r['rubro_id'] as int, r['nombre'] as String),
            )),
        if (secundarios.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(
            'Rubros adicionales',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Productos que manejás pero no son tu especialidad.',
            style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          ...secundarios.map((r) => _RubroTile(
                rubro: r,
                esPrincipal: false,
                onEliminar: () => _eliminar(r['rubro_id'] as int, r['nombre'] as String),
              )),
        ],
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: () async {
            final resultado = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (_) => const SeleccionRubrosScreen(esRegistro: false),
              ),
            );
            if (resultado == true || resultado == null) _cargar();
          },
          icon: const Icon(Icons.edit_rounded, size: 18),
          label: Text('Cambiar rubros', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ],
    );
  }
}

class _RubroTile extends StatelessWidget {
  final dynamic rubro;
  final bool esPrincipal;
  final VoidCallback onEliminar;
  const _RubroTile({required this.rubro, required this.esPrincipal, required this.onEliminar});

  @override
  Widget build(BuildContext context) {
    final colorHex = (rubro['color_hex'] as String).replaceAll('#', '');
    final color = Color(int.parse('0xFF$colorHex'));

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: esPrincipal ? color.withValues(alpha: 0.5) : AppColors.divider,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(rubro['icono_emoji'] as String, style: const TextStyle(fontSize: 22)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              rubro['nombre'] as String,
              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: esPrincipal ? AppColors.primaryLight : AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                esPrincipal ? 'Principal' : 'Adicional',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: esPrincipal ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ),
          ]),
        ),
        IconButton(
          onPressed: onEliminar,
          icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
        ),
      ]),
    );
  }
}
