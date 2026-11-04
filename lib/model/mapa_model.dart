import 'dart:math';
import 'package:sipam_foto/database/create.dart';
import 'package:latlong2/latlong.dart';

class MapaModel {
  final int id;
  final int missaoId;
  final String imagePath;
  final LatLng upperRight;
  final LatLng upperLeft;
  final LatLng lowerLeft;
  final LatLng lowerRight;

  const MapaModel({
    required this.id,
    required this.missaoId,
    required this.imagePath,
    required this.upperRight,
    required this.upperLeft,
    required this.lowerLeft,
    required this.lowerRight,
  });

  factory MapaModel.fromJson({
    required Map<String, dynamic> json,
    required int id,
    required int missaoId,
    required String imagePath,
  }) {
    final corners = json['corners'] as Map<String, dynamic>;

    return MapaModel(
      id: id,
      missaoId: missaoId,
      imagePath: imagePath,
      upperRight: canto(corners['upperRight']),
      upperLeft: canto(corners['upperLeft']),
      lowerLeft: canto(corners['lowerLeft']),
      lowerRight: canto(corners['lowerRight']),
    );
  }
  static LatLng canto(dynamic c) {
    final m = c as Map<String, dynamic>;
    final lat = (m['lat'] as num).toDouble();
    final lng = (m['lng'] as num).toDouble();

    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
      throw FormatException('Canto com lat/lng fora do intervalo válido.');
    }

    return LatLng(lat, lng);
  }

  factory MapaModel.fromMap(Map<String, dynamic> map) {
    return MapaModel(
      id: map['id'] as int,
      missaoId: map['missao_id'] as int,
      imagePath: map['image_path'] as String,
      upperRight: LatLng(
        (map['upper_right_lat'] as num).toDouble(),
        (map['upper_right_lng'] as num).toDouble(),
      ),
      upperLeft: LatLng(
        (map['upper_left_lat'] as num).toDouble(),
        (map['upper_left_lng'] as num).toDouble(),
      ),
      lowerLeft: LatLng(
        (map['lower_left_lat'] as num).toDouble(),
        (map['lower_left_lng'] as num).toDouble(),
      ),
      lowerRight: LatLng(
        (map['lower_right_lat'] as num).toDouble(),
        (map['lower_right_lng'] as num).toDouble(),
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'missao_id': missaoId,
      'image_path': imagePath,
      'upper_right_lat': upperRight.latitude,
      'upper_right_lng': upperRight.longitude,
      'upper_left_lat': upperLeft.latitude,
      'upper_left_lng': upperLeft.longitude,
      'lower_left_lat': lowerLeft.latitude,
      'lower_left_lng': lowerLeft.longitude,
      'lower_right_lat': lowerRight.latitude,
      'lower_right_lng': lowerRight.longitude,
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
