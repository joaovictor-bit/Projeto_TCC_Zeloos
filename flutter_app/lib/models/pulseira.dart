class Pulseira {
  final int id;
  final int criancaId;
  final String identificador;
  final String? nomeDispositivo;
  final String? modelo;
  final String status;
  final String statusConexao;
  final double? bateriaPercentual;
  final DateTime? ultimaComunicacao;

  Pulseira({
    required this.id,
    required this.criancaId,
    required this.identificador,
    this.nomeDispositivo,
    this.modelo,
    required this.status,
    required this.statusConexao,
    this.bateriaPercentual,
    this.ultimaComunicacao,
  });

  factory Pulseira.fromJson(Map<String, dynamic> json) {
    return Pulseira(
      id: json['id'] as int? ?? 0,
      criancaId: json['crianca_id'] as int? ?? 0,
      identificador: json['identificador'] as String? ?? 'N/A',
      nomeDispositivo: json['nome_dispositivo'] as String?,
      modelo: json['modelo'] as String?,
      status: json['status'] as String? ?? 'ativa',
      statusConexao: json['status_conexao'] as String? ?? 'desconectada',
      bateriaPercentual: json['bateria_percentual'] == null ? null : (json['bateria_percentual'] as num).toDouble(),
      ultimaComunicacao: json['ultima_comunicacao_em'] == null ? null : DateTime.tryParse(json['ultima_comunicacao_em'] as String),
    );
  }
}
