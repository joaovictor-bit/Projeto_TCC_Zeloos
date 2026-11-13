import 'package:flutter/material.dart';
import 'package:flutter_app/services/app_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final settings = AppSettings.instance;

  tearDown(() async {
    SharedPreferences.setMockInitialValues({});
    await settings.setThemeMode(ThemeMode.system);
    await settings.setMapRefreshSeconds(15);
  });

  group('AppSettings.load', () {
    test('carrega tema e intervalo salvos', () async {
      SharedPreferences.setMockInitialValues({
        'theme_mode': 'dark',
        'map_refresh_seconds': 30,
      });

      await settings.load();

      expect(settings.themeMode, ThemeMode.dark);
      expect(settings.mapRefreshSeconds, 30);
    });

    test('usa tema do sistema para valor desconhecido', () async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'roxo'});

      await settings.load();

      expect(settings.themeMode, ThemeMode.system);
    });

    test('ignora intervalo fora das opções permitidas', () async {
      SharedPreferences.setMockInitialValues({'map_refresh_seconds': 7});

      await settings.load();

      expect(settings.mapRefreshSeconds, 15);
    });

    test('notifica os ouvintes', () async {
      SharedPreferences.setMockInitialValues({});
      var notificado = 0;
      void listener() => notificado++;
      settings.addListener(listener);

      await settings.load();

      settings.removeListener(listener);
      expect(notificado, 1);
    });
  });

  group('AppSettings setters', () {
    test('setThemeMode atualiza, notifica e persiste', () async {
      SharedPreferences.setMockInitialValues({});
      var notificado = false;
      void listener() => notificado = true;
      settings.addListener(listener);

      await settings.setThemeMode(ThemeMode.light);

      settings.removeListener(listener);
      final prefs = await SharedPreferences.getInstance();
      expect(settings.themeMode, ThemeMode.light);
      expect(notificado, isTrue);
      expect(prefs.getString('theme_mode'), 'light');
    });

    test('setMapRefreshSeconds atualiza e persiste', () async {
      SharedPreferences.setMockInitialValues({});

      await settings.setMapRefreshSeconds(60);

      final prefs = await SharedPreferences.getInstance();
      expect(settings.mapRefreshSeconds, 60);
      expect(prefs.getInt('map_refresh_seconds'), 60);
    });
  });

  test('mapIntervalOptions contém 15, 30 e 60 segundos', () {
    expect(AppSettings.mapIntervalOptions, [15, 30, 60]);
  });
}
