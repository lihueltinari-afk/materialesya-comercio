import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'services/api_service.dart';
import 'theme.dart';

void main() => runApp(const MaterialesYaComercioApp());

class MaterialesYaComercioApp extends StatefulWidget {
  const MaterialesYaComercioApp({super.key});

  @override
  State<MaterialesYaComercioApp> createState() => _MaterialesYaComercioAppState();
}

class _MaterialesYaComercioAppState extends State<MaterialesYaComercioApp> {
  final _navKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    ApiService.onSesionExpirada = () {
      _navKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen(sesionExpirada: true)),
        (_) => false,
      );
    };
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navKey,
      title: 'MaterialesYa Comercio',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      home: const SplashScreen(),
    );
  }
}
