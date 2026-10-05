import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:sipam_foto/view/mapa/mapa_overlay.dart';

class MapaPage extends StatefulWidget {
  const MapaPage({super.key});

  @override
  State<MapaPage> createState() => _MapaPageState();
}

class _MapaPageState extends State<MapaPage> {
  late final Future<List<MapOverlay>> _overlays = MapOverlay.loadAll();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mapa')),
      body: FutureBuilder<List<MapOverlay>>(
        future: _overlays,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Erro ao carregar mapas: ${snapshot.error}'),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(-7.6393, -72.6628),
              initialZoom: 12,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.sipam_foto',
              ),
              OverlayImageLayer(
                overlayImages: [
                  for (final o in snapshot.data!)
                    OverlayImage(
                      imageProvider: AssetImage(o.imageAsset),
                      bounds: o.bounds,
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
