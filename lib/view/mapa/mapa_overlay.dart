import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapOverlay {
  final String imageAsset;
  final LatLngBounds bounds;

  const MapOverlay({required this.imageAsset, required this.bounds});

  factory MapOverlay.fromJson(Map<String, dynamic> json, String folder) {
    final corners = json['corners'] as Map<String, dynamic>;

    // No JSON vem [lon, lat]; o LatLng espera (lat, lon)
    LatLng point(String key) {
      final c = corners[key] as List;
      return LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble());
    }

    return MapOverlay(
      imageAsset: '$folder${json['image']}',
      bounds: LatLngBounds.fromPoints([
        point('upperLeft'),
        point('upperRight'),
        point('lowerRight'),
        point('lowerLeft'),
      ]),
    );
  }

  static Future<List<MapOverlay>> loadAll({
    String folder = 'assets/map/',
  }) async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final jsonPaths = manifest.listAssets().where(
      (p) => p.startsWith(folder) && p.endsWith('.json'),
    );

    final overlays = <MapOverlay>[];
    for (final path in jsonPaths) {
      final data = jsonDecode(await rootBundle.loadString(path));
      overlays.add(MapOverlay.fromJson(data as Map<String, dynamic>, folder));
    }
    return overlays;
  }
}
