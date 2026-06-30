// Pantalla genérica de scroll para mostrar Términos y Condiciones o Política de Privacidad.
import 'package:flutter/material.dart';

const _textDark = Color(0xFF1A1A1A);

class LegalScreen extends StatelessWidget {
  final String titulo;
  final String texto;
  const LegalScreen({super.key, required this.titulo, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(title: Text(titulo), backgroundColor: Colors.white, foregroundColor: _textDark, elevation: 0.5),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Text(texto, style: const TextStyle(fontSize: 14, height: 1.6, color: _textDark)),
      ),
    );
  }
}
