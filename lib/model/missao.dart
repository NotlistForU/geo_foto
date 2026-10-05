class Missao {
  final int id;
  final DateTime data;
  final String nome;
  final bool ativa;
  final int? mapaId;
  Missao({
    required this.id,
    required this.data,
    required this.nome,
    required this.ativa,
    this.mapaId,
  });

  factory Missao.fromMap(Map<String, dynamic> map) {
    return Missao(
      id: map['id'] as int,
      data: DateTime.fromMillisecondsSinceEpoch(map['data_criacao'] as int),
      nome: map['nome'] as String,
      ativa: (map['ativa'] as int) == 1,
      mapaId: map['mapa_id'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'data_criacao': data.millisecondsSinceEpoch,
      'nome': nome,
      'ativa': ativa ? 1 : 0,
      'mapa_id': mapaId,
    };
  }

  Missao copyWith({
    int? id,
    DateTime? data,
    String? nome,
    bool? ativa,
    int? mapaId,
  }) {
    return Missao(
      id: id ?? this.id,
      data: data ?? this.data,
      nome: nome ?? this.nome,
      ativa: ativa ?? this.ativa,
      mapaId: mapaId ?? this.mapaId,
    );
  }
}
