// lib/light_theme.dart

import 'package:flutter/material.dart';

// A more modern, visually pleasing light theme for the app.
final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  fontFamily: 'Poppins',

  // Define the color scheme
  colorScheme: ColorScheme.light(
    primary: Colors.teal.shade600, // A vibrant, modern primary color
    secondary: Colors.teal.shade400, // A lighter shade for accents
    surface: Colors.white, // Card and dialog backgrounds
    // REMOVED: 'background' is deprecated. The scaffoldBackgroundColor is used instead.
    onPrimary: Colors.white, // Text/icons on top of the primary color
    onSurface: const Color(0xFF212529), // Main text color
    // REMOVED: 'onBackground' is deprecated and inferred from onSurface.
    error: Colors.red.shade400,
  ),

  // Use the color scheme for core components
  primaryColor: Colors.teal.shade600,
  scaffoldBackgroundColor: const Color(0xFFF8F9FA),

  // AppBar Theme
  appBarTheme: AppBarTheme(
    backgroundColor: const Color(0xFFF8F9FA), // Clean, light app bar
    elevation: 0, // No shadow for a flatter, modern look
    centerTitle: true,
    titleTextStyle: const TextStyle(
      color: Color(0xFF212529), // Dark text for contrast
      fontSize: 20,
      fontWeight: FontWeight.bold,
      fontFamily: 'Poppins',
    ),
    iconTheme: IconThemeData(
        color: Colors.teal.shade700), // Icons match the primary color
  ),

  // Card Theme
  cardTheme: CardTheme(
    color: Colors.white,
    elevation: 1, // Softer shadow
    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16)), // Slightly larger radius
    margin: const EdgeInsets.symmetric(vertical: 8),
  ),

  // Text Theme
  textTheme: const TextTheme(
    displayLarge: TextStyle(
        color: Color(0xFF212529), fontWeight: FontWeight.bold, fontSize: 32),
    displayMedium: TextStyle(
        color: Color(0xFF212529), fontWeight: FontWeight.bold, fontSize: 24),
    headlineSmall: TextStyle(
        color: Color(0xFF212529), fontWeight: FontWeight.bold, fontSize: 20),
    bodyLarge: TextStyle(color: Color(0xFF343A40), fontSize: 16),
    bodyMedium: TextStyle(
        color: Color(0xFF6C757D), fontSize: 14), // Lighter grey for subtitles
  ),

  // ElevatedButton Theme
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.teal.shade600,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)), // Less rounded
      textStyle: const TextStyle(
          fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
      elevation: 2,
    ),
  ),

  // OutlinedButton Theme
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: Colors.teal.shade600,
      side: BorderSide(color: Colors.teal.shade200, width: 1.5),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: const TextStyle(
          fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
    ),
  ),

  // InputDecoration Theme (for TextFields)
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    hintStyle: const TextStyle(color: Color(0xFFADB5BD)),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.teal.shade600, width: 2),
    ),
  ),

  // BottomNavigationBar Theme
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: Colors.white,
    selectedItemColor: Colors.teal.shade600,
    unselectedItemColor: Colors.grey.shade500,
    type: BottomNavigationBarType.fixed,
    elevation: 2,
  ),

  // FloatingActionButton Theme
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: Colors.amber.shade700, // A nice accent color
    foregroundColor: Colors.white,
  ),
);
