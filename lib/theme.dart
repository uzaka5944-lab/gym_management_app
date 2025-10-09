import 'package:flutter/material.dart';

const Color primaryColor = Color(0xFFC3FF41);
const Color darkBackgroundColor = Color(0xFF131414);
const Color cardBackgroundColor = Color(0xFF1C1C1E);
const Color fontColor = Colors.white;

final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: primaryColor,
  scaffoldBackgroundColor: darkBackgroundColor,
  fontFamily: 'Poppins',
  appBarTheme: const AppBarTheme(
    backgroundColor: darkBackgroundColor,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: TextStyle(
      color: fontColor,
      fontSize: 20,
      fontWeight: FontWeight.bold,
      fontFamily: 'Poppins',
    ),
    iconTheme: IconThemeData(color: primaryColor),
  ),
  cardTheme: CardTheme(
    color: cardBackgroundColor,
    elevation: 4,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    margin: const EdgeInsets.symmetric(vertical: 8),
  ),
  textTheme: const TextTheme(
    displayLarge:
        TextStyle(color: fontColor, fontWeight: FontWeight.bold, fontSize: 32),
    displayMedium:
        TextStyle(color: fontColor, fontWeight: FontWeight.bold, fontSize: 24),
    bodyLarge: TextStyle(color: fontColor, fontSize: 16),
    bodyMedium: TextStyle(color: Colors.white70, fontSize: 14),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: primaryColor,
      foregroundColor: Colors.black,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      textStyle: const TextStyle(
          fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: fontColor,
      side: const BorderSide(color: cardBackgroundColor),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      textStyle: const TextStyle(
          fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: cardBackgroundColor,
    hintStyle: const TextStyle(color: Colors.white54),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: primaryColor),
    ),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: cardBackgroundColor,
    selectedItemColor: primaryColor,
    unselectedItemColor: Colors.grey,
    type: BottomNavigationBarType.fixed,
    showUnselectedLabels: false,
  ),
  colorScheme: const ColorScheme.dark(
    primary: primaryColor,
    secondary: primaryColor,
    surface: cardBackgroundColor,
    onPrimary: Colors.black,
    onSurface: fontColor,
  ),
);
