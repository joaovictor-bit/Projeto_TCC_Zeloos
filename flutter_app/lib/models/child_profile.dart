class ChildProfile {
  final int id;
  final String nome;
  final String? fotoUrl;
  final String? dataNascimento;

  ChildProfile({
    required this.id,
    required this.nome,
    this.fotoUrl,
    this.dataNascimento,
  });

  factory ChildProfile.fromJson(Map<String, dynamic> json) {
    return ChildProfile(
      id: json['id'] as int? ?? 0,
      nome: json['nome'] as String? ?? 'Criança',
      fotoUrl: json['foto_url'] as String?,
      dataNascimento: json['data_nascimento'] as String?,
    );
  }
}
