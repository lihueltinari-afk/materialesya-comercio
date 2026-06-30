import 'package:flutter/material.dart';

const kNaranja = Color(0xFFE07B00);
const kAzul    = Color(0xFF1E3A5F);
const kFondo   = Color(0xFFF5F5F5);

final appTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: kNaranja, primary: kNaranja, secondary: kAzul),
  useMaterial3: true,
  fontFamily: 'Roboto',
  appBarTheme: const AppBarTheme(
    backgroundColor: kAzul,
    foregroundColor: Colors.white,
    elevation: 0,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: kNaranja,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
      textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    filled: true,
    fillColor: Colors.white,
  ),
  cardTheme: CardThemeData(
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    color: Colors.white,
  ),
);
