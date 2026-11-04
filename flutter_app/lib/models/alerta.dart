class Alerta {
  final int id;
  final int criancaId;
  final String tipo;
  final String titulo;
  final String mensagem;
  final String status;
  final DateTime ocorridoEm;

  Alerta({
    required this.id,
    required this.criancaId,
    required this.tipo,
    required this.titulo,
    required this.mensagem,
    required this.status,
    required this.ocorridoEm,
  });

  factory Alerta.fromJson(Map<String, dynamic> json) {
    return Alerta(
      id: json['id'] as int? ?? 0,
      criancaId: json['crianca_id'] as int? ?? 0,
      tipo: json['tipo'] as String? ?? 'desconhecido',
      titulo: json['titulo'] as String? ?? 'Alerta',
      mensagem: json['mensagem'] as String? ?? '',
      status: json['status'] as String? ?? 'novo',
      ocorridoEm: DateTime.tryParse(json['ocorrido_em'] as String? ?? DateTime.now().toIso8601String()) ?? DateTime.now(),
    );
  }
}
