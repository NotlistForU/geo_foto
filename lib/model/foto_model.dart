import 'package:sipam_foto/database/create.dart';

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

  static Future<int> inserir(FotoModel foto) async {
    final db = await Create.database;

    return await db.insert('fotos', foto.toMap());
  }

  static Future<FotoModel?> buscarPorId(int id) async {
    final db = await Create.database;

    final resultado = await db.query(
      'fotos',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (resultado.isEmpty) {
      return null;
    }

    return FotoModel.fromMap(resultado.first);
  }

  static Future<int> obterProximoNumero(int pontoId) async {
    final db = await Create.database;

    final resultado = await db.rawQuery(
      '''
    SELECT COALESCE(MAX(numero), 0) + 1 AS proximo
    FROM fotos
    WHERE ponto_id = ?
    ''',
      [pontoId],
    );

    return resultado.first['proximo'] as int;
  }

  FotoModel copyWith({
    int? id,
    DateTime? data,
    int? pontoId,
    int? numero,
    String? nome,
    double? latitude,
    double? longitude,
    double? altitude,
  }) {
    return FotoModel(
      id: id ?? this.id,
      data: data ?? this.data,
      pontoId: pontoId ?? this.pontoId,
      numero: numero ?? this.numero,
      nome: nome ?? this.nome,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      altitude: altitude ?? this.altitude,
    );
  }
}
