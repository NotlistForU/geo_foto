class Foto {
  final int id;
  final DateTime data;
  final int missaoId;
  final int numero;
  final String nome;
  final String assetId;
  final double? latitude;
  final double? longitude;
  final double? altitude;
  Foto({
    required this.id,
    required this.data,
    required this.missaoId,
    required this.numero,
    required this.nome,
    required this.assetId,
    this.latitude,
    this.longitude,
    this.altitude,
  });
  // construtor  quando vem do banco de dados
  factory Foto.fromMap(Map<String, dynamic> map) {
    return Foto(
      id: map['id'] as int,
      data: DateTime.fromMillisecondsSinceEpoch(map['data_criacao'] as int),
      missaoId: map['missao_id'] as int,
      numero: map['numero'] as int,
      nome: map['nome'] as String,
      assetId: map['asset_id'] as String,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      altitude: (map['altitude'] as num?)?.toDouble(),
    );
  }
  // converter para quando vai para o banco
  Map<String, dynamic> toMap() {
    return {
      'data_criacao': data.millisecondsSinceEpoch,
      'missao_id': missaoId,
      'numero': numero,
      'nome': nome,
      'asset_id': assetId,
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
    };
  }
}
