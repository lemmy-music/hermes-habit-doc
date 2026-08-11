import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kThemeModeKey = 'theme_mode';
const _kDateFormatKey = 'date_format';
const _kTimeFormatKey = 'time_format';

/// Preferred date layout (numeric day/month order).
enum DateFormatPref {
  /// German: TT.MM. (day.month)
  german,

  /// US: MM/DD (month/day)
  us,
}

/// Preferred time layout.
enum TimeFormatPref {
  /// 24-hour clock (HH:mm)
  h24,

  /// 12-hour clock with AM/PM (h:mm a)
  h12,
}

/// Manages persisted app preferences: dark-mode plus date/time formats.
///
/// Priority order:
///   1. Saved SharedPreferences value (if any)
///   2. System platform brightness (on first launch)
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  DateFormatPref _dateFormat = DateFormatPref.german;
  TimeFormatPref _timeFormat = TimeFormatPref.h24;

  ThemeMode get themeMode => _themeMode;

  bool get isDark => _themeMode == ThemeMode.dark;

  DateFormatPref get dateFormat => _dateFormat;
  TimeFormatPref get timeFormat => _timeFormat;

  /// True when a 24-hour clock should be used (time pickers, labels).
  bool get use24Hour => _timeFormat == TimeFormatPref.h24;

  /// Short numeric date pattern for the selected preference (e.g. `dd.MM.`).
  String get shortDatePattern =>
      _dateFormat == DateFormatPref.german ? 'dd.MM.' : 'MM/dd';

  /// Long numeric date pattern for the selected preference (e.g. `dd.MM.yy`).
  String get longDatePattern =>
      _dateFormat == DateFormatPref.german ? 'dd.MM.yy' : 'MM/dd/yy';

  /// Time pattern for the selected preference (e.g. `HH:mm`).
  String get timePattern => use24Hour ? 'HH:mm' : 'h:mm a';

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

    final savedDate = prefs.getString(_kDateFormatKey);
    _dateFormat = savedDate == 'us' ? DateFormatPref.us : DateFormatPref.german;

    final savedTime = prefs.getString(_kTimeFormatKey);
    _timeFormat = savedTime == 'h12' ? TimeFormatPref.h12 : TimeFormatPref.h24;

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

  Future<void> setDateFormat(DateFormatPref pref) async {
    if (_dateFormat == pref) return;
    _dateFormat = pref;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kDateFormatKey, pref == DateFormatPref.us ? 'us' : 'de');
  }

  Future<void> setTimeFormat(TimeFormatPref pref) async {
    if (_timeFormat == pref) return;
    _timeFormat = pref;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kTimeFormatKey, pref == TimeFormatPref.h12 ? 'h12' : 'h24');
  }

  /// Returns true if dark should be shown given the [platformBrightness].
  bool effectivelyDark(Brightness platformBrightness) {
    if (_themeMode == ThemeMode.system) {
      return platformBrightness == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }
}
