import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MiniMap extends StatefulWidget {
  final double lat;
  final double lng;

  const MiniMap({super.key, required this.lat, required this.lng});

  @override
  State<MiniMap> createState() => _MiniMapState();
}

class _MiniMapState extends State<MiniMap> {
  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 180,
        width: 180,
        child: FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: LatLng(widget.lat, widget.lng),
            initialZoom: 13,
            interactionOptions: const InteractionOptions(
              flags:
                  InteractiveFlag.drag |
                  InteractiveFlag.pinchZoom |
                  InteractiveFlag.doubleTapZoom |
                  InteractiveFlag.rotate,
            ),
            onLongPress: (tapPosition, point) {
              debugPrint('>>>>>> SEGUROU NO MAPA');
              _mapController.move(
                LatLng(widget.lat, widget.lng),
                13,
              ); // volta pro centro
              _mapController.rotate(0); // reseta rotação
            },
          ),

          children: [
            TileLayer(
              urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
              userAgentPackageName: 'com.sipam_foto.app',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: LatLng(widget.lat, widget.lng),
                  width: 40,
                  height: 40,
                  child: const Icon(
                    Icons.location_pin,
                    size: 30,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
