// Botón de Ayuda/Soporte: abre WhatsApp con un mensaje prearmado.
// TODO: reemplazar por el número real de soporte (formato internacional sin '+' ni espacios,
// ej: 5492610000000 para Argentina). Mientras tanto queda un número de ejemplo.
import 'package:url_launcher/url_launcher.dart';

const String numeroSoporteWhatsApp = '5492610000000'; // TODO: poner el número real acá

Future<void> abrirSoporteWhatsApp({String? pedidoId}) async {
  final mensaje = pedidoId != null
      ? 'Hola, soy un comercio de MaterialesYa y necesito ayuda con el pedido #$pedidoId'
      : 'Hola, soy un comercio de MaterialesYa y necesito ayuda';
  final uri = Uri.parse('https://wa.me/$numeroSoporteWhatsApp?text=${Uri.encodeComponent(mensaje)}');
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}
