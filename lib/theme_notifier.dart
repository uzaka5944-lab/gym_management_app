import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeNotifier extends ChangeNotifier {
  final String key = "theme";
  SharedPreferences? _prefs;
  bool _isDarkMode;

  bool get isDarkMode => _isDarkMode;

  ThemeNotifier() : _isDarkMode = true {
    _loadFromPrefs();
  }

  toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _saveToPrefs();
    notifyListeners();
  }

  _initPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  _loadFromPrefs() async {
    await _initPrefs();
    _isDarkMode = _prefs?.getBool(key) ?? true;
    notifyListeners();
  }

  _saveToPrefs() async {
    await _initPrefs();
    _prefs?.setBool(key, _isDarkMode);
  }
}
