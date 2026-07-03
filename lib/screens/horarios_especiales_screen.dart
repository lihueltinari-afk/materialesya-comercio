import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_colors.dart';
import '../services/api_service.dart';

class HorariosEspecialesScreen extends StatefulWidget {
  const HorariosEspecialesScreen({super.key});

  @override
  State<HorariosEspecialesScreen> createState() => _HorariosEspecialesScreenState();
}

class _HorariosEspecialesScreenState extends State<HorariosEspecialesScreen> {
  List<dynamic> _horarios = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    final res = await ApiService.get('/horarios-especiales');
    if (!mounted) return;
    setState(() {
      _cargando = false;
      if (res['status'] == 200) {
        _horarios = List<dynamic>.from(res['data']['horarios'] ?? []);
      }
    });
  }

  Future<void> _eliminar(int id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar horario especial'),
        content: const Text('¿Estás seguro?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;
    final res = await ApiService.delete('/horarios-especiales/$id');
    if (!mounted) return;
    if (res['status'] == 200) {
      _cargar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Horario eliminado'), backgroundColor: Colors.green),
      );
    }
  }

  Future<void> _agregarHorario() async {
    DateTime? fechaSeleccionada;
    bool abierto = false;
    final aperturaCtrl = TextEditingController();
    final cierreCtrl = TextEditingController();
    final motivoCtrl = TextEditingController();

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
              Text('Nuevo horario especial',
                style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.secondary)),
              Text('Feriados, días especiales, vacaciones, etc.',
                style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              // DatePicker
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) setModalState(() => fechaSeleccionada = picked);
                },
                icon: const Icon(Icons.calendar_today),
                label: Text(
                  fechaSeleccionada != null
                    ? '${fechaSeleccionada!.day.toString().padLeft(2,'0')}/${fechaSeleccionada!.month.toString().padLeft(2,'0')}/${fechaSeleccionada!.year}'
                    : 'Seleccionar fecha',
                  style: GoogleFonts.poppins(),
                ),
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: abierto,
                activeColor: AppColors.primary,
                title: Text('¿Abierto ese día?', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                onChanged: (v) => setModalState(() => abierto = v),
              ),
              if (abierto) ...[
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: aperturaCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Apertura (HH:mm)',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        keyboardType: TextInputType.datetime,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: cierreCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Cierre (HH:mm)',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        keyboardType: TextInputType.datetime,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: motivoCtrl,
                decoration: const InputDecoration(
                  labelText: 'Motivo (opcional)',
                  border: OutlineInputBorder(),
                  hintText: 'Ej: Feriado nacional, vacaciones...',
                ),
              ),
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
                    if (fechaSeleccionada == null) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Seleccioná una fecha')),
                      );
                      return;
                    }
                    final fecha = '${fechaSeleccionada!.year}-${fechaSeleccionada!.month.toString().padLeft(2,'0')}-${fechaSeleccionada!.day.toString().padLeft(2,'0')}';
                    Navigator.pop(ctx);
                    final body = <String, dynamic>{
                      'fecha': fecha,
                      'abierto': abierto,
                      'motivo': motivoCtrl.text.trim().isEmpty ? null : motivoCtrl.text.trim(),
                    };
                    if (abierto) {
                      if (aperturaCtrl.text.trim().isNotEmpty) body['hora_apertura'] = aperturaCtrl.text.trim();
                      if (cierreCtrl.text.trim().isNotEmpty) body['hora_cierre'] = cierreCtrl.text.trim();
                    }
                    final res = await ApiService.post('/horarios-especiales', body);
                    if (!mounted) return;
                    if (res['status'] == 200) {
                      _cargar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Horario guardado'), backgroundColor: Colors.green),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Error al guardar'), backgroundColor: Colors.red),
                      );
                    }
                  },
                  child: Text('Guardar', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatearFecha(String fecha) {
    try {
      final parts = fecha.split('T')[0].split('-');
      if (parts.length < 3) return fecha;
      final meses = ['', 'ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
      return '${parts[2]}/${meses[int.parse(parts[1])]}/${parts[0]}';
    } catch (_) { return fecha; }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Horarios Especiales', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _agregarHorario,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            color: AppColors.infoBg,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Text(
              'Configurá excepciones para feriados, días especiales, etc.',
              style: GoogleFonts.poppins(fontSize: 13, color: AppColors.secondary),
            ),
          ),
          Expanded(
            child: _cargando
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _horarios.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.event_outlined, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text('Sin horarios especiales', style: GoogleFonts.poppins(color: Colors.grey)),
                        const SizedBox(height: 8),
                        Text('Tocá + para agregar uno', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: _cargar,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
                      itemCount: _horarios.length,
                      itemBuilder: (_, i) {
                        final h = _horarios[i] as Map;
                        final abierto = h['abierto'] == true;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: abierto ? AppColors.successBg : AppColors.errorBg,
                              child: Icon(
                                abierto ? Icons.check_circle_outline : Icons.cancel_outlined,
                                color: abierto ? AppColors.success : AppColors.error,
                              ),
                            ),
                            title: Text(
                              _formatearFecha(h['fecha']?.toString() ?? ''),
                              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  abierto
                                    ? 'Abierto${h['hora_apertura'] != null ? ' ${h['hora_apertura'].toString().substring(0, 5)} - ${h['hora_cierre']?.toString().substring(0, 5) ?? '?'}' : ''}'
                                    : 'Cerrado',
                                  style: GoogleFonts.poppins(fontSize: 12, color: abierto ? AppColors.success : AppColors.error),
                                ),
                                if ((h['motivo'] ?? '').toString().isNotEmpty)
                                  Text(h['motivo'].toString(), style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary)),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => _eliminar(h['id'] as int),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
