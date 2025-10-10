// lib/themes/indigo_theme.dart
import 'package:flutter/material.dart';

final ThemeData indigoTheme = ThemeData(
  brightness: Brightness.dark,
  fontFamily: 'Poppins',
  colorScheme: ColorScheme.dark(
    primary: Colors.indigo.shade300,
    secondary: Colors.indigo.shade200,
    surface: const Color(0xFF262A35), // Darker card color
    // REMOVED: 'background' is deprecated.
    onPrimary: Colors.black,
    onSurface: Colors.white,
    // REMOVED: 'onBackground' is deprecated.
    error: Colors.red.shade300,
  ),
  primaryColor: Colors.indigo.shade300,
  scaffoldBackgroundColor: const Color(0xFF1A1D24),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF1A1D24),
    elevation: 0,
    centerTitle: true,
    iconTheme: IconThemeData(color: Colors.white),
  ),
  cardTheme: CardTheme(
    color: const Color(0xFF262A35),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.indigo.shade300,
      foregroundColor: Colors.black,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  ),
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: const Color(0xFF262A35),
    selectedItemColor: Colors.indigo.shade300,
    unselectedItemColor: Colors.grey.shade500,
  ),
);
