// lib/theme_notifier.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme.dart';
import 'light_theme.dart';
import 'themes/blue_theme.dart';
import 'themes/indigo_theme.dart';

class ThemeNotifier extends ChangeNotifier {
  final String key = "theme";
  SharedPreferences? _prefs;
  late String _themeName;

  String get themeName => _themeName;

  // UPDATED: The 'rainbow' theme has been removed and 'aurora' is added.
  final Map<String, ThemeData> _themes = {
    'dark': darkTheme,
    'light': lightTheme,
    'blue': blueTheme,
    'indigo': indigoTheme,
  };

  Map<String, ThemeData> get allThemes => _themes;

  ThemeData get currentTheme => _themes[_themeName] ?? darkTheme;

  ThemeNotifier() : _themeName = 'dark' {
    _loadFromPrefs();
  }

  void setTheme(String themeName) {
    if (_themes.containsKey(themeName)) {
      _themeName = themeName;
      _saveToPrefs();
      notifyListeners();
    }
  }

  _initPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  _loadFromPrefs() async {
    await _initPrefs();
    _themeName = _prefs?.getString(key) ?? 'dark';
    notifyListeners();
  }

  _saveToPrefs() async {
    await _initPrefs();
    _prefs?.setString(key, _themeName);
  }
}
