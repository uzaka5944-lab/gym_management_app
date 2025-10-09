import 'package:flutter/material.dart';

final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: Colors.blue.shade700,
  scaffoldBackgroundColor: const Color(0xFFF5F5F5),
  fontFamily: 'Poppins',
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
  textTheme: const TextTheme(
    displayLarge: TextStyle(
        color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 32),
    displayMedium: TextStyle(
        color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 24),
    bodyLarge: TextStyle(color: Colors.black87, fontSize: 16),
    bodyMedium: TextStyle(color: Colors.black54, fontSize: 14),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.blue.shade700,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      textStyle: const TextStyle(
          fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    hintStyle: const TextStyle(color: Colors.grey),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.grey),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
    ),
  ),
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: Colors.white,
    selectedItemColor: Colors.blue.shade700,
    unselectedItemColor: Colors.grey.shade600,
    type: BottomNavigationBarType.fixed,
    showUnselectedLabels: false,
  ),
  colorScheme: ColorScheme.light(
    primary: Colors.blue.shade700,
    secondary: Colors.blue.shade600,
    surface: Colors.white,
    onPrimary: Colors.white,
    onSurface: Colors.black87,
  ),
);
