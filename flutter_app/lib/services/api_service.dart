import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/alerta.dart';
import '../models/child_profile.dart';
import '../models/pulseira.dart';

class ApiService {
  static const _storage = FlutterSecureStorage();

  static String get baseUrl => AppConfig.baseUrl;

  static Future<String?> readToken() async =>
      _storage.read(key: AppConfig.authTokenKey);

  static Future<void> saveToken(String token) async =>
      _storage.write(key: AppConfig.authTokenKey, value: token);

  static Future<void> clearToken() async =>
      _storage.delete(key: AppConfig.authTokenKey);

  static Map<String, String> authHeaders({String? token}) => {
    'Content-Type': 'application/json; charset=UTF-8',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  static Future<Map<String, dynamic>> login({
    required String email,
    required String senha,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/auth/login'),
          headers: authHeaders(),
          body: jsonEncode({'email': email, 'senha': senha}),
        )
        .timeout(AppConfig.requestTimeout);

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 && data['token'] != null) {
      await saveToken(data['token'] as String);
    }
    return data;
  }

  static Future<Map<String, dynamic>> register({
    required String nome,
    required String email,
    required String senha,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/auth/register'),
          headers: authHeaders(),
          body: jsonEncode({'nome': nome, 'email': email, 'senha': senha}),
        )
        .timeout(AppConfig.requestTimeout);

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 201 && data['token'] != null) {
      await saveToken(data['token'] as String);
    }
    return data;
  }

  static Future<List<ChildProfile>> fetchChildren() async {
    final token = await readToken();
    final response = await http
        .get(
          Uri.parse('$baseUrl/api/criancas'),
          headers: authHeaders(token: token),
        )
        .timeout(AppConfig.requestTimeout);

    if (response.statusCode != 200) {
      throw Exception('Não foi possível carregar as crianças.');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final items = data['data'] as List<dynamic>? ?? const [];
    return items
        .map((item) => ChildProfile.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<ChildProfile> createChild({
    required String nome,
    String? dataNascimento,
  }) async {
    final token = await readToken();
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/criancas'),
          headers: authHeaders(token: token),
          body: jsonEncode({'nome': nome, 'data_nascimento': ?dataNascimento}),
        )
        .timeout(AppConfig.requestTimeout);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 201 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Não foi possível criar o perfil.');
    }
    return ChildProfile.fromJson(data['data'] as Map<String, dynamic>);
  }

  static Future<ChildProfile> updateChild({
    required int id,
    required String nome,
    String? dataNascimento,
  }) async {
    final token = await readToken();
    final response = await http
        .put(
          Uri.parse('$baseUrl/api/criancas/$id'),
          headers: authHeaders(token: token),
          body: jsonEncode({'nome': nome, 'data_nascimento': dataNascimento}),
        )
        .timeout(AppConfig.requestTimeout);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(
        data['message'] ?? 'Não foi possível atualizar o perfil.',
      );
    }
    return ChildProfile.fromJson(data['data'] as Map<String, dynamic>);
  }

  static Future<Map<String, dynamic>?> fetchAlertConfiguration(
    int childId,
  ) async {
    final token = await readToken();
    final response = await http
        .get(
          Uri.parse('$baseUrl/api/configuracoes/$childId'),
          headers: authHeaders(token: token),
        )
        .timeout(AppConfig.requestTimeout);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(
        data['message'] ?? 'Não foi possível carregar as configurações.',
      );
    }
    return data['data'] as Map<String, dynamic>?;
  }

  static Future<void> updateAlertConfiguration({
    required int childId,
    required bool alertaSaidaLocal,
    required bool alertaEntradaLocal,
    required bool alertaDesconexao,
    required bool alertaBateriaBaixa,
    required int limiteBateriaPercentual,
  }) async {
    final token = await readToken();
    final response = await http
        .put(
          Uri.parse('$baseUrl/api/configuracoes/$childId'),
          headers: authHeaders(token: token),
          body: jsonEncode({
            'alerta_saida_local': alertaSaidaLocal,
            'alerta_entrada_local': alertaEntradaLocal,
            'alerta_desconexao': alertaDesconexao,
            'alerta_bateria_baixa': alertaBateriaBaixa,
            'limite_bateria_percentual': limiteBateriaPercentual,
          }),
        )
        .timeout(AppConfig.requestTimeout);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(
        data['message'] ?? 'Não foi possível salvar as configurações.',
      );
    }
  }

  static Future<void> createPulseira({
    required int criancaId,
    required String identificador,
    required String nomeDispositivo,
    String? modelo,
  }) async {
    final token = await readToken();
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/pulseiras'),
          headers: authHeaders(token: token),
          body: jsonEncode({
            'crianca_id': criancaId,
            'identificador': identificador,
            'nome_dispositivo': nomeDispositivo,
            if (modelo != null && modelo.isNotEmpty) 'modelo': modelo,
          }),
        )
        .timeout(AppConfig.requestTimeout);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 201 || data['success'] != true) {
      throw Exception(
        data['message'] ?? 'Não foi possível cadastrar a pulseira.',
      );
    }
  }

  static Future<void> updatePulseira({
    required int id,
    required int criancaId,
    required String identificador,
    required String nomeDispositivo,
    String? modelo,
  }) async {
    final token = await readToken();
    final response = await http
        .put(
          Uri.parse('$baseUrl/api/pulseiras/$id'),
          headers: authHeaders(token: token),
          body: jsonEncode({
            'crianca_id': criancaId,
            'identificador': identificador,
            'nome_dispositivo': nomeDispositivo,
            'modelo': modelo,
          }),
        )
        .timeout(AppConfig.requestTimeout);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(
        data['message'] ?? 'Não foi possível atualizar a pulseira.',
      );
    }
  }

  static Future<void> deletePulseira(int id) async {
    final token = await readToken();
    final response = await http
        .delete(
          Uri.parse('$baseUrl/api/pulseiras/$id'),
          headers: authHeaders(token: token),
        )
        .timeout(AppConfig.requestTimeout);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(
        data['message'] ?? 'Não foi possível remover a pulseira.',
      );
    }
  }

  static Future<Map<String, dynamic>> fetchPulseiraLocation(int id) async {
    final token = await readToken();
    final response = await http
        .get(
          Uri.parse('$baseUrl/api/pulseiras/$id/localizacao-atual'),
          headers: authHeaders(token: token),
        )
        .timeout(AppConfig.requestTimeout);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(
        data['message'] ?? 'Não foi possível consultar a localização.',
      );
    }
    return data['data'] as Map<String, dynamic>;
  }

  static Future<List<Alerta>> fetchAlerts() async {
    final token = await readToken();
    final response = await http
        .get(
          Uri.parse('$baseUrl/api/alertas'),
          headers: authHeaders(token: token),
        )
        .timeout(AppConfig.requestTimeout);

    if (response.statusCode != 200) {
      throw Exception('Não foi possível carregar os alertas.');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final items = data['data'] as List<dynamic>? ?? const [];
    return items
        .map((item) => Alerta.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<List<Pulseira>> fetchPulseiras() async {
    final token = await readToken();
    final response = await http
        .get(
          Uri.parse('$baseUrl/api/pulseiras'),
          headers: authHeaders(token: token),
        )
        .timeout(AppConfig.requestTimeout);

    if (response.statusCode != 200) {
      throw Exception('Não foi possível carregar as pulseiras.');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final items = data['data'] as List<dynamic>? ?? const [];
    return items
        .map((item) => Pulseira.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
