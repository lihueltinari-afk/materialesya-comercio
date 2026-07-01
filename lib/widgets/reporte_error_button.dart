import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ReporteErrorButton extends StatelessWidget {
  final String pantalla;
  final String appNombre;
  final int? usuarioId;

  const ReporteErrorButton({
    super.key,
    required this.pantalla,
    this.appNombre = 'Comercio',
    this.usuarioId,
  });

  void _abrir(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReporteSheet(
        pantalla: pantalla,
        appNombre: appNombre,
        usuarioId: usuarioId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Reportar un problema',
      child: FloatingActionButton.small(
        onPressed: () => _abrir(context),
        backgroundColor: Colors.grey[200],
        foregroundColor: Colors.grey[600],
        elevation: 2,
        child: const Icon(Icons.bug_report_outlined, size: 20),
      ),
    );
  }
}

class _ReporteSheet extends StatefulWidget {
  final String pantalla;
  final String appNombre;
  final int? usuarioId;

  const _ReporteSheet({
    required this.pantalla,
    required this.appNombre,
    this.usuarioId,
  });

  @override
  State<_ReporteSheet> createState() => _ReporteSheetState();
}

class _ReporteSheetState extends State<_ReporteSheet> {
  final _ctrl = TextEditingController();
  bool _enviando = false;
  bool _enviado = false;
  String? _error;

  Future<void> _enviar() async {
    if (_ctrl.text.trim().length < 5) {
      setState(() => _error = 'Por favor describí el problema (mínimo 5 caracteres)');
      return;
    }
    setState(() { _enviando = true; _error = null; });

    final res = await ApiService.post('/soporte/reporte', {
      'app': widget.appNombre,
      'pantalla': widget.pantalla,
      'descripcion': _ctrl.text.trim(),
      if (widget.usuarioId != null) 'usuario_id': widget.usuarioId,
    });

    final ok = res['data']?['ok'] == true;
    setState(() {
      _enviando = false;
      _enviado = ok;
      if (!ok) _error = res['data']?['error'] ?? 'No se pudo enviar. Intentá de nuevo.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.bug_report, color: Color(0xFFE53935)),
            const SizedBox(width: 10),
            const Text('Reportar un problema',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ]),
          const SizedBox(height: 4),
          Text('Pantalla: ${widget.pantalla}',
              style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          const SizedBox(height: 16),
          if (_enviado) ...[
            const Icon(Icons.check_circle, color: Color(0xFF43A047), size: 48),
            const SizedBox(height: 12),
            const Text(
              '¡Reporte enviado!\nNuestro equipo lo va a revisar.',
              style: TextStyle(fontSize: 15),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
            ),
          ] else ...[
            const Text('¿Qué está fallando?',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _ctrl,
              maxLines: 4,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Describí el problema lo más claro posible...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _enviando ? null : _enviar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE53935),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _enviando
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Enviar reporte', style: TextStyle(fontSize: 15)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
