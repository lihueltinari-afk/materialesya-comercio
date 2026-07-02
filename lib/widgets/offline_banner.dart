import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';

/// Banner discreto en la parte superior que aparece cuando no hay conexión
/// y desaparece automáticamente cuando vuelve.
class OfflineBanner extends StatefulWidget {
  final Widget child;
  const OfflineBanner({super.key, required this.child});

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner>
    with SingleTickerProviderStateMixin {
  bool _offline = false;
  Timer? _checker;
  late AnimationController _ac;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _slide = Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ac, curve: Curves.easeOut));
    _checker = Timer.periodic(const Duration(seconds: 8), (_) => _check());
    _check();
  }

  @override
  void dispose() {
    _checker?.cancel();
    _ac.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    bool ahora = false;
    try {
      final base = ApiService.baseUrlPublico.replaceFirst('/api', '');
      final uri = Uri.parse('$base/health/db');
      final res = await http.get(uri).timeout(const Duration(seconds: 4));
      ahora = res.statusCode >= 500;
    } catch (_) {
      ahora = true;
    }
    if (!mounted) return;
    if (ahora != _offline) {
      setState(() => _offline = ahora);
      if (_offline) _ac.forward(); else _ac.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      widget.child,
      SlideTransition(
        position: _slide,
        child: SafeArea(
          bottom: false,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: double.infinity,
            color: _offline ? const Color(0xFFB71C1C) : Colors.transparent,
            padding: _offline ? const EdgeInsets.symmetric(vertical: 6, horizontal: 16) : EdgeInsets.zero,
            child: _offline
                ? const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.wifi_off_rounded, color: Colors.white, size: 14),
                    SizedBox(width: 6),
                    Text('Sin conexión a internet',
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                  ])
                : const SizedBox.shrink(),
          ),
        ),
      ),
    ]);
  }
}
