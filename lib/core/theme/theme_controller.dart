import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists theme to [SharedPreferences] key [kPrefsKey] and notifies listeners.
class ThemeController extends ChangeNotifier {
  static const kPrefsKey = 'kk_theme';

  ThemeMode _mode = ThemeMode.dark;

  ThemeMode get themeMode => _mode;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(kPrefsKey) ?? 'dark';
    _mode = s == 'light' ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      kPrefsKey,
      mode == ThemeMode.light ? 'light' : 'dark',
    );
  }

  Future<void> setThemeFromApiString(String theme) async {
    await setThemeMode(theme == 'light' ? ThemeMode.light : ThemeMode.dark);
  }

  Future<void> toggle() async {
    await setThemeMode(
      _mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
    );
  }
}
