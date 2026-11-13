// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/main.dart';
import 'package:flutter_app/screens/app_settings_screen.dart';
import 'package:flutter_app/screens/dashboard_screen.dart';
import 'package:flutter_app/services/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('ZELOOS login screen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(
      find.byWidgetPredicate((w) => w is Image && w.semanticLabel == 'ZELOOS'),
      findsOneWidget,
    );
    expect(find.text('Acesse sua conta'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
  });

  testWidgets('login screen toggles between light and dark theme', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await AppSettings.instance.setThemeMode(ThemeMode.light);
    await tester.pumpWidget(const MyApp());

    expect(
      find.image(const AssetImage('assets/images/zeloos_logo_navy.png')),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip('Mudar para tema escuro'));
    await tester.pumpAndSettle();

    expect(AppSettings.instance.themeMode, ThemeMode.dark);
    expect(
      find.image(const AssetImage('assets/images/zeloos_logo_white.png')),
      findsOneWidget,
    );
    expect(find.byTooltip('Mudar para tema claro'), findsOneWidget);
    await AppSettings.instance.setThemeMode(ThemeMode.system);
  });

  testWidgets('register form shows optional phone with mask', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    final toggle = find.text('Criar conta');
    await tester.ensureVisible(toggle);
    await tester.tap(toggle);
    await tester.pumpAndSettle();

    expect(find.text('Telefone (opcional)'), findsOneWidget);
    final phoneField = find.widgetWithText(TextField, 'Telefone (opcional)');
    await tester.enterText(phoneField, '11987654321');
    expect(
      tester.widget<TextField>(phoneField).controller!.text,
      '(11) 98765-4321',
    );
  });

  testWidgets('app settings links to account screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: AppSettingsScreen()),
    );
    await tester.scrollUntilVisible(find.text('Minha conta'), 200);
    await tester.tap(find.text('Minha conta'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.widgetWithText(AppBar, 'Minha conta'), findsOneWidget);
  });

  testWidgets('home screen greets the user and shows shortcuts', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: DashboardScreen(userName: 'Henry Silva')),
    );

    expect(
      find.image(const AssetImage('assets/images/zeloos_wordmark_white.png')),
      findsOneWidget,
    );
    expect(find.text('Olá, Henry!'), findsOneWidget);
    expect(find.text('Atalhos'), findsOneWidget);
    expect(find.text('Pulseiras'), findsOneWidget);
    expect(find.text('Perfis'), findsOneWidget);
    expect(find.text('Config. pulseira'), findsOneWidget);
    expect(find.text('Mapa'), findsOneWidget);
    expect(find.byTooltip('Mudar para tema escuro'), findsOneWidget);
  });

  testWidgets('app settings switches to dark theme', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await AppSettings.instance.load();
    await tester.pumpWidget(const MyApp());
    final context = tester.element(find.text('Acesse sua conta'));
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AppSettingsScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Configurações do app'), findsOneWidget);
    await tester.tap(find.text('Escuro'));
    await tester.pumpAndSettle();

    expect(AppSettings.instance.themeMode, ThemeMode.dark);
    expect(
      Theme.of(tester.element(find.text('Tema'))).brightness,
      Brightness.dark,
    );
    await AppSettings.instance.setThemeMode(ThemeMode.system);
  });
}
