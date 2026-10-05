import 'package:sipam_foto/database/create.dart';

class PontoModel {
  final int id;
  final int missaoId;
  final int numero;
  final DateTime data;
  final String nome;
  final double latitude;
  final double longitude;
  final double altitude;

  const PontoModel({
    required this.id,
    required this.missaoId,
    required this.numero,
    required this.data,
    required this.nome,
    required this.latitude,
    required this.longitude,
    required this.altitude,
  });

  factory PontoModel.fromMap(Map<String, dynamic> map) {
    return PontoModel(
      id: map['id'] as int,
      missaoId: map['missao_id'] as int,
      numero: map['numero'] as int,
      data: DateTime.fromMillisecondsSinceEpoch(map['data_criacao'] as int),
      nome: map['nome'] as String,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      altitude: (map['altitude'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'missao_id': missaoId,
      'numero': numero,
      'data_criacao': data.millisecondsSinceEpoch,
      'nome': nome,
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
    };
  }

  PontoModel copyWith({
    int? id,
    int? missaoId,
    int? numero,
    DateTime? data,
    String? nome,
    double? latitude,
    double? longitude,
    double? altitude,
  }) {
    return PontoModel(
      id: id ?? this.id,
      missaoId: missaoId ?? this.missaoId,
      numero: numero ?? this.numero,
      data: data ?? this.data,
      nome: nome ?? this.nome,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      altitude: altitude ?? this.altitude,
    );
  }

  static Future<int> inserir(PontoModel ponto) async {
    final db = await Create.database;

    return await db.insert('pontos', ponto.toMap());
  }

  static Future<PontoModel?> buscarPorId(int id) async {
    final db = await Create.database;

    final resultado = await db.query(
      'pontos',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (resultado.isEmpty) {
      return null;
    }

    return PontoModel.fromMap(resultado.first);
  }

  static Future<List<PontoModel>> listarPorMissao(int missaoId) async {
    final db = await Create.database;

    final resultado = await db.query(
      'pontos',
      where: 'missao_id = ?',
      whereArgs: [missaoId],
      orderBy: 'numero ASC',
    );

    return resultado.map((map) => PontoModel.fromMap(map)).toList();
  }

  static Future<int> obterProximoNumero(int missaoId) async {
    final db = await Create.database;

    final resultado = await db.rawQuery(
      '''
      SELECT COALESCE(MAX(numero), 0) + 1 AS proximo
      FROM pontos
      WHERE missao_id = ?
      ''',
      [missaoId],
    );

    return resultado.first['proximo'] as int;
  }

  static Future<int> atualizar(PontoModel ponto) async {
    final db = await Create.database;

    return await db.update(
      'pontos',
      ponto.toMap(),
      where: 'id = ?',
      whereArgs: [ponto.id],
    );
  }

  static Future<int> excluir(int id) async {
    final db = await Create.database;

    return await db.delete('pontos', where: 'id = ?', whereArgs: [id]);
  }
}
