import 'dart:math';

class MapaModel {
  final String id;
  final String imagePath;
  final double south; // Latitude mínima
  final double north; // Latitude máxima
  final double west; // longitude mínima
  final double east; // longitude máxima

  const MapaModel({
    required this.id,
    required this.imagePath,
    required this.south,
    required this.north,
    required this.west,
    required this.east,
  });

  factory MapaModel.fromJson({
    required Map<String, dynamic> json,
    required String id,
    required String imagePath,
  }) {
    final lats = <double>[];
    final lons = <double>[];

    final corners = json['corners'] as Map<String, dynamic>;

    // Varre os 4 cantos definidos no JSON
    for (final key in ['upperLeft', 'upperRight', 'lowerRight', 'lowerLeft']) {
      final c =
          corners[key] as List; // Formato padrão do JSON: [longitude, latitude]
      lons.add((c[0] as num).toDouble());
      lats.add((c[1] as num).toDouble());
    }

    return MapaModel(
      id: id,
      imagePath: imagePath,
      south: lats.reduce(min),
      north: lats.reduce(max),
      west: lons.reduce(min),
      east: lons.reduce(max),
    );
  }

  /// Método utilitário para quando você for salvar os dados no SQLite / Hive / Isar
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'imagePath': imagePath,
      'south': south,
      'north': north,
      'west': west,
      'east': east,
    };
  }
}
