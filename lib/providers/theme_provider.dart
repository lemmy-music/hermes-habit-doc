import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kThemeModeKey = 'theme_mode';

/// Manages dark-mode preference.
///
/// Priority order:
///   1. Saved SharedPreferences value (if any)
///   2. System platform brightness (on first launch)
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  bool get isDark => _themeMode == ThemeMode.dark;

  /// Call once at startup (before runApp or inside FutureBuilder).
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kThemeModeKey);
    if (saved == 'dark') {
      _themeMode = ThemeMode.dark;
    } else if (saved == 'light') {
      _themeMode = ThemeMode.light;
    } else {
      // No preference saved yet – use system default.
      _themeMode = ThemeMode.system;
    }
    notifyListeners();
  }

  Future<void> setDark(bool dark) async {
    _themeMode = dark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemeModeKey, dark ? 'dark' : 'light');
  }

  Future<void> toggleTheme() async {
    final currentlyDark = _themeMode == ThemeMode.dark;
    await setDark(!currentlyDark);
  }

  /// Returns true if dark should be shown given the [platformBrightness].
  bool effectivelyDark(Brightness platformBrightness) {
    if (_themeMode == ThemeMode.system) {
      return platformBrightness == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }
}
