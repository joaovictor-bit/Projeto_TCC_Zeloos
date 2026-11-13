# flutter_app

Aplicativo Flutter da pulseira localizadora infantil (ZELOOS).

## Executar

```bash
flutter run
```

Para apontar para outra API, use `--dart-define=API_BASE_URL=http://seu-servidor:3005`.

## Testes

```bash
flutter test
```

- `test/unit/`: testes unitários dos models (`Pulseira`, `ChildProfile`, `Alerta`), da máscara de telefone (`PhoneInputFormatter`), das preferências (`AppSettings`) e do `ApiService` (com `MockClient` do pacote `http`, sem precisar da API rodando).
- `test/widget_test.dart`: testes de widget das telas.

Para rodar só os testes unitários: `flutter test test/unit`.
