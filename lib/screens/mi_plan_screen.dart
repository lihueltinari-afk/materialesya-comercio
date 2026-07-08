import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import '../core/colores.dart';

class MiPlanScreen extends StatefulWidget {
  const MiPlanScreen({super.key});

  @override
  State<MiPlanScreen> createState() => _MiPlanScreenState();
}

class _MiPlanScreenState extends State<MiPlanScreen> {
  Map<String, dynamic>? _plan;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarPlan();
  }

  Future<void> _cargarPlan() async {
    try {
      final resp = await ApiService.get('/planes-comercio/mi-plan');
      if (resp.statusCode == 200) {
        setState(() {
          _plan = jsonDecode(utf8.decode(resp.bodyBytes));
          _cargando = false;
        });
      } else {
        setState(() => _cargando = false);
      }
    } catch (_) {
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        title: const Text('Mi Plan'),
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: AppColores.naranja))
          : _plan == null
              ? const Center(child: Text('Error al cargar', style: TextStyle(color: Colors.white54)))
              : RefreshIndicator(
                  onRefresh: _cargarPlan,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildPlanActual(),
                      const SizedBox(height: 16),
                      if (_plan!['plan_siguiente'] != null) _buildProximoNivel(),
                      const SizedBox(height: 16),
                      _buildVentasMes(),
                      const SizedBox(height: 16),
                      _buildHistorial(),
                      const SizedBox(height: 16),
                      _buildTodosLosPlanes(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildPlanActual() {
    final plan = _plan!['plan_actual'] ?? 'Estándar';
    final comision = _plan!['comision_productos']?.toString() ?? '15';
    final comisionEnvio = _plan!['comision_envio']?.toString() ?? '20';
    final badge = _badgePlan(plan);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [badge.color.withOpacity(0.3), const Color(0xFF1A1A2E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: badge.color.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(badge.emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Plan $plan',
                      style: TextStyle(color: badge.color, fontSize: 20, fontWeight: FontWeight.bold)),
                  Text('Tu plan actual', style: const TextStyle(color: Colors.white54, fontSize: 13)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _infoRow('Comisión en productos', '$comision%'),
          _infoRow('Comisión en envío', '$comisionEnvio%'),
        ],
      ),
    );
  }

  Widget _buildProximoNivel() {
    final sig = _plan!['plan_siguiente'];
    if (sig == null) return const SizedBox();
    final nombre = sig['nombre'] ?? '';
    final comision = sig['comision_productos']?.toString() ?? '';
    final faltan = (sig['faltan'] ?? 0).toDouble();
    final minimas = (sig['ventas_minimas'] ?? 0).toDouble();
    final badge = _badgePlan(nombre);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A3A5A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(badge.emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text('Próximo nivel: $nombre',
                  style: TextStyle(color: badge.color, fontWeight: FontWeight.w600, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            faltan > 0
                ? 'Te faltan \$${_fmt(faltan)} este mes'
                : '¡Ya calificás para este plan!',
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          if (faltan > 0) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: minimas > 0 ? (1 - faltan / minimas).clamp(0.0, 1.0) : 0,
                backgroundColor: Colors.white12,
                valueColor: AlwaysStoppedAnimation<Color>(badge.color),
                minHeight: 6,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'Beneficio: comisión baja al $comision%',
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildVentasMes() {
    final ventasMes = (_plan!['ventas_mes_actual'] ?? 0).toDouble();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A3A5A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ventas este mes', style: TextStyle(color: Colors.white54, fontSize: 13)),
          const SizedBox(height: 4),
          Text('\$${_fmt(ventasMes)}',
              style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildHistorial() {
    final historial = _plan!['historial'] as List? ?? [];
    if (historial.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Historial de planes', style: TextStyle(color: Colors.white54, fontSize: 13)),
        const SizedBox(height: 8),
        ...historial.take(5).map((h) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            '${h['cambio_at']?.toString().substring(0, 10) ?? ''}: ${h['plan_anterior']} → ${h['plan_nuevo']}',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        )),
      ],
    );
  }

  Widget _buildTodosLosPlanes() {
    final planes = _plan!['planes_disponibles'] as List? ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Todos los planes', style: TextStyle(color: Colors.white54, fontSize: 13)),
        const SizedBox(height: 8),
        ...planes.map((p) {
          final badge = _badgePlan(p['nombre']);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Text(badge.emoji),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(p['nombre'],
                      style: TextStyle(color: badge.color, fontWeight: FontWeight.w500)),
                ),
                Text('${p['comision_productos']}%',
                    style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _infoRow(String label, String valor) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 14)),
        Text(valor, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    ),
  );

  _BadgeInfo _badgePlan(String plan) {
    switch (plan) {
      case 'Silver': return _BadgeInfo('🥈', const Color(0xFFC0C0C0));
      case 'Gold': return _BadgeInfo('🥇', const Color(0xFFFFD700));
      case 'Platinum': return _BadgeInfo('💎', const Color(0xFF67E8F9));
      default: return _BadgeInfo('⭐', const Color(0xFFE8601C));
    }
  }

  String _fmt(double n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}K';
    return n.toStringAsFixed(0);
  }
}

class _BadgeInfo {
  final String emoji;
  final Color color;
  const _BadgeInfo(this.emoji, this.color);
}
