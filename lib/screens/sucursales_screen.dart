import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_colors.dart';
import '../services/api_service.dart';

class SucursalesScreen extends StatefulWidget {
  const SucursalesScreen({super.key});

  @override
  State<SucursalesScreen> createState() => _SucursalesScreenState();
}

class _SucursalesScreenState extends State<SucursalesScreen> {
  List<dynamic> _sucursales = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    final res = await ApiService.get('/sucursales');
    if (!mounted) return;
    setState(() {
      _cargando = false;
      if (res['status'] == 200) {
        _sucursales = List<dynamic>.from(res['data']['sucursales'] ?? []);
      }
    });
  }

  Future<void> _mostrarFormulario({Map? sucursal}) async {
    final nombreCtrl = TextEditingController(text: sucursal?['nombre'] ?? '');
    final direccionCtrl = TextEditingController(text: sucursal?['direccion'] ?? '');
    final telefonoCtrl = TextEditingController(text: sucursal?['telefono'] ?? '');
    bool activa = sucursal?['activa'] != false;
    final esEdicion = sucursal != null;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                esEdicion ? 'Editar sucursal' : 'Nueva sucursal',
                style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.secondary),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nombreCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.store_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: direccionCtrl,
                decoration: const InputDecoration(
                  labelText: 'Dirección',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: telefonoCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Teléfono',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              if (esEdicion) ...[
                const SizedBox(height: 4),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: activa,
                  activeColor: AppColors.primary,
                  title: Text('Sucursal activa', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                  onChanged: (v) => setModalState(() => activa = v),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: () async {
                    if (nombreCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('El nombre es obligatorio')),
                      );
                      return;
                    }
                    Navigator.pop(ctx);
                    final body = {
                      'nombre': nombreCtrl.text.trim(),
                      'direccion': direccionCtrl.text.trim().isEmpty ? null : direccionCtrl.text.trim(),
                      'telefono': telefonoCtrl.text.trim().isEmpty ? null : telefonoCtrl.text.trim(),
                    };
                    Map<String, dynamic> res;
                    if (esEdicion) {
                      res = await ApiService.patch('/sucursales/${sucursal!['id']}', {...body, 'activa': activa});
                    } else {
                      res = await ApiService.post('/sucursales', body);
                    }
                    if (!mounted) return;
                    if (res['status'] == 200 || res['status'] == 201) {
                      _cargar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(esEdicion ? 'Sucursal actualizada' : 'Sucursal creada'), backgroundColor: Colors.green),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(res['data']?['error'] ?? 'Error al guardar'), backgroundColor: Colors.red),
                      );
                    }
                  },
                  child: Text('Guardar', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                ),
              ),
              if (esEdicion) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final confirmar = await showDialog<bool>(
                        context: context,
                        builder: (d) => AlertDialog(
                          title: const Text('Archivar sucursal'),
                          content: const Text('¿Estás seguro? La sucursal quedará inactiva.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancelar')),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(d, true),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                              child: const Text('Archivar'),
                            ),
                          ],
                        ),
                      );
                      if (confirmar != true || !mounted) return;
                      final r = await ApiService.delete('/sucursales/${sucursal!['id']}');
                      if (!mounted) return;
                      if (r['status'] == 200) {
                        _cargar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Sucursal archivada'), backgroundColor: Colors.orange),
                        );
                      }
                    },
                    icon: const Icon(Icons.archive_outlined, color: Colors.red),
                    label: Text('Archivar sucursal', style: GoogleFonts.poppins(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      minimumSize: const Size.fromHeight(44),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Mis Sucursales', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarFormulario(),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: _cargando
        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
        : _sucursales.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.store_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text('Sin sucursales', style: GoogleFonts.poppins(color: Colors.grey)),
                  const SizedBox(height: 8),
                  Text('Tocá + para agregar una', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                ],
              ),
            )
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _cargar,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
                itemCount: _sucursales.length,
                itemBuilder: (_, i) {
                  final s = _sucursales[i] as Map;
                  final activa = s['activa'] != false;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _mostrarFormulario(sucursal: Map<String, dynamic>.from(s)),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: activa ? AppColors.primaryLight : Colors.grey.shade100,
                              child: Icon(Icons.store_outlined, color: activa ? AppColors.primary : Colors.grey),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(s['nombre'] ?? '', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
                                  if ((s['direccion'] ?? '').toString().isNotEmpty)
                                    Text(s['direccion'].toString(), style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary)),
                                  if ((s['telefono'] ?? '').toString().isNotEmpty)
                                    Text(s['telefono'].toString(), style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: activa ? AppColors.successBg : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                activa ? 'Activa' : 'Inactiva',
                                style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: activa ? AppColors.success : Colors.grey),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.chevron_right, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
