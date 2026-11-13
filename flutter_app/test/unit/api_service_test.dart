import 'dart:convert';

import 'package:flutter_app/config/app_config.dart';
import 'package:flutter_app/services/api_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Executa [body] com um cliente HTTP falso que responde com [handler].
Future<T> withMockHttp<T>(
  Future<T> Function() body,
  Future<http.Response> Function(http.Request request) handler,
) {
  return http.runWithClient(body, () => MockClient(handler));
}

http.Response jsonResponse(Object body, int status) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  group('ApiService.authHeaders', () {
    test('inclui apenas Content-Type sem token', () {
      expect(ApiService.authHeaders(), {
        'Content-Type': 'application/json; charset=UTF-8',
      });
    });

    test('inclui Authorization Bearer com token', () {
      expect(
        ApiService.authHeaders(token: 'abc')['Authorization'],
        'Bearer abc',
      );
    });
  });

  group('ApiService.login', () {
    test('envia credenciais e salva o token em caso de sucesso', () async {
      late http.Request enviada;

      final data = await withMockHttp(
        () => ApiService.login(email: 'a@b.com', senha: '123456'),
        (request) async {
          enviada = request;
          return jsonResponse({'success': true, 'token': 'jwt-123'}, 200);
        },
      );

      expect(enviada.method, 'POST');
      expect(enviada.url.toString(), '${AppConfig.baseUrl}/api/auth/login');
      expect(jsonDecode(enviada.body), {'email': 'a@b.com', 'senha': '123456'});
      expect(data['token'], 'jwt-123');
      expect(await ApiService.readToken(), 'jwt-123');
    });

    test('não salva token quando as credenciais são inválidas', () async {
      final data = await withMockHttp(
        () => ApiService.login(email: 'a@b.com', senha: 'errada'),
        (_) async => jsonResponse({
          'success': false,
          'message': 'Credenciais inválidas.',
        }, 401),
      );

      expect(data['message'], 'Credenciais inválidas.');
      expect(await ApiService.readToken(), isNull);
    });
  });

  group('ApiService.register', () {
    test('omite telefone quando não informado', () async {
      late Map<String, dynamic> corpo;

      await withMockHttp(
        () => ApiService.register(nome: 'Ana', email: 'a@b.com', senha: '123456'),
        (request) async {
          corpo = jsonDecode(request.body) as Map<String, dynamic>;
          return jsonResponse({'success': true, 'token': 't'}, 201);
        },
      );

      expect(corpo.containsKey('telefone'), isFalse);
      expect(await ApiService.readToken(), 't');
    });
  });

  group('requisições autenticadas', () {
    setUp(() => FlutterSecureStorage.setMockInitialValues({
      AppConfig.authTokenKey: 'token-salvo',
    }));

    test('fetchPulseiras envia o token e converte a lista', () async {
      late http.Request enviada;

      final pulseiras = await withMockHttp(ApiService.fetchPulseiras, (
        request,
      ) async {
        enviada = request;
        return jsonResponse({
          'success': true,
          'data': [
            {'id': 1, 'crianca_id': 5, 'identificador': 'BRACELET-001'},
          ],
        }, 200);
      });

      expect(enviada.headers['Authorization'], 'Bearer token-salvo');
      expect(pulseiras, hasLength(1));
      expect(pulseiras.first.identificador, 'BRACELET-001');
    });

    test('fetchPulseiras lança exceção quando a API falha', () async {
      expect(
        withMockHttp(
          ApiService.fetchPulseiras,
          (_) async => jsonResponse({'success': false}, 500),
        ),
        throwsException,
      );
    });

    test('fetchChildren converte a lista de crianças', () async {
      final criancas = await withMockHttp(
        ApiService.fetchChildren,
        (_) async => jsonResponse({
          'success': true,
          'data': [
            {'id': 5, 'nome': 'Ana'},
          ],
        }, 200),
      );

      expect(criancas.single.nome, 'Ana');
    });

    test('updateMe mostra a primeira mensagem de erro de validação', () async {
      await expectLater(
        withMockHttp(
          () => ApiService.updateMe(nome: 'A', telefone: '12'),
          (_) async => jsonResponse({
            'success': false,
            'message': 'Dados inválidos.',
            'errors': [
              {'field': 'nome', 'message': 'Nome deve ter pelo menos 2 caracteres.'},
            ],
          }, 400),
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'mensagem',
            contains('Nome deve ter pelo menos 2 caracteres.'),
          ),
        ),
      );
    });

    test('createPulseira omite modelo vazio', () async {
      late Map<String, dynamic> corpo;

      await withMockHttp(
        () => ApiService.createPulseira(
          criancaId: 5,
          identificador: 'BRACELET-001',
          nomeDispositivo: 'Pulseira',
          modelo: '',
        ),
        (request) async {
          corpo = jsonDecode(request.body) as Map<String, dynamic>;
          return jsonResponse({'success': true, 'data': {}}, 201);
        },
      );

      expect(corpo, {
        'crianca_id': 5,
        'identificador': 'BRACELET-001',
        'nome_dispositivo': 'Pulseira',
      });
    });

    test('deletePulseira usa o método DELETE na URL da pulseira', () async {
      late http.Request enviada;

      await withMockHttp(() => ApiService.deletePulseira(7), (request) async {
        enviada = request;
        return jsonResponse({'success': true}, 200);
      });

      expect(enviada.method, 'DELETE');
      expect(enviada.url.path, '/api/pulseiras/7');
    });

    test('clearToken remove o token salvo', () async {
      await ApiService.clearToken();
      expect(await ApiService.readToken(), isNull);
    });
  });
}
