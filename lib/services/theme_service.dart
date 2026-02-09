import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  final String key = "theme_mode";
  SharedPreferences? _prefs;
  bool _darkMode = false;

  bool get darkMode => _darkMode;

  ThemeService() {
    _loadFromPrefs();
  }

  _initPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  _loadFromPrefs() async {
    await _initPrefs();
    _darkMode = _prefs?.getBool(key) ?? false;
    notifyListeners();
  }

  toggleTheme() async {
    _darkMode = !_darkMode;
    await _initPrefs();
    _prefs?.setBool(key, _darkMode);
    notifyListeners();
  }
}
