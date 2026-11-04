import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:io';
import 'package:sipam_foto/model/mapa_model.dart';

class MapOverlayWidget {
  final String imageAsset;
  final LatLngBounds bounds;

  const MapOverlayWidget({required this.imageAsset, required this.bounds});

  factory MapOverlayWidget.fromJson(Map<String, dynamic> json, String folder) {
    final corners = json['corners'] as Map<String, dynamic>;

    // No JSON vem [lon, lat]; o LatLng espera (lat, lon)
    LatLng point(String key) {
      final c = corners[key] as List;
      return LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble());
    }

    return MapOverlayWidget(
      imageAsset: '$folder${json['image']}',
      bounds: LatLngBounds.fromPoints([
        point('upperLeft'),
        point('upperRight'),
        point('lowerRight'),
        point('lowerLeft'),
      ]),
    );
  }

  static Future<List<MapOverlayWidget>> loadAll({
    String folder = 'assets/map/',
  }) async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final jsonPaths = manifest.listAssets().where(
      (p) => p.startsWith(folder) && p.endsWith('.json'),
    );

    final overlays = <MapOverlayWidget>[];
    for (final path in jsonPaths) {
      final data = jsonDecode(await rootBundle.loadString(path));
      overlays.add(
        MapOverlayWidget.fromJson(data as Map<String, dynamic>, folder),
      );
    }
    return overlays;
  }
}
