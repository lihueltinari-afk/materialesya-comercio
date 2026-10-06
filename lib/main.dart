import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'services/api_service.dart';
import 'services/notificacion_service.dart';
import 'services/remote_config_service.dart';
import 'theme.dart';
import 'core/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (_) {}
  NotificacionService.init().catchError((_) {});
  RemoteConfigService.init().catchError((_) {});
  runApp(const MaterialesYaComercioApp());
}

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
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.light,
      home: const SplashScreen(),
    );
  }
}
