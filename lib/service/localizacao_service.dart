import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LocalizacaoService {
  static const _distance = Distance();

  static Future<Position> posicaoAtual() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw Exception('GPS desligado');
    }

    var permissao = await Geolocator.checkPermission();
    if (permissao == LocationPermission.denied) {
      permissao = await Geolocator.requestPermission();
    }
    if (permissao == LocationPermission.denied ||
        permissao == LocationPermission.deniedForever) {
      throw Exception('Sem permissão de localização');
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  /// Distância em metros entre dois pontos.
  static double metros(LatLng a, LatLng b) =>
      _distance.as(LengthUnit.Meter, a, b);
}
