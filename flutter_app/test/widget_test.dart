// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/main.dart';
import 'package:flutter_app/screens/access_screen.dart';
import 'package:flutter_app/screens/dashboard_screen.dart';

void main() {
  testWidgets('ZELOOS login screen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('ZELOOS'), findsOneWidget);
    expect(find.text('Acesse sua conta'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
  });

  testWidgets('home screen presents separate navigation options', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: DashboardScreen()));

    expect(find.text('O que você deseja acessar?'), findsOneWidget);
    expect(find.text('Editar pulseira'), findsOneWidget);
    expect(find.text('Editar perfil'), findsOneWidget);
    expect(find.text('Configurações'), findsOneWidget);
    expect(find.text('Mapa'), findsOneWidget);
  });

  testWidgets('access screen enters the home when button is tapped', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: AccessScreen(email: 'teste@exemplo.com')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Acesso confirmado'), findsOneWidget);
    expect(find.text('teste@exemplo.com'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);

    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    expect(find.text('O que você deseja acessar?'), findsOneWidget);
  });
}
