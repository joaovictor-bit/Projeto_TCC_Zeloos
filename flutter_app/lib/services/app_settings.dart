import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings extends ChangeNotifier {
  AppSettings._();

  static final instance = AppSettings._();

  static const mapIntervalOptions = [15, 30, 60];
  static const _themeKey = 'theme_mode';
  static const _mapIntervalKey = 'map_refresh_seconds';

  ThemeMode _themeMode = ThemeMode.system;
  int _mapRefreshSeconds = 15;

  ThemeMode get themeMode => _themeMode;
  int get mapRefreshSeconds => _mapRefreshSeconds;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _themeMode = ThemeMode.values.firstWhere(
        (mode) => mode.name == prefs.getString(_themeKey),
        orElse: () => ThemeMode.system,
      );
      final interval = prefs.getInt(_mapIntervalKey);
      if (mapIntervalOptions.contains(interval)) _mapRefreshSeconds = interval!;
    } catch (_) {
      // Mantém os valores padrão se o armazenamento não estiver disponível.
    }
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, mode.name);
  }

  Future<void> setMapRefreshSeconds(int seconds) async {
    _mapRefreshSeconds = seconds;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_mapIntervalKey, seconds);
  }
}
