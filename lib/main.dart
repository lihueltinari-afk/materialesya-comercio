import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

void main() => runApp(const ComercioApp());

class ComercioApp extends StatelessWidget {
  const ComercioApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MaterialesYa Comercio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE07B00), primary: const Color(0xFFE07B00)),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
