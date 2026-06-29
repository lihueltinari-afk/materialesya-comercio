import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fade = Tween<double>(begin: 0, end: 1).animate(_ctrl);
    _ctrl.forward();
    Future.delayed(const Duration(seconds: 2), _checkSession);
  }

  Future<void> _checkSession() async {
    if (!mounted) return;
    final token = await ApiService.obtenerToken();
    if (!mounted) return;
    if (token != null && token.isNotEmpty) {
      // Token existe — verificar que el comercio también está guardado
      final comercioId = await ApiService.obtenerComercioId();
      if (!mounted) return;
      if (comercioId != null) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
        return;
      }
      // Token pero sin comercioId — intentar cargar
      final comercio = await ApiService.miComercio();
      if (!mounted) return;
      if (comercio != null) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
        return;
      }
    }
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE07B00),
      body: FadeTransition(
        opacity: _fade,
        child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 84, height: 84,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
            child: const Icon(Icons.store_rounded, color: Colors.white, size: 46),
          ),
          const SizedBox(height: 20),
          RichText(text: const TextSpan(
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -0.5, color: Colors.white),
            children: [
              TextSpan(text: 'Materiales'),
              TextSpan(text: 'Ya', style: TextStyle(color: Color(0xFFFFD280))),
            ],
          )),
          const SizedBox(height: 6),
          const Text('Panel del comercio', style: TextStyle(fontSize: 13, color: Colors.white70, letterSpacing: 1.2)),
        ])),
      ),
    );
  }
}
