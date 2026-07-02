import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OrderStatusChip extends StatelessWidget {
  final String estado;
  const OrderStatusChip(this.estado, {super.key});

  static (Color bg, Color text, String label, IconData icon) _meta(String estado) {
    switch (estado) {
      case 'pendiente': return (const Color(0xFFFEF3C7), const Color(0xFFD97706), 'Pendiente', Icons.schedule);
      case 'aceptado': return (const Color(0xFFDBEAFE), const Color(0xFF1D4ED8), 'Aceptado', Icons.thumb_up_outlined);
      case 'confirmado': return (const Color(0xFFDBEAFE), const Color(0xFF1D4ED8), 'Confirmado', Icons.check_circle_outline);
      case 'en_preparacion': return (const Color(0xFFF3E8FF), const Color(0xFF7C3AED), 'Preparando', Icons.inventory_2_outlined);
      case 'preparando': return (const Color(0xFFF3E8FF), const Color(0xFF7C3AED), 'Preparando', Icons.inventory_2_outlined);
      case 'listo_para_retirar': return (const Color(0xFFD1FAE5), const Color(0xFF059669), 'Listo para despacho', Icons.store_outlined);
      case 'en_camino': return (const Color(0xFFD1FAE5), const Color(0xFF059669), 'En camino', Icons.delivery_dining);
      case 'retirado': return (const Color(0xFFCFFAFE), const Color(0xFF0891B2), 'Retirado', Icons.shopping_bag_outlined);
      case 'entregado': return (const Color(0xFFD1FAE5), const Color(0xFF065F46), 'Entregado ✓', Icons.check_circle_outline);
      case 'cancelado': return (const Color(0xFFFEE2E2), const Color(0xFFDC2626), 'Cancelado', Icons.cancel_outlined);
      default: return (const Color(0xFFF3F4F6), const Color(0xFF6B7280), estado, Icons.help_outline);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (bg, text, label, icon) = _meta(estado);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: text),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: text)),
      ]),
    );
  }
}
