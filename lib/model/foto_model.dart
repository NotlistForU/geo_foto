class FotoModel {
  final int id;
  final DateTime data;
  final int pontoId;
  final int numero;
  final String nome;
  final double? latitude;
  final double? longitude;
  final double? altitude;

  FotoModel({
    required this.id,
    required this.data,
    required this.pontoId,
    required this.numero,
    required this.nome,
    this.latitude,
    this.longitude,
    this.altitude,
  });

  factory FotoModel.fromMap(Map<String, dynamic> map) {
    return FotoModel(
      id: map['id'] as int,
      data: DateTime.fromMillisecondsSinceEpoch(map['data_criacao'] as int),
      pontoId: map['ponto_id'] as int,
      numero: map['numero'] as int,
      nome: map['nome'] as String,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      altitude: (map['altitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'data_criacao': data.millisecondsSinceEpoch,
      'ponto_id': pontoId,
      'numero': numero,
      'nome': nome,
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
    };
  }
}
