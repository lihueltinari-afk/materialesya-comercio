// Botón de Ayuda/Soporte: abre WhatsApp con un mensaje prearmado.
import 'package:url_launcher/url_launcher.dart';

const String numeroSoporteWhatsApp = '5492604399394';

Future<void> abrirSoporteWhatsApp({String? pedidoId}) async {
  final mensaje = pedidoId != null
      ? 'Hola, soy un comercio de MaterialesYa y necesito ayuda con el pedido #$pedidoId'
      : 'Hola, soy un comercio de MaterialesYa y necesito ayuda';
  final uri = Uri.parse('https://wa.me/$numeroSoporteWhatsApp?text=${Uri.encodeComponent(mensaje)}');
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}
