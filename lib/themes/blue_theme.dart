// lib/themes/blue_theme.dart
import 'package:flutter/material.dart';

final ThemeData blueTheme = ThemeData(
  brightness: Brightness.light,
  fontFamily: 'Poppins',
  colorScheme: ColorScheme.light(
    primary: Colors.blue.shade700,
    secondary: Colors.blue.shade500,
    surface: Colors.white,
    // REMOVED: 'background' is deprecated.
    onPrimary: Colors.white,
    onSurface: const Color(0xFF212529),
    // REMOVED: 'onBackground' is deprecated.
    error: Colors.red.shade400,
  ),
  primaryColor: Colors.blue.shade700,
  scaffoldBackgroundColor: const Color(0xFFF5F5F5),
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.blue.shade700,
    elevation: 4,
    centerTitle: true,
    titleTextStyle: const TextStyle(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.bold,
      fontFamily: 'Poppins',
    ),
    iconTheme: const IconThemeData(color: Colors.white),
  ),
  cardTheme: CardTheme(
    color: Colors.white,
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    margin: const EdgeInsets.symmetric(vertical: 8),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.blue.shade700,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
    ),
  ),
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: Colors.white,
    selectedItemColor: Colors.blue.shade700,
    unselectedItemColor: Colors.grey.shade600,
  ),
);
