import 'package:sipam_foto/database/create.dart';
import 'package:sipam_foto/model/filtro.dart';

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

  static Future<List<FotoModel>> listar(Filtro filtro) async {
    final db = await Create.database;

    final where = <String>[];
    final args = <dynamic>[];

    if (filtro.missaoId != null) {
      where.add('p.missao_id = ?');
      args.add(filtro.missaoId);
    }

    if (filtro.pontoId != null) {
      where.add('f.ponto_id = ?');
      args.add(filtro.pontoId);
    }

    if (filtro.inicio != null) {
      where.add('f.data_criacao >= ?');
      args.add(filtro.inicio!.millisecondsSinceEpoch);
    }

    if (filtro.fim != null) {
      where.add('f.data_criacao <= ?');
      args.add(filtro.fim!.millisecondsSinceEpoch);
    }

    final resultado = await db.rawQuery('''
    SELECT f.*
    FROM fotos f
    INNER JOIN pontos p ON p.id = f.ponto_id
    ${where.isNotEmpty ? 'WHERE ${where.join(' AND ')}' : ''}
    ORDER BY f.data_criacao DESC
    ''', args);

    return resultado.map((map) => FotoModel.fromMap(map)).toList();
  }

  static Future<List<FotoModel>> listarTodas() async {
    final db = await Create.database;

    final resultado = await db.query(
      'fotos',
      orderBy: 'ponto_id ASC, numero ASC',
    );

    return resultado.map((map) => FotoModel.fromMap(map)).toList();
  }

  static Future<List<FotoModel>> listarPorPonto(int pontoId) async {
    final db = await Create.database;

    final resultado = await db.query(
      'fotos',
      where: 'ponto_id = ?',
      whereArgs: [pontoId],
      orderBy: 'numero ASC',
    );

    return resultado.map((map) => FotoModel.fromMap(map)).toList();
  }

  static Future<List<FotoModel>> listarPorMissao(int missaoId) async {
    final db = await Create.database;

    final resultado = await db.rawQuery(
      '''
    SELECT f.*
    FROM fotos f
    INNER JOIN pontos p ON p.id = f.ponto_id
    WHERE p.missao_id = ?
    ORDER BY p.numero ASC, f.numero ASC
    ''',
      [missaoId],
    );

    return resultado.map((map) => FotoModel.fromMap(map)).toList();
  }

  static Future<void> excluir(int id) async {
    final db = await Create.database;

    await db.delete('fotos', where: 'id = ?', whereArgs: [id]);
  }
}
