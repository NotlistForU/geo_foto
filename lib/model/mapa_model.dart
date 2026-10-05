import 'dart:math';
import 'package:sipam_foto/database/create.dart';

class MapaModel {
  final int id;
  final int missaoId;
  final String imagePath;
  final double south;
  final double north;
  final double west;
  final double east;

  const MapaModel({
    required this.id,
    required this.missaoId,
    required this.imagePath,
    required this.south,
    required this.north,
    required this.west,
    required this.east,
  });

  factory MapaModel.fromJson({
    required Map<String, dynamic> json,
    required int id,
    required int missaoId,
    required String imagePath,
  }) {
    final lats = <double>[];
    final lons = <double>[];

    final corners = json['corners'] as Map<String, dynamic>;

    for (final key in ['upperLeft', 'upperRight', 'lowerRight', 'lowerLeft']) {
      final c = corners[key] as List;

      lons.add((c[0] as num).toDouble());
      lats.add((c[1] as num).toDouble());
    }

    return MapaModel(
      id: id,
      missaoId: missaoId,
      imagePath: imagePath,
      south: lats.reduce(min),
      north: lats.reduce(max),
      west: lons.reduce(min),
      east: lons.reduce(max),
    );
  }

  factory MapaModel.fromMap(Map<String, dynamic> map) {
    return MapaModel(
      id: map['id'] as int,
      missaoId: map['missao_id'] as int,
      imagePath: map['image_path'] as String,
      south: (map['south'] as num).toDouble(),
      north: (map['north'] as num).toDouble(),
      west: (map['west'] as num).toDouble(),
      east: (map['east'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'missao_id': missaoId,
      'image_path': imagePath,
      'south': south,
      'north': north,
      'west': west,
      'east': east,
    };
  }

  // =========================
  // REPOSITORY
  // =========================

  static Future<int> inserir(MapaModel mapa) async {
    final db = await Create.database;

    return await db.insert('mapas', mapa.toMap());
  }

  static Future<MapaModel?> buscarPorId(int id) async {
    final db = await Create.database;

    final resultado = await db.query(
      'mapas',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (resultado.isEmpty) {
      return null;
    }

    return MapaModel.fromMap(resultado.first);
  }

  static Future<MapaModel?> buscarPorMissao(int missaoId) async {
    final db = await Create.database;

    final resultado = await db.query(
      'mapas',
      where: 'missao_id = ?',
      whereArgs: [missaoId],
      limit: 1,
    );

    if (resultado.isEmpty) {
      return null;
    }

    return MapaModel.fromMap(resultado.first);
  }

  static Future<int> atualizar(MapaModel mapa) async {
    final db = await Create.database;

    return await db.update(
      'mapas',
      mapa.toMap(),
      where: 'id = ?',
      whereArgs: [mapa.id],
    );
  }

  static Future<int> excluir(int id) async {
    final db = await Create.database;

    return await db.delete('mapas', where: 'id = ?', whereArgs: [id]);
  }
}
