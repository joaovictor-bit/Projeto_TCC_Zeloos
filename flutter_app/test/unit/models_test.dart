import 'package:flutter_app/models/alerta.dart';
import 'package:flutter_app/models/child_profile.dart';
import 'package:flutter_app/models/pulseira.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Pulseira.fromJson', () {
    test('converte todos os campos da API', () {
      final pulseira = Pulseira.fromJson({
        'id': 10,
        'crianca_id': 5,
        'identificador': 'BRACELET-001',
        'nome_dispositivo': 'Pulseira da Ana',
        'modelo': 'ZL-01',
        'status': 'ativa',
        'status_conexao': 'conectada',
        'bateria_percentual': 82,
        'ultima_comunicacao_em': '2026-11-11T10:30:00.000Z',
      });

      expect(pulseira.id, 10);
      expect(pulseira.criancaId, 5);
      expect(pulseira.identificador, 'BRACELET-001');
      expect(pulseira.nomeDispositivo, 'Pulseira da Ana');
      expect(pulseira.modelo, 'ZL-01');
      expect(pulseira.status, 'ativa');
      expect(pulseira.statusConexao, 'conectada');
      expect(pulseira.bateriaPercentual, 82.0);
      expect(pulseira.ultimaComunicacao, DateTime.utc(2026, 11, 11, 10, 30));
    });

    test('usa valores padrão quando campos estão ausentes', () {
      final pulseira = Pulseira.fromJson({});

      expect(pulseira.id, 0);
      expect(pulseira.criancaId, 0);
      expect(pulseira.identificador, 'N/A');
      expect(pulseira.nomeDispositivo, isNull);
      expect(pulseira.modelo, isNull);
      expect(pulseira.status, 'ativa');
      expect(pulseira.statusConexao, 'desconectada');
      expect(pulseira.bateriaPercentual, isNull);
      expect(pulseira.ultimaComunicacao, isNull);
    });

    test('aceita bateria como decimal', () {
      final pulseira = Pulseira.fromJson({'bateria_percentual': 45.5});
      expect(pulseira.bateriaPercentual, 45.5);
    });

    test('ignora data de comunicação inválida', () {
      final pulseira = Pulseira.fromJson({'ultima_comunicacao_em': 'data-invalida'});
      expect(pulseira.ultimaComunicacao, isNull);
    });
  });

  group('ChildProfile.fromJson', () {
    test('converte os campos da API', () {
      final crianca = ChildProfile.fromJson({
        'id': 5,
        'nome': 'Ana',
        'foto_url': 'https://exemplo.com/ana.png',
        'data_nascimento': '2018-05-10',
      });

      expect(crianca.id, 5);
      expect(crianca.nome, 'Ana');
      expect(crianca.fotoUrl, 'https://exemplo.com/ana.png');
      expect(crianca.dataNascimento, '2018-05-10');
    });

    test('usa valores padrão quando campos estão ausentes', () {
      final crianca = ChildProfile.fromJson({});

      expect(crianca.id, 0);
      expect(crianca.nome, 'Criança');
      expect(crianca.fotoUrl, isNull);
      expect(crianca.dataNascimento, isNull);
    });
  });

  group('Alerta.fromJson', () {
    test('converte os campos da API', () {
      final alerta = Alerta.fromJson({
        'id': 1,
        'crianca_id': 5,
        'tipo': 'saida_local',
        'titulo': 'Saída de local seguro',
        'mensagem': 'A criança saiu de Escola.',
        'status': 'visualizado',
        'ocorrido_em': '2026-11-11T08:00:00.000Z',
      });

      expect(alerta.id, 1);
      expect(alerta.criancaId, 5);
      expect(alerta.tipo, 'saida_local');
      expect(alerta.titulo, 'Saída de local seguro');
      expect(alerta.mensagem, 'A criança saiu de Escola.');
      expect(alerta.status, 'visualizado');
      expect(alerta.ocorridoEm, DateTime.utc(2026, 11, 11, 8));
    });

    test('usa valores padrão e data atual quando campos estão ausentes', () {
      final antes = DateTime.now();
      final alerta = Alerta.fromJson({});
      final depois = DateTime.now();

      expect(alerta.id, 0);
      expect(alerta.tipo, 'desconhecido');
      expect(alerta.titulo, 'Alerta');
      expect(alerta.mensagem, '');
      expect(alerta.status, 'novo');
      expect(alerta.ocorridoEm.isBefore(antes), isFalse);
      expect(alerta.ocorridoEm.isAfter(depois), isFalse);
    });

    test('usa a data atual quando ocorrido_em é inválido', () {
      final alerta = Alerta.fromJson({'ocorrido_em': 'invalida'});
      expect(
        alerta.ocorridoEm.difference(DateTime.now()).inSeconds.abs(),
        lessThan(5),
      );
    });
  });
}
